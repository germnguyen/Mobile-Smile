import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discipline_app/models/habit.dart';
import 'package:discipline_app/providers/habit_provider.dart';
import 'package:discipline_app/screens/habit_form_screen.dart';
import 'package:discipline_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HabitFormScreen creates new habit with validation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    final provider = HabitProvider(storageService: storage);
    await provider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: HabitFormScreen(),
        ),
      ),
    );

    // Initial state
    expect(find.text('Thêm Thói Quen Mới'), findsOneWidget);
    expect(find.text('Tạo Thói Quen'), findsOneWidget);

    // Try submitting without title -> trigger validation error
    await tester.tap(find.text('Tạo Thói Quen'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên thói quen'), findsOneWidget);

    // Enter title & description
    await tester.enterText(find.byType(TextFormField).first, 'Học Flutter mỗi ngày');
    await tester.enterText(find.byType(TextFormField).at(1), 'Luyện tập widget và state management');

    // Select frequency 'T2 - T6'
    await tester.tap(find.text('T2 - T6'));
    await tester.pumpAndSettle();

    // Submit form
    await tester.tap(find.text('Tạo Thói Quen'));
    await tester.pumpAndSettle();

    // Verify habit added to provider
    expect(provider.habits.length, 1);
    expect(provider.habits.first.title, 'Học Flutter mỗi ngày');
    expect(provider.habits.first.frequency, 'weekdays');
  });

  testWidgets('HabitFormScreen edits existing habit', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    final provider = HabitProvider(storageService: storage);
    await provider.init();

    final existing = Habit(
      id: 'h_edit',
      title: 'Dậy lúc 6h',
      description: 'Không ngủ nướng',
      frequency: 'daily',
      reminderTime: '06:00',
    );
    await provider.addHabit(existing);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: HabitFormScreen(habit: existing),
        ),
      ),
    );

    expect(find.text('Chỉnh Sửa Thói Quen'), findsOneWidget);
    expect(find.text('Dậy lúc 6h'), findsOneWidget);
    expect(find.text('Không ngủ nướng'), findsOneWidget);

    // Change title
    await tester.enterText(find.byType(TextFormField).first, 'Dậy lúc 5h30 sáng');
    await tester.tap(find.text('Lưu Thay Đổi'));
    await tester.pumpAndSettle();

    expect(provider.habits.first.title, 'Dậy lúc 5h30 sáng');
  });
}

