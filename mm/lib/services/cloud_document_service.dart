import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/cloud_document.dart';
import '../struct/document_type.dart';
import 'supabase_storage_service.dart';

class CloudDocumentService {
  CloudDocumentService({
    SupabaseClient? client,
    SupabaseStorageService? storage,
  }) : _client = client ?? Supabase.instance.client,
       _storage =
           storage ??
           SupabaseStorageService(client: client ?? Supabase.instance.client);

  final SupabaseClient _client;
  final SupabaseStorageService _storage;

  Future<void> ensureProfile(User user) async {
    if (_requireCurrentUserId() != user.uid) {
      throw StateError('Phiên đăng nhập đã thay đổi. Vui lòng thử lại.');
    }
    await _client.from('users').upsert({
      'id': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'avatar_url': user.photoURL,
    }, onConflict: 'id');
  }

  Future<List<CloudDocument>> searchDocuments({
    String? keyword,
    DocumentType? type,
  }) async {
    final userId = _requireCurrentUserId();
    final response = await _client.rpc(
      'search_documents',
      params: {
        'p_query': keyword?.trim().isNotEmpty == true ? keyword!.trim() : null,
        'p_document_type': type?.name,
      },
    );
    final documents = (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    if (documents.isEmpty) {
      return const [];
    }

    final ids = documents.map((row) => row['id'] as String).toList();
    final permissions = await _client
        .from('document_permissions')
        .select('document_id, permission')
        .eq('user_id', userId)
        .inFilter('document_id', ids);
    final permissionByDocument = {
      for (final row in permissions)
        row['document_id'] as String: row['permission'] as String,
    };
    return documents.map((row) {
      final ownerId = row['owner_id'] as String;
      return CloudDocument.fromMap({
        ...row,
        'permission': ownerId == userId
            ? 'owner'
            : permissionByDocument[row['id'] as String],
      });
    }).toList();
  }

  Future<CloudDocument?> getDocument(String id) async {
    final userId = _requireCurrentUserId();
    final row = await _client
        .from('documents')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;

    String? permission;
    if (row['owner_id'] != userId) {
      final access = await _client
          .from('document_permissions')
          .select('permission')
          .eq('document_id', id)
          .eq('user_id', userId)
          .maybeSingle();
      permission = access?['permission'] as String?;
    } else {
      permission = 'owner';
    }

    return CloudDocument.fromMap({...row, 'permission': permission});
  }

  Future<void> createDocument({
    required String title,
    required String? description,
    required String? subject,
    required DocumentType type,
    PlatformFile? file,
  }) async {
    final normalizedTitle = title.trim();
    _validateTitle(normalizedTitle);
    final userId = _requireCurrentUserId();
    final bytes = file == null ? null : await _fileBytes(file);

    final row = await _client
        .from('documents')
        .insert({
          'owner_id': userId,
          'title': normalizedTitle,
          'description': _normalize(description),
          'subject': _normalize(subject),
          'document_type': type.name,
        })
        .select('id')
        .single();
    final documentId = row['id'] as String;

    if (file == null) return;
    final fileBytes = bytes!;
    final path = _storage.createObjectPath(
      ownerId: userId,
      documentId: documentId,
      fileName: file.name,
    );
    var uploadStarted = false;
    try {
      uploadStarted = true;
      await _storage.upload(path: path, fileName: file.name, bytes: fileBytes);
      final updated = await _client
          .from('documents')
          .update({
            'storage_path': path,
            'mime_type': SupabaseStorageService.mimeType(file.name),
            'file_size_bytes': fileBytes.length,
          })
          .eq('id', documentId)
          .select('id');
      if (updated.isEmpty) {
        throw StateError('Không còn quyền cập nhật metadata tài liệu.');
      }
    } catch (error, stackTrace) {
      Object? cleanupError;
      if (uploadStarted) {
        try {
          await _storage.delete(path);
        } catch (cleanup) {
          cleanupError = cleanup;
        }
      }
      try {
        final removed = await _client
            .from('documents')
            .delete()
            .eq('id', documentId)
            .select('id');
        if (removed.isEmpty) {
          cleanupError ??= StateError('Metadata tài liệu vẫn còn tồn tại.');
        }
      } catch (cleanup) {
        cleanupError ??= cleanup;
      }
      if (cleanupError != null) {
        throw StateError(
          'Không thể hoàn tất tài liệu ($error). Tệp có thể còn sót tại '
          '$path và không dọn được: $cleanupError.',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateDocument({
    required CloudDocument document,
    required String title,
    required String? description,
    required String? subject,
    required DocumentType type,
    PlatformFile? replacementFile,
  }) async {
    final normalizedTitle = title.trim();
    _validateTitle(normalizedTitle);
    final userId = _requireCurrentUserId();

    String? newPath;
    int? newSize;
    String? newMimeType;
    Uint8List? replacementBytes;
    if (replacementFile != null) {
      if (!document.isOwner) {
        throw StateError('Chỉ chủ sở hữu mới được thay tệp.');
      }
      replacementBytes = await _fileBytes(replacementFile);
      newPath = _storage.createObjectPath(
        ownerId: userId,
        documentId: document.id,
        fileName: replacementFile.name,
      );
      newSize = replacementBytes.length;
      newMimeType = SupabaseStorageService.mimeType(replacementFile.name);
    }

    final changes = <String, dynamic>{
      'title': normalizedTitle,
      'description': _normalize(description),
      'subject': _normalize(subject),
      'document_type': type.name,
    };
    if (newPath != null) changes['storage_path'] = newPath;
    if (newMimeType != null) changes['mime_type'] = newMimeType;
    if (newSize != null) changes['file_size_bytes'] = newSize;

    var uploadStarted = false;
    try {
      if (replacementFile != null && newPath != null) {
        uploadStarted = true;
        await _storage.upload(
          path: newPath,
          fileName: replacementFile.name,
          bytes: replacementBytes!,
        );
      }
      final updated = await _client
          .from('documents')
          .update(changes)
          .eq('id', document.id)
          .select('id');
      if (updated.isEmpty) {
        throw StateError('Không còn quyền cập nhật tài liệu này.');
      }
    } catch (error, stackTrace) {
      if (uploadStarted && newPath != null) {
        try {
          await _storage.delete(newPath);
        } catch (cleanup) {
          throw StateError(
            'Không thể cập nhật tài liệu ($error). Tệp mới có thể còn sót tại '
            '$newPath; dọn dẹp thất bại: $cleanup.',
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    if (newPath != null && document.storagePath != null) {
      try {
        await _storage.delete(document.storagePath!);
      } catch (error) {
        throw StateError(
          'Metadata và tệp mới đã cập nhật, nhưng tệp cũ chưa được xóa '
          '(${document.storagePath}): $error',
        );
      }
    }
  }

  Future<void> deleteDocument(CloudDocument document) async {
    if (!document.isOwner) {
      throw StateError('Chỉ chủ sở hữu mới được xóa tài liệu.');
    }
    final deleted = await _client
        .from('documents')
        .delete()
        .eq('id', document.id)
        .select('id');
    if (deleted.isEmpty) {
      throw StateError('Không còn quyền xóa tài liệu này.');
    }
    if (document.storagePath != null) {
      try {
        await _storage.delete(document.storagePath!);
      } catch (error) {
        throw StateError(
          'Bản ghi đã xóa nhưng tệp riêng tư chưa được dọn tại '
          '${document.storagePath}: $error',
        );
      }
    }
  }

  Future<void> shareDocument({
    required String documentId,
    required String email,
    required String permission,
  }) async {
    await _client.rpc(
      'share_document_with_email',
      params: {
        'p_document_id': documentId,
        'p_email': email.trim(),
        'p_permission': permission,
      },
    );
  }

  Future<void> revokeShare({
    required String documentId,
    required String userId,
  }) async {
    await _client.rpc(
      'revoke_document_share',
      params: {'p_document_id': documentId, 'p_user_id': userId},
    );
  }

  Future<List<Map<String, dynamic>>> getShares(String documentId) async {
    final rows = await _client.rpc(
      'list_document_shares',
      params: {'p_document_id': documentId},
    );
    return (rows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Uri> getAuthorizedDownloadUri(String documentId) async {
    final document = await getDocument(documentId);
    final path = document?.storagePath;
    if (document == null || path == null) {
      throw StateError('Không tìm thấy tệp hoặc bạn không có quyền truy cập.');
    }
    return _storage.createDownloadUri(path);
  }

  Future<Uint8List> _fileBytes(PlatformFile file) async {
    final size = await file.length();
    if (size != null && size > SupabaseStorageService.maxFileSizeBytes) {
      throw ArgumentError('Tệp không được vượt quá 20 MB.');
    }
    final bytes = await file.readAsBytes();
    SupabaseStorageService.validateFile(
      fileName: file.name,
      size: bytes.length,
    );
    return bytes;
  }

  String _requireCurrentUserId() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw StateError('Bạn cần đăng nhập lại.');
    return userId;
  }

  String? _normalize(String? text) {
    final normalized = text?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void _validateTitle(String title) {
    if (title.isEmpty) throw ArgumentError('Tên tài liệu không được để trống.');
    if (title.length > 250) {
      throw ArgumentError('Tên tài liệu không được vượt quá 250 ký tự.');
    }
  }
}
