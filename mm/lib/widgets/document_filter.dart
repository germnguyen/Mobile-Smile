import 'package:flutter/material.dart';

import '../struct/document_type.dart';

class DocumentFilter extends StatelessWidget {
  final DocumentType? selectedType;
  final ValueChanged<DocumentType?> onChanged;

  const DocumentFilter({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  String _getTypeName(
    DocumentType type,
  ) {
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
    return DropdownButtonFormField<
        DocumentType?>(
      initialValue: selectedType,
      decoration: const InputDecoration(
        labelText: 'Loại tài liệu',
        prefixIcon: Icon(
          Icons.filter_list,
        ),
      ),
      items: [
        const DropdownMenuItem<
            DocumentType?>(
          value: null,
          child: Text(
            'Tất cả loại tài liệu',
          ),
        ),
        ...DocumentType.values.map(
          (type) {
            return DropdownMenuItem<
                DocumentType?>(
              value: type,
              child: Text(
                _getTypeName(type),
              ),
            );
          },
        ),
      ],
      onChanged: onChanged,
    );
  }
}