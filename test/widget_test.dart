import 'package:clock_in_clock_out/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ClockInClockOut());

    // Basic check for app title or expected initial UI element
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
