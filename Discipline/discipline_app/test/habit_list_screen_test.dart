import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discipline_app/models/habit.dart';
import 'package:discipline_app/providers/habit_provider.dart';
import 'package:discipline_app/screens/habit_list_screen.dart';
import 'package:discipline_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HabitListScreen empty state and habit item display', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    final provider = HabitProvider(storageService: storage);
    await provider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: HabitListScreen(
            onAddHabit: () {},
            onEditHabit: (_) {},
          ),
        ),
      ),
    );

    // Initial empty state
    expect(find.text('Chưa có thói quen nào'), findsOneWidget);
    expect(find.text('Kỷ Luật Bản Thân'), findsOneWidget);

    // Add a habit
    await provider.addHabit(
      Habit(
        id: 'h1',
        title: 'Đọc sách 30 phút',
        description: 'Đọc sách trước khi ngủ',
        frequency: 'daily',
        reminderTime: '21:30',
      ),
    );
    await tester.pumpAndSettle();

    // Verify habit card is visible
    expect(find.text('Đọc sách 30 phút'), findsOneWidget);
    expect(find.text('Đọc sách trước khi ngủ'), findsOneWidget);
    expect(find.text('21:30'), findsOneWidget);
    expect(find.text('Mỗi ngày'), findsOneWidget);

    // Tap check-in
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify completion
    expect(provider.isHabitCompletedOn('h1', provider.selectedDate), isTrue);
  });
}

