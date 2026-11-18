import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/report/drafts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Sender implements FeedbackSender {
  final List<FeedbackReport> sent = <FeedbackReport>[];

  @override
  Future<FeedbackSendResult> send(FeedbackReport report) async {
    sent.add(report);
    return const FeedbackSent();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  late Directory dir;
  late _Sender sender;

  setUp(() async {
    sender = _Sender();
    await Planish.init(
      PlanishConfig(
        sender: sender,
        appName: 'Test',
        persistLogs: false,
        keepDrafts: false,
        categories: FeedbackCategory.defaults,
        categoryRequired: false,
        captureDebugPrint: false,
        privacy: const PrivacyConfig(
          deviceInfo: DeviceInfoLevel.none,
          includeScreenshot: false,
        ),
      ),
    );
    dir = await Directory.systemTemp.createTemp('drafts_flow');
    activeDraftStore = await DraftStore.open(directory: dir);
  });

  tearDown(() async {
    await Planish.reset();
    await dir.delete(recursive: true);
  });

  // Draft files are real I/O, outside the test's fake clock.
  Future<void> settleIo(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    Planish.show().ignore();
    await tester.pumpAndSettle();
    await settleIo(tester);
  }

  Widget app() => MaterialApp(
    builder: Planish.builder(),
    home: const Scaffold(body: Text('home')),
  );

  testWidgets('a closed form is kept, offered on the next open and restored', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app());
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'Pay does nothing');
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await settleIo(tester);

    final kept = await tester.runAsync(() => Planish.drafts.list());
    expect(kept!.single.message, 'Pay does nothing');

    await open(tester);
    expect(find.text('Unsent draft'), findsOneWidget);
    expect(find.text('Drafts'), findsOneWidget);
    await tester.tap(find.text('Continue the draft'));
    await settleIo(tester);
    expect(find.text('Pay does nothing'), findsOneWidget);
    expect(find.text('Discard draft'), findsOneWidget);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    await settleIo(tester);
    expect(sender.sent.single.id, kept.single.id);
    expect(await tester.runAsync(() => Planish.drafts.list()), isEmpty);
  });

  testWidgets('an empty form leaves nothing; Discard deletes the draft', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app());
    await open(tester);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await settleIo(tester);
    expect(await tester.runAsync(() => Planish.drafts.list()), isEmpty);

    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'Keep me');
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await settleIo(tester);
    await open(tester);
    await tester.tap(find.text('Continue the draft'));
    await settleIo(tester);
    await tester.tap(find.text('Discard draft'));
    await tester.pumpAndSettle();
    await settleIo(tester);
    expect(await tester.runAsync(() => Planish.drafts.list()), isEmpty);
  });
}
