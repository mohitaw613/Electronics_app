import 'package:flutter_test/flutter_test.dart';
import 'package:electronics_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ElectronicsApp());

    // Verify that the home screen title is present.
    expect(find.text('Experiment 5: BJT Common Emitter'), findsOneWidget);
  });
}
