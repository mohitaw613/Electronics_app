import 'package:flutter_test/flutter_test.dart';
import 'package:electronics_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title widget is present.
    expect(find.text('BJT Common Emitter App'), findsOneWidget);
  });
}
