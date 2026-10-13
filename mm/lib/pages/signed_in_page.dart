import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cloud_document.dart';
import '../services/auth_service.dart';
import '../services/cloud_document_service.dart';
import '../struct/document_type.dart';
import 'cloud_document_detail_page.dart';
import 'cloud_document_form_page.dart';

class SignedInPage extends StatefulWidget {
  const SignedInPage({
    super.key,
    required this.user,
    required this.authService,
    required this.cloudDocumentService,
  });

  final User user;
  final AuthService authService;
  final CloudDocumentService cloudDocumentService;

  @override
  State<SignedInPage> createState() => _SignedInPageState();
}

class _SignedInPageState extends State<SignedInPage> {
  final _searchController = TextEditingController();
  List<CloudDocument> _documents = const [];
  DocumentType? _selectedType;
  bool _isLoading = true;
  bool _profileReady = false;
  String? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void didUpdateWidget(covariant SignedInPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid == widget.user.uid) return;

    _loadGeneration++;
    _documents = const [];
    _profileReady = false;
    _isLoading = true;
    _error = null;
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final generation = ++_loadGeneration;
    final userId = widget.user.uid;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      if (!_profileReady) {
        await widget.cloudDocumentService.ensureProfile(widget.user);
        if (!_isCurrentLoad(generation, userId)) return;
        _profileReady = true;
      }
      final documents = await widget.cloudDocumentService.searchDocuments(
        keyword: _searchController.text,
        type: _selectedType,
      );
      if (!_isCurrentLoad(generation, userId)) return;
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (error) {
      if (!_isCurrentLoad(generation, userId)) return;
      setState(() {
        _isLoading = false;
        _error = _profileReady
            ? 'Không thể tải dữ liệu đám mây: $error'
            : 'Không thể xác nhận danh tính hoặc đồng bộ hồ sơ. Dữ liệu đám '
                  'mây vẫn bị khóa. Chi tiết: $error';
      });
    }
  }

  bool _isCurrentLoad(int generation, String userId) =>
      mounted && generation == _loadGeneration && widget.user.uid == userId;

  Future<void> _openForm([CloudDocument? document]) async {
    if (!_profileReady) return;
    if (document != null && !document.canEdit) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CloudDocumentFormPage(
          service: widget.cloudDocumentService,
          document: document,
        ),
      ),
    );
    if (saved == true) await _loadDocuments();
  }

  Future<void> _openDocument(CloudDocument document) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CloudDocumentDetailPage(
          documentId: document.id,
          service: widget.cloudDocumentService,
        ),
      ),
    );
    if (mounted) await _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài liệu học tập'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadDocuments,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await widget.authService.signOut();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể đăng xuất: $error')),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _profileReady ? () => _openForm() : null,
        tooltip: 'Thêm tài liệu',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadDocuments(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài liệu...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          _loadDocuments();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<DocumentType?>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Lọc theo loại',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<DocumentType?>(
                  value: null,
                  child: Text('Tất cả loại tài liệu'),
                ),
                ...DocumentType.values.map(
                  (type) => DropdownMenuItem<DocumentType?>(
                    value: type,
                    child: Text(_typeName(type)),
                  ),
                ),
              ],
              onChanged: (type) {
                setState(() => _selectedType = type);
                _loadDocuments();
              },
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadDocuments,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (_documents.isEmpty) {
      return const Center(child: Text('Chưa có tài liệu phù hợp.'));
    }
    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final document = _documents[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.description_outlined),
              ),
              title: Text(document.title),
              subtitle: Text(
                [
                  if (document.subject != null) document.subject!,
                  _typeName(document.documentType),
                  if (!document.isOwner)
                    document.permission == 'editor'
                        ? 'Được chỉnh sửa'
                        : 'Được chia sẻ',
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: document.storagePath == null
                  ? null
                  : const Icon(Icons.attach_file),
              onTap: () => _openDocument(document),
            ),
          );
        },
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
