import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SignedInPage extends StatelessWidget {
  const SignedInPage({
    super.key,
    required this.user,
    required this.authService,
  });

  final User user;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài liệu'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await authService.signOut();
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Đã đăng nhập${user.displayName == null ? '' : ' với ${user.displayName}'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (user.email != null) ...[
                const SizedBox(height: 8),
                Text(user.email!),
              ],
              const SizedBox(height: 24),
              const Text(
                'Dữ liệu tài liệu trên đám mây chưa được kết nối. '
                'Tạm thời ẩn dữ liệu SQLite cục bộ để tránh hiển thị '
                'tài liệu của tài khoản khác.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
