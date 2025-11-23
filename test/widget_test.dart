// DeepcoRaceTimer 기본 위젯 테스트

import 'package:flutter_test/flutter_test.dart';

import 'package:deepco_race_timer/main.dart';

void main() {
  testWidgets('DeepcoRaceTimer app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DeepcoRaceTimerApp());

    // Verify that timer starts at 00:00:00
    expect(find.text('00:00:00'), findsOneWidget);

    // Verify that control buttons exist
    expect(find.text('START'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);
  });
}
