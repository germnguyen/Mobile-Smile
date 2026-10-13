import 'package:flutter/material.dart';
import 'package:mm/database/app_database.dart';

import '../database/tables.dart';
import '../services/document_service.dart';
import '../struct/document_type.dart';
import '../widgets/document_form.dart';

class DocumentFormPage extends StatefulWidget {
  final Document? document;

  // Service được truyền từ bên ngoài vào.
  final DocumentService service;

  const DocumentFormPage({
    super.key,
    this.document,
    required this.service,
  });

  bool get isEditing => document != null;

  @override
  State<DocumentFormPage> createState() =>
      _DocumentFormPageState();
}

class _DocumentFormPageState
    extends State<DocumentFormPage> {
  // Không tự tạo DocumentService nữa.
  // Service được nhận từ widget.
  DocumentService get _service => widget.service;

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController =
      TextEditingController();
  final _filePathController =
      TextEditingController();

  DocumentType _selectedType =
      DocumentType.other;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _initializeForm();
  }

  // =========================================================
  // INITIALIZE FORM
  // =========================================================

  void _initializeForm() {
    final document = widget.document;

    // Không có document
    // => đang ở chế độ THÊM.
    if (document == null) {
      return;
    }

    // Có document
    // => đang ở chế độ CHỈNH SỬA.
    _titleController.text = document.title;

    _subjectController.text =
        document.subject ?? '';

    _descriptionController.text =
        document.description ?? '';

    _filePathController.text =
        document.filePath ?? '';

    _selectedType =
        document.documentType;
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _filePathController.dispose();

    // Không close database ở đây.
    //
    // Vì Page không tạo database.
    // Database được quản lý bởi AppDependencies.
    super.dispose();
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        await _updateDocument();
      } else {
        await _addDocument();
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể lưu tài liệu: $error',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ADD
  // =========================================================

  Future<void> _addDocument() async {
    await _service.addDocument(
      title: _titleController.text,
      subject: _subjectController.text,
      description: _descriptionController.text,
      filePath: _filePathController.text,
      documentType: _selectedType,
    );
  }

  // =========================================================
  // UPDATE
  // =========================================================

  Future<void> _updateDocument() async {
    final document = widget.document!;

    final updated =
        await _service.updateDocument(
      id: document.id,
      title: _titleController.text,
      subject: _subjectController.text,
      description: _descriptionController.text,
      filePath: _filePathController.text,
      documentType: _selectedType,
    );

    if (!updated) {
      throw Exception(
        'Không tìm thấy tài liệu cần cập nhật.',
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Chỉnh sửa tài liệu'
              : 'Thêm tài liệu',
        ),
      ),

      body: _isSaving
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : DocumentForm(
              formKey: _formKey,

              titleController:
                  _titleController,

              subjectController:
                  _subjectController,

              descriptionController:
                  _descriptionController,

              filePathController:
                  _filePathController,

              selectedType:
                  _selectedType,

              onTypeChanged: (type) {
                setState(() {
                  _selectedType = type;
                });
              },

              onSubmit: _saveDocument,

              submitText:
                  widget.isEditing
                      ? 'Lưu thay đổi'
                      : 'Lưu tài liệu',
            ),
    );
  }
}