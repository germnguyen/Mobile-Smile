import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/cloud_document_service.dart';
import 'signed_in_page.dart';
import 'sign_in_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.cloudDocumentService,
  });

  final AuthService authService;
  final CloudDocumentService cloudDocumentService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Không thể khôi phục phiên đăng nhập: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return SignInPage(authService: authService);
        }

        return SignedInPage(
          user: snapshot.data!,
          authService: authService,
          cloudDocumentService: cloudDocumentService,
        );
      },
    );
  }
}
