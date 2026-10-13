import 'package:flutter/material.dart';
import 'package:mm/database/app_database.dart';

import '../database/tables.dart';
import '../struct/document_type.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDelete,
  });

  String _getTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.lecture:
        return 'Bài giảng';

      case DocumentType.assignment:
        return 'Bài tập';

      case DocumentType.reference:
        return 'Tham khảo';

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

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------
              // ICON
              // ---------------------------------------------

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme
                      .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  _getTypeIcon(
                    document.documentType,
                  ),
                  color: colorScheme
                      .onPrimaryContainer,
                ),
              ),

              const SizedBox(width: 14),

              // ---------------------------------------------
              // CONTENT
              // ---------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 6),

                    if (document.subject !=
                        null)
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 16,
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Expanded(
                            child: Text(
                              document.subject!,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: theme
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // ---------------------------------------
                    // TYPE CHIP
                    // ---------------------------------------

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: colorScheme
                            .secondaryContainer,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        _getTypeName(
                          document.documentType,
                        ),
                        style: theme
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: colorScheme
                                  .onSecondaryContainer,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------
              // DELETE
              // ---------------------------------------------

              if (onDelete != null)
                IconButton(
                  tooltip: 'Xóa',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}