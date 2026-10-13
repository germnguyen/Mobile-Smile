import 'package:flutter/material.dart';

import '../struct/document_type.dart';

class DocumentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController titleController;
  final TextEditingController subjectController;
  final TextEditingController descriptionController;
  final TextEditingController filePathController;

  final DocumentType selectedType;
  final ValueChanged<DocumentType> onTypeChanged;

  final VoidCallback onSubmit;
  final String submitText;

  const DocumentForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.subjectController,
    required this.descriptionController,
    required this.filePathController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onSubmit,
    this.submitText = 'Lưu tài liệu',
  });

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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: titleController,
            textInputAction:
                TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Tên tài liệu',
              hintText:
                  'Ví dụ: Bài giảng Java OOP',
              prefixIcon: Icon(
                Icons.title,
              ),
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Vui lòng nhập tên tài liệu.';
              }

              if (value.trim().length > 250) {
                return 'Tên tài liệu không được vượt quá 250 ký tự.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<DocumentType>(
            initialValue: selectedType,
            decoration: const InputDecoration(
              labelText: 'Loại tài liệu',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: DocumentType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getTypeName(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onTypeChanged(value);
              }
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: subjectController,
            decoration: const InputDecoration(
              labelText: 'Môn học',
              hintText: 'Ví dụ: Lập trình Java',
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: titleController,
            textInputAction:
                TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Tên tài liệu',
              hintText:
                  'Ví dụ: Bài giảng Java OOP',
              prefixIcon: Icon(
                Icons.title,
              ),
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Vui lòng nhập tên tài liệu.';
              }

              if (value.trim().length > 250) {
                return 'Tên tài liệu không được vượt quá 250 ký tự.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: filePathController,
            decoration: const InputDecoration(
              labelText: 'Đường dẫn file',
              hintText: 'Ví dụ: D:/Documents/java.pdf',
              prefixIcon: Icon(Icons.insert_drive_file),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.save),
              label: Text(submitText),
            ),
          ),
        ],
      ),
    );
  }
}