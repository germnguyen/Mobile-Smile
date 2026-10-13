import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_dependencies.dart';
import 'config/app_theme.dart';
import 'pages/document_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fzzsffkeajsqjjaljojk.supabase.co',
    publishableKey: 'sb_publishable_FCP9pJuNh6MlQX0HXFVGNw_5QnzQpvQ',
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

      home: DocumentListPage(
        service: dependencies.documentService,
      ),
    );
  }
}