// Basic smoke test for Swarnayan Jewellers app

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:swarnayan_flutter/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PayPulseApp()),
    );

    // Verify the app renders the home screen
    expect(find.text('PayPulse'), findsWidgets);
  });
}
