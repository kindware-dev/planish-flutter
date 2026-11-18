import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(Planish.reset);

  Future<void> firstStep(
    WidgetTester tester, {
    required bool debugTools,
    Set<TriggerGesture> reportGestures = const <TriggerGesture>{},
    bool quickSheet = true,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Planish.init(
      PlanishConfig(
        sender: CallbackFeedbackSender((_) async {}),
        appName: 'Test',
        persistLogs: false,
        captureDebugPrint: false,
        reportGestures: reportGestures,
        quickReport: QuickReportConfig(enabled: quickSheet),
        debugTools: DebugToolsConfig(enabled: debugTools),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: Planish.builder(),
        home: const Scaffold(body: Text('home')),
      ),
    );
    Planish.showTutorial().ignore();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('release with shake to report: the sheet, not a button', (
    WidgetTester tester,
  ) async {
    await firstStep(
      tester,
      debugTools: false,
      reportGestures: const <TriggerGesture>{TriggerGesture.shake},
    );
    expect(
      find.textContaining('A small sheet opens, “Share feedback”'),
      findsOneWidget,
    );
    expect(find.textContaining('bug button'), findsNothing);
  });

  testWidgets('shake to report without the sheet: the form opens', (
    WidgetTester tester,
  ) async {
    await firstStep(
      tester,
      debugTools: false,
      reportGestures: const <TriggerGesture>{TriggerGesture.shake},
      quickSheet: false,
    );
    expect(find.textContaining('The report form opens'), findsOneWidget);
  });

  testWidgets('debug tools on the shake: the bug button', (
    WidgetTester tester,
  ) async {
    await firstStep(
      tester,
      debugTools: true,
      reportGestures: const <TriggerGesture>{TriggerGesture.shake},
    );
    expect(find.textContaining('bug button'), findsOneWidget);
  });

  testWidgets('no shake at all: open it from the menu', (
    WidgetTester tester,
  ) async {
    await firstStep(tester, debugTools: false);
    expect(find.textContaining('from the menu'), findsOneWidget);
    expect(find.text('Shake your phone'), findsNothing);
  });
}
