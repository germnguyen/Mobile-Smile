import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          Center(child: Text('Danh sách thói quen (Đang khởi tạo)')),
          Center(child: Text('Thống kê tiến độ (Đang khởi tạo)')),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.check_circle, color: AppTheme.primaryColor),
              label: 'Thói quen',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.bar_chart, color: AppTheme.primaryColor),
              label: 'Thống kê',
            ),
          ],
        ),
      ),
    );
  }
}
