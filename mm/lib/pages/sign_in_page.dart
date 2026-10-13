import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isSigningIn = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      final signedIn = await widget.authService.signInWithGoogle();
      if (!mounted) return;

      setState(() {
        _isSigningIn = false;
        if (!signedIn) {
          _errorMessage = 'Bạn đã hủy đăng nhập.';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSigningIn = false;
        _errorMessage = 'Đăng nhập thất bại: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_shared_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Quản lý Tài liệu',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (_isSigningIn)
                  const CircularProgressIndicator()
                else
                  FilledButton.icon(
                    onPressed: _signIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Đăng nhập bằng Google'),
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
