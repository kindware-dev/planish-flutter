import 'dart:io';
import 'dart:ui';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/report/drafts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? dir;
  late List<FeedbackReport> sent;

  Future<void> init(
    WidgetTester tester, {
    bool autoSend = false,
    PromptMode prompts = PromptMode.off,
    FeedbackSender? sender,
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    sent = <FeedbackReport>[];
    await Planish.init(
      PlanishConfig(
        sender: sender ?? CallbackFeedbackSender(sent.add),
        appName: 'Test',
        persistLogs: false,
        keepDrafts: false,
        prompts: prompts,
        autoSendErrors: autoSend,
        captureDebugPrint: false,
        attachments: (_) async => <FeedbackAttachment>[
          FeedbackAttachment.text('db.txt', 'app data'),
        ],
        errorHandling: const ErrorHandlingConfig(promptCooldown: Duration.zero),
        privacy: const PrivacyConfig(
          deviceInfo: DeviceInfoLevel.none,
          includeScreenshot: false,
        ),
      ),
    );
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('autosend');
      activeDraftStore = await DraftStore.open(directory: dir);
    });
  }

  tearDown(() async {
    await Planish.reset();
    await dir?.delete(recursive: true);
    dir = null;
  });

  // Draft files and sends are real async work, outside the fake clock.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> crash(WidgetTester tester, String what) async {
    PlatformDispatcher.instance.onError!(StateError(what), StackTrace.current);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
  }

  Widget app() => MaterialApp(
    builder: Planish.builder(),
    home: const Scaffold(body: Text('home')),
  );

  testWidgets('off by default: an error sends nothing', (
    WidgetTester tester,
  ) async {
    await init(tester);
    await tester.pumpWidget(app());
    await crash(tester, 'boom');
    expect(sent, isEmpty);
  });

  testWidgets('on: a minimal automatic report, once per error', (
    WidgetTester tester,
  ) async {
    await init(tester, autoSend: true);
    await tester.pumpWidget(app());
    await crash(tester, 'boom');
    await crash(tester, 'boom');
    await crash(tester, 'other');

    expect(sent, hasLength(2));
    final first = sent.first;
    expect(first.source, ReportSource.automatic);
    expect(first.message, isEmpty);
    expect(first.screenshot, isNull);
    expect(first.errorText, contains('boom'));
    expect(
      first.attachments.map((FeedbackAttachment a) => a.name),
      isNot(contains('db.txt')),
      reason: 'app attachments stay on the device',
    );
    expect(first.toJson()['source'], 'automatic');
  });

  testWidgets('on: at most 5 per launch', (WidgetTester tester) async {
    await init(tester, autoSend: true);
    await tester.pumpWidget(app());
    for (var i = 0; i < 7; i++) {
      await crash(tester, 'error $i');
    }
    expect(sent, hasLength(5));
  });

  testWidgets('on: ignored with the email sender', (WidgetTester tester) async {
    await init(
      tester,
      autoSend: true,
      sender: const EmailFeedbackSender(to: <String>['a@b.c']),
    );
    await tester.pumpWidget(app());
    await crash(tester, 'boom');
    expect(
      Log.entries.map((LogEntry e) => e.message),
      contains(contains('autoSendErrors is ignored with EmailFeedbackSender')),
    );
  });

  testWidgets('the draft of an auto-sent error points to that report', (
    WidgetTester tester,
  ) async {
    await init(tester, autoSend: true, prompts: PromptMode.quiet);
    await tester.pumpWidget(app());
    await crash(tester, 'boom');
    final draft = (await tester.runAsync(() => Planish.drafts.list()))!.single;
    expect(draft.relatedTo, sent.single.id);
    expect(Planish.drafts.pending.value, 0, reason: 'a caught error');
  });

  testWidgets('a waiting draft is recalled once a day', (
    WidgetTester tester,
  ) async {
    await init(tester, prompts: PromptMode.quiet);
    await tester.pumpWidget(app());
    await crash(tester, 'boom');
    expect(Planish.drafts.pending.value, 0);
    await tester.runAsync(Planish.remindDraftsNow);
    await tester.pump();
    expect(
      find.text('1 report not sent'),
      findsNothing,
      reason: 'a caught error alone is not recalled',
    );

    final now = DateTime.now();
    await tester.runAsync(
      () => activeDraftStore!.save(
        FeedbackDraft(
          id: 'mine',
          createdAt: now,
          updatedAt: now,
          frozen: const FrozenContext(),
          message: 'Total stays at 0',
        ),
      ),
    );
    expect(Planish.drafts.pending.value, 1);

    await tester.runAsync(Planish.remindDraftsNow);
    await tester.pump();
    expect(find.text('1 report not sent'), findsOneWidget);
    await tester.tap(find.text('View'));
    await settle(tester);
    expect(find.text('Discard draft'), findsOneWidget, reason: 'draft opened');

    await tester.tap(find.byTooltip('Cancel'));
    await settle(tester);
    await tester.runAsync(Planish.remindDraftsNow);
    await tester.pump();
    expect(find.text('1 report not sent'), findsNothing, reason: 'once a day');
  });
}
