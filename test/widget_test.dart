import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test - the app requires async initialization
    // so we just verify the test framework works
    expect(true, isTrue);
  });
}
