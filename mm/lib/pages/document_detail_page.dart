import 'package:flutter/material.dart';
import 'package:mm/database/app_database.dart';

import '../database/tables.dart';
import '../services/document_service.dart';
import '../struct/document_type.dart';
import 'document_form_page.dart';

class DocumentDetailPage extends StatefulWidget {
  final int documentId;
  final DocumentService service;

  const DocumentDetailPage({
    super.key,
    required this.documentId,
    required this.service,
  });

  @override
  State<DocumentDetailPage> createState() =>
      _DocumentDetailPageState();
}

class _DocumentDetailPageState
    extends State<DocumentDetailPage> {
  DocumentService get _service => widget.service;

  Document? _document;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final document =
          await _service.getDocumentById(
        widget.documentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Không thể tải tài liệu: $error',
      );
    }
  }

  String _getTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.lecture:
        return 'Bài giảng';

      case DocumentType.assignment:
        return 'Bài tập';

      case DocumentType.reference:
        return 'Tài liệu tham khảo';

      case DocumentType.other:
        return 'Khác';
    }
  }

  IconData _getTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.lecture:
        return Icons.menu_book;

      case DocumentType.assignment:
        return Icons.assignment;

      case DocumentType.reference:
        return Icons.library_books;

      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _editDocument() async {
    if (_document == null) {
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentFormPage(
          document: _document,
          service: _service,
        ),
      ),
    );

    if (result == true) {
      await _loadDocument();
    }
  }

  Future<void> _deleteDocument() async {
    if (_document == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Xóa tài liệu?',
          ),
          content: Text(
            'Bạn có chắc muốn xóa '
            '"${_document!.title}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final deleted =
        await _service.deleteDocument(
      _document!.id,
    );

    if (!mounted) {
      return;
    }

    if (deleted) {
      Navigator.pop(
        context,
        true,
      );
    } else {
      _showMessage(
        'Không tìm thấy tài liệu.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildInfo(
    String label,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(
          top: 4,
        ),
        child: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chi tiết tài liệu',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_document == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chi tiết tài liệu',
          ),
        ),
        body: const Center(
          child: Text(
            'Không tìm thấy tài liệu.',
          ),
        ),
      );
    }

    final document = _document!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết tài liệu',
        ),
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa',
            onPressed: _editDocument,
            icon: const Icon(
              Icons.edit,
            ),
          ),
          IconButton(
            tooltip: 'Xóa',
            onPressed: _deleteDocument,
            icon: const Icon(
              Icons.delete_outline,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            child: Icon(
              _getTypeIcon(
                document.documentType,
              ),
              size: 40,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            document.title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                _buildInfo(
                  'Loại tài liệu',
                  _getTypeName(
                    document.documentType,
                  ),
                  Icons.category,
                ),

                if (document.subject != null)
                  _buildInfo(
                    'Môn học',
                    document.subject!,
                    Icons.school,
                  ),

                if (document.description != null)
                  _buildInfo(
                    'Mô tả',
                    document.description!,
                    Icons.description,
                  ),

                if (document.filePath != null)
                  _buildInfo(
                    'Đường dẫn file',
                    document.filePath!,
                    Icons.insert_drive_file,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}