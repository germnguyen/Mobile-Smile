import 'package:flutter/material.dart';
import 'package:mm/database/app_database.dart';

import '../database/tables.dart';
import '../services/document_service.dart';
import '../struct/document_type.dart';
import '../widgets/document_card.dart';
import '../widgets/document_filter.dart';
import '../widgets/document_search.dart';
import '../widgets/empty_state.dart';
import 'document_detail_page.dart';
import 'document_form_page.dart';

class DocumentListPage extends StatefulWidget {
  final DocumentService service;

  const DocumentListPage({
    super.key,
    required this.service,
  });

  @override
  State<DocumentListPage> createState() =>
      _DocumentListPageState();
}

class _DocumentListPageState
    extends State<DocumentListPage> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController _searchController =
      TextEditingController();

  // =========================================================
  // STATE
  // =========================================================

  List<Document> _documents = [];

  bool _isLoading = true;

  String _searchKeyword = '';

  // Bộ lọc loại tài liệu.
  //
  // null = tất cả loại tài liệu
  DocumentType? _selectedType;

  // Service được truyền từ bên ngoài vào.
  DocumentService get _service => widget.service;

  // Kiểm tra xem người dùng có đang sử dụng
  // ít nhất một bộ lọc hay không.
  bool get _hasFilter =>
      _searchKeyword.isNotEmpty ||
      _selectedType != null;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadDocuments();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD DOCUMENTS
  // =========================================================

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final documents =
          await _service.searchDocuments(
        keyword: _searchKeyword,
        type: _selectedType,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Không thể tải tài liệu: $error',
      );
    }
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<void> _search(String keyword) async {
    _searchKeyword = keyword;

    await _loadDocuments();
  }

  // =========================================================
  // FILTER
  // =========================================================

  Future<void> _filterByType(
    DocumentType? type,
  ) async {
    setState(() {
      _selectedType = type;
    });

    await _loadDocuments();
  }

  // =========================================================
  // CLEAR FILTER
  // =========================================================

  Future<void> _clearFilters() async {
    setState(() {
      _searchKeyword = '';
      _selectedType = null;
      _searchController.clear();
    });

    await _loadDocuments();
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> _deleteDocument(
    Document document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Xóa tài liệu?',
          ),
          content: Text(
            'Bạn có chắc muốn xóa '
            '"${document.title}" không?',
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
      document.id,
    );

    if (!mounted) {
      return;
    }

    if (deleted) {
      _showMessage(
        'Đã xóa tài liệu.',
      );

      await _loadDocuments();
    } else {
      _showError(
        'Không tìm thấy tài liệu.',
      );
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài liệu học tập',
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: DocumentSearch(
              controller: _searchController,
              onChanged: _search,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: DocumentFilter(
              selectedType: _selectedType,
              onChanged: _filterByType,
            ),
          ),

          if (_hasFilter)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 16,
                  bottom: 8,
                ),
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(
                    Icons.filter_alt_off,
                  ),
                  label: const Text(
                    'Xóa bộ lọc',
                  ),
                ),
              ),
            ),

          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      // =====================================================
      // ADD DOCUMENT
      // =====================================================

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DocumentFormPage(
                service: _service,
              ),
            ),
          );

          if (result == true) {
            await _loadDocuments();
          }
        },
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }

  // =========================================================
  // BODY
  // =========================================================

  Widget _buildBody() {
    // -------------------------------------------------------
    // LOADING
    // -------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // -------------------------------------------------------
    // EMPTY RESULT
    // -------------------------------------------------------

    if (_documents.isEmpty) {
      if (_hasFilter) {
        return const EmptyState(
          icon: Icons.search_off,
          message:
              'Không tìm thấy tài liệu phù hợp.',
        );
      }

      return const EmptyState();
    }

    // -------------------------------------------------------
    // DOCUMENT LIST
    // -------------------------------------------------------

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (
          context,
          index,
        ) {
          final document =
              _documents[index];

          return DocumentCard(
            document: document,

            // ------------------------------------------------
            // DELETE
            // ------------------------------------------------

            onDelete: () {
              _deleteDocument(document);
            },

            // ------------------------------------------------
            // DETAIL
            // ------------------------------------------------

            onTap: () async {
              final result =
                  await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DocumentDetailPage(
                    documentId: document.id,
                    service: _service,
                  ),
                ),
              );

              if (result == true) {
                await _loadDocuments();
              }
            },
          );
        },
      ),
    );
  }
}