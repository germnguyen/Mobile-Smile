import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  SupabaseStorageService({
    required this.client,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const String bucket = 'documents';
  static const int maxFileSizeBytes = 20 * 1024 * 1024;
  static const int signedUrlLifetimeSeconds = 60;

  static const Map<String, String> _mimeTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
  };

  final SupabaseClient client;
  final DateTime Function() _now;

  String createObjectPath({
    required String ownerId,
    required String documentId,
    required String fileName,
  }) {
    if (!_isPathSegment(ownerId) || !_isPathSegment(documentId)) {
      throw ArgumentError('Chủ sở hữu hoặc mã tài liệu không hợp lệ.');
    }
    final normalizedName = fileName.split(RegExp(r'[/\\]')).last;
    final extension = _extension(normalizedName);
    if (!_mimeTypes.containsKey(extension)) {
      throw ArgumentError('Định dạng tệp không được hỗ trợ.');
    }
    final safeName = normalizedName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    return '$ownerId/$documentId/${_now().microsecondsSinceEpoch}_$safeName';
  }

  Future<void> upload({
    required String path,
    required String fileName,
    required Uint8List bytes,
  }) async {
    validateFile(fileName: fileName, size: bytes.length);
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType(fileName),
            cacheControl: '0',
            upsert: false,
          ),
        );
  }

  Future<Uri> createDownloadUri(String path) async {
    final signedUrl = await client.storage
        .from(bucket)
        .createSignedUrl(path, signedUrlLifetimeSeconds);
    return Uri.parse(signedUrl);
  }

  Future<void> delete(String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  static void validateFile({required String fileName, required int size}) {
    if (!_mimeTypes.containsKey(_extension(fileName))) {
      throw ArgumentError('Định dạng tệp không được hỗ trợ.');
    }
    if (size <= 0) {
      throw ArgumentError('Tệp đã chọn không có nội dung.');
    }
    if (size > maxFileSizeBytes) {
      throw ArgumentError('Tệp không được vượt quá 20 MB.');
    }
  }

  static String mimeType(String fileName) {
    final type = _mimeTypes[_extension(fileName)];
    if (type == null) {
      throw ArgumentError('Định dạng tệp không được hỗ trợ.');
    }
    return type;
  }

  static bool _isPathSegment(String value) =>
      value.isNotEmpty && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);

  static String _extension(String fileName) {
    final separator = fileName.lastIndexOf('.');
    return separator < 0 ? '' : fileName.substring(separator + 1).toLowerCase();
  }
}
