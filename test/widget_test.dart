import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const TimerNeoApp());
    expect(find.text('START'), findsOneWidget);
  });
}
