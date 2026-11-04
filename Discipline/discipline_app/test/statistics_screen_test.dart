import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discipline_app/models/habit.dart';
import 'package:discipline_app/providers/habit_provider.dart';
import 'package:discipline_app/screens/statistics_screen.dart';
import 'package:discipline_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StatisticsScreen renders day, week, month tabs and handles empty data', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    final provider = HabitProvider(storageService: storage);
    await provider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: StatisticsScreen(),
        ),
      ),
    );

    // Initial check: Day tab
    expect(find.text('Thống Kê Kỷ Luật'), findsOneWidget);
    expect(find.text('Theo Ngày'), findsOneWidget);
    expect(find.text('Theo Tuần'), findsOneWidget);
    expect(find.text('Theo Tháng'), findsOneWidget);
    expect(find.text('Tiến độ hôm nay'), findsOneWidget);

    // Switch to Week tab
    await tester.tap(find.text('Theo Tuần'));
    await tester.pumpAndSettle();
    expect(find.text('Biểu đồ 7 ngày gần nhất'), findsOneWidget);
    expect(find.text('Tỷ lệ hoàn thành tuần'), findsOneWidget);

    // Switch to Month tab
    await tester.tap(find.text('Theo Tháng'));
    await tester.pumpAndSettle();
    expect(find.text('Số ngày hoạt động'), findsOneWidget);
    expect(find.text('Thói quen kiên trì nhất'), findsOneWidget);
  });

  testWidgets('StatisticsScreen displays populated habit data and completion rates', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    final provider = HabitProvider(storageService: storage);
    await provider.init();

    final habit1 = Habit(id: 'h1', title: 'Thiền định 10 phút');
    final habit2 = Habit(id: 'h2', title: 'Uống đủ nước');
    await provider.addHabit(habit1);
    await provider.addHabit(habit2);

    final today = DateTime.now();
    await provider.toggleHabitCompletion('h1', today);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: StatisticsScreen(),
        ),
      ),
    );

    // Day view has 50%
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Thiền định 10 phút'), findsOneWidget);
    expect(find.text('Uống đủ nước'), findsOneWidget);
    expect(find.text('✅ Đã hoàn thành'), findsOneWidget);
    expect(find.text('⏳ Chưa hoàn thành'), findsOneWidget);
  });
}
