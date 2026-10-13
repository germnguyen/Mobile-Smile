import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'config/app_dependencies.dart';
import 'config/app_theme.dart';
import 'pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();

  await Supabase.initialize(
    url: 'https://fzzsffkeajsqjjaljojk.supabase.co',
    publishableKey: 'sb_publishable_FCP9pJuNh6MlQX0HXFVGNw_5QnzQpvQ',
    accessToken: () async =>
        FirebaseAuth.instance.currentUser?.getIdToken(),
  );

  final dependencies =
      AppDependencies.create();

  runApp(
    StudyCashewApp(
      dependencies: dependencies,
    ),
  );
}

class StudyCashewApp extends StatelessWidget {
  final AppDependencies dependencies;

  const StudyCashewApp({
    super.key,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Study Cashew',

      theme: AppTheme.lightTheme(),

      darkTheme: AppTheme.darkTheme(),

      themeMode: ThemeMode.system,

      home: AuthGate(
        authService: dependencies.authService,
      ),
    );
  }
}