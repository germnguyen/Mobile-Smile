import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cloud_document.dart';
import '../services/cloud_document_service.dart';
import 'cloud_document_form_page.dart';

class CloudDocumentDetailPage extends StatefulWidget {
  const CloudDocumentDetailPage({
    super.key,
    required this.documentId,
    required this.service,
  });

  final String documentId;
  final CloudDocumentService service;

  @override
  State<CloudDocumentDetailPage> createState() =>
      _CloudDocumentDetailPageState();
}

class _CloudDocumentDetailPageState extends State<CloudDocumentDetailPage> {
  CloudDocument? _document;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final document = await widget.service.getDocument(widget.documentId);
      if (!mounted) return;
      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải tài liệu: $error';
      });
    }
  }

  Future<void> _edit() async {
    final document = _document;
    if (document == null || !document.canEdit) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CloudDocumentFormPage(service: widget.service, document: document),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final uri = await widget.service.getAuthorizedDownloadUri(
        widget.documentId,
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('Không mở được liên kết tải tệp.');
    } catch (error) {
      if (mounted) {
        _showMessage('Không thể mở tệp: $error');
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _share() async {
    final emailController = TextEditingController();
    var permission = 'viewer';
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chia sẻ tài liệu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email tài khoản đã đăng ký',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: permission,
                decoration: const InputDecoration(labelText: 'Quyền'),
                items: const [
                  DropdownMenuItem(value: 'viewer', child: Text('Chỉ xem')),
                  DropdownMenuItem(
                    value: 'editor',
                    child: Text('Xem và chỉnh sửa'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => permission = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Chia sẻ'),
            ),
          ],
        ),
      ),
    );

    if (shouldShare != true) {
      emailController.dispose();
      return;
    }
    try {
      await widget.service.shareDocument(
        documentId: widget.documentId,
        email: emailController.text,
        permission: permission,
      );
      if (mounted) _showMessage('Đã cấp quyền chia sẻ.');
    } catch (error) {
      if (mounted) _showMessage('Không thể chia sẻ tài liệu: $error');
    } finally {
      emailController.dispose();
    }
  }

  Future<void> _manageShares() async {
    try {
      final shares = await widget.service.getShares(widget.documentId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Quyền đang chia sẻ'),
            content: SizedBox(
              width: 420,
              child: shares.isEmpty
                  ? const Text('Chưa chia sẻ tài liệu này.')
                  : ListView(
                      shrinkWrap: true,
                      children: shares.map((share) {
                        final email =
                            share['email'] as String? ??
                            share['user_id'] as String;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(email),
                          subtitle: Text(
                            share['permission'] == 'editor'
                                ? 'Xem và chỉnh sửa'
                                : 'Chỉ xem',
                          ),
                          trailing: IconButton(
                            tooltip: 'Thu hồi quyền',
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () async {
                              try {
                                await widget.service.revokeShare(
                                  documentId: widget.documentId,
                                  userId: share['user_id'] as String,
                                );
                                setDialogState(() => shares.remove(share));
                              } catch (error) {
                                if (context.mounted) {
                                  _showMessage(
                                    'Không thể thu hồi quyền: $error',
                                  );
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showMessage('Không thể tải danh sách chia sẻ: $error');
    }
  }

  Future<void> _delete() async {
    final document = _document;
    if (document == null || !document.isOwner) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài liệu?'),
        content: Text('Bạn có chắc muốn xóa "${document.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteDocument(document);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showMessage('Không thể xóa tài liệu: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu'),
        actions: [
          if (document?.canEdit == true)
            IconButton(
              tooltip: 'Chỉnh sửa',
              onPressed: _edit,
              icon: const Icon(Icons.edit),
            ),
          if (document?.isOwner == true)
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'share') _share();
                if (action == 'manage') _manageShares();
                if (action == 'delete') _delete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Chia sẻ')),
                PopupMenuItem(
                  value: 'manage',
                  child: Text('Quản lý quyền chia sẻ'),
                ),
                PopupMenuItem(value: 'delete', child: Text('Xóa tài liệu')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, textAlign: TextAlign.center))
          : document == null
          ? const Center(child: Text('Không tìm thấy tài liệu.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  document.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                if (document.subject != null)
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('Môn học'),
                    subtitle: Text(document.subject!),
                  ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Loại tài liệu'),
                  subtitle: Text(document.documentType.name),
                ),
                if (document.description != null)
                  ListTile(
                    leading: const Icon(Icons.notes),
                    title: const Text('Mô tả'),
                    subtitle: Text(document.description!),
                  ),
                if (document.storagePath != null)
                  FilledButton.icon(
                    onPressed: _isDownloading ? null : _download,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isDownloading ? 'Đang tạo liên kết...' : 'Mở / tải tệp',
                    ),
                  )
                else
                  const ListTile(
                    leading: Icon(Icons.insert_drive_file_outlined),
                    title: Text('Chưa có tệp đính kèm'),
                  ),
              ],
            ),
    );
  }
}
