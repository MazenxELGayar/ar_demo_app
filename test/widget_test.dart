import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ar_demo/main.dart';

void main() {
  testWidgets('Start screen shows Start AR button', (WidgetTester tester) async {
    await tester.pumpWidget(const ARDemo());

    expect(find.text('Start AR'), findsOneWidget);
    expect(find.text('AR Fox Demo'), findsOneWidget);
  });
}
