import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/responsive_mobile_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DisciplineApp());
}

class DisciplineApp extends StatelessWidget {
  const DisciplineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kỷ Luật Cá Nhân',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return ResponsiveMobileWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}
