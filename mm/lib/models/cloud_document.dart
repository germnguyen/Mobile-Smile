import '../struct/document_type.dart';

class CloudDocument {
  const CloudDocument({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.documentType,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.subject,
    this.storagePath,
    this.mimeType,
    this.fileSizeBytes,
    this.permission,
  });

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? subject;
  final DocumentType documentType;
  final String? storagePath;
  final String? mimeType;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? permission;

  bool get isOwner => permission == 'owner';
  bool get canEdit => isOwner || permission == 'editor';

  factory CloudDocument.fromMap(Map<String, dynamic> map) {
    final typeName = map['document_type'] as String? ?? 'other';
    final type = DocumentType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => DocumentType.other,
    );

    return CloudDocument(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      subject: map['subject'] as String?,
      documentType: type,
      storagePath: map['storage_path'] as String?,
      mimeType: map['mime_type'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      permission: map['permission'] as String?,
    );
  }
}
