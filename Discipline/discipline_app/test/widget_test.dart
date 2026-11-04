import 'package:flutter_test/flutter_test.dart';
import 'package:discipline_app/main.dart';

void main() {
  testWidgets('DisciplineApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DisciplineApp());
    expect(find.text('Thói quen'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);
  });
}
