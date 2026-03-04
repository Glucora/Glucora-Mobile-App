import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App loads and shows role selection',
      (WidgetTester tester) async {

    // Build the app
    await tester.pumpWidget(GlucoraApp());

    // Verify role selection buttons exist
    expect(find.text('Patient Side'), findsOneWidget);
    expect(find.text('Doctor Side'), findsOneWidget);
  });
}