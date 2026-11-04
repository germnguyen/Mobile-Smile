import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discipline_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DisciplineApp integrated navigation and screen switching', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const DisciplineApp());
    await tester.pumpAndSettle();

    // Verify initial screen: Habit list
    expect(find.text('Kỷ Luật Bản Thân'), findsOneWidget);
    expect(find.text('Chưa có thói quen nào'), findsOneWidget);

    // Switch to Statistics tab
    await tester.tap(find.text('Thống kê'));
    await tester.pumpAndSettle();

    // Verify statistics screen
    expect(find.text('Thống Kê Kỷ Luật'), findsOneWidget);
    expect(find.text('Theo Ngày'), findsOneWidget);

    // Switch back to Habits tab
    await tester.tap(find.text('Thói quen'));
    await tester.pumpAndSettle();
    expect(find.text('Kỷ Luật Bản Thân'), findsOneWidget);

    // Tap Floating Action Button to open Add Habit screen
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Thêm Thói Quen Mới'), findsOneWidget);
    expect(find.text('Tên thói quen *'), findsOneWidget);
  });
}
