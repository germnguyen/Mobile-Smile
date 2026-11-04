import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import 'habit_form_screen.dart';
import 'habit_list_screen.dart';
import 'statistics_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _openHabitForm([Habit? habit]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HabitFormScreen(habit: habit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HabitListScreen(
        onAddHabit: () => _openHabitForm(),
        onEditHabit: (habit) => _openHabitForm(habit),
      ),
      const StatisticsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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
          indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.15),
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
