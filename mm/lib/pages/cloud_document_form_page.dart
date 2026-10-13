import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/cloud_document.dart';
import '../services/cloud_document_service.dart';
import '../services/supabase_storage_service.dart';
import '../struct/document_type.dart';

class CloudDocumentFormPage extends StatefulWidget {
  const CloudDocumentFormPage({
    super.key,
    required this.service,
    this.document,
  });

  final CloudDocumentService service;
  final CloudDocument? document;

  @override
  State<CloudDocumentFormPage> createState() => _CloudDocumentFormPageState();
}

class _CloudDocumentFormPageState extends State<CloudDocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _subjectController;
  late DocumentType _type;
  PlatformFile? _file;
  int? _fileSize;
  bool _isSaving = false;

  bool get _isEditing => widget.document != null;

  @override
  void initState() {
    super.initState();
    final document = widget.document;
    _titleController = TextEditingController(text: document?.title ?? '');
    _descriptionController = TextEditingController(
      text: document?.description ?? '',
    );
    _subjectController = TextEditingController(text: document?.subject ?? '');
    _type = document?.documentType ?? DocumentType.other;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'png',
          'jpg',
          'jpeg',
        ],
      );
      if (files.isEmpty || !mounted) return;
      final file = files.single;
      final size = await file.length();
      if (size != null && size > SupabaseStorageService.maxFileSizeBytes) {
        throw ArgumentError('Tệp không được vượt quá 20 MB.');
      }
      if (!mounted) return;
      setState(() {
        _file = file;
        _fileSize = size;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể chọn tệp: $error')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await widget.service.updateDocument(
          document: widget.document!,
          title: _titleController.text,
          description: _descriptionController.text,
          subject: _subjectController.text,
          type: _type,
          replacementFile: _file,
        );
      } else {
        await widget.service.createDocument(
          title: _titleController.text,
          description: _descriptionController.text,
          subject: _subjectController.text,
          type: _type,
          file: _file,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu tài liệu: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    maxLength: 250,
                    decoration: const InputDecoration(
                      labelText: 'Tên tài liệu',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên tài liệu.';
                      }
                      if (value.trim().length > 250) {
                        return 'Tên tài liệu không được vượt quá 250 ký tự.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DocumentType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Loại tài liệu',
                      border: OutlineInputBorder(),
                    ),
                    items: DocumentType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_typeName(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (type) {
                      if (type != null) setState(() => _type = type);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Môn học',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _file?.name ??
                          (widget.document?.storagePath == null
                              ? 'Chọn tệp (tối đa 20 MB)'
                              : 'Thay tệp đính kèm'),
                    ),
                  ),
                  if (_file != null)
                    Text(
                      _fileSize == null
                          ? 'Kích thước sẽ được kiểm tra khi tải lên.'
                          : '${(_fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditing ? 'Lưu thay đổi' : 'Lưu tài liệu'),
                  ),
                ],
              ),
            ),
    );
  }

  String _typeName(DocumentType type) {
    return switch (type) {
      DocumentType.lecture => 'Bài giảng',
      DocumentType.assignment => 'Bài tập',
      DocumentType.reference => 'Tài liệu tham khảo',
      DocumentType.other => 'Khác',
    };
  }
}
