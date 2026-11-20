import 'dart:io';

// ignore: deprecated_member_use
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

  testWidgets('the sheet lists own drafts and folds caught errors by screen', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    FeedbackDraft error(String id) => FeedbackDraft(
      id: id,
      createdAt: now,
      updatedAt: now,
      source: DraftSource.automatic,
      touched: false,
      frozen: const FrozenContext(
        context: {'screen': '/settings'},
        error: 'Bad state: boom',
      ),
    );
    await tester.runAsync(() async {
      final store = activeDraftStore!;
      await store.save(error('e1'));
      await store.save(error('e2'));
      await store.save(
        FeedbackDraft(
          id: 'mine',
          createdAt: now,
          updatedAt: now,
          frozen: const FrozenContext(context: {'screen': '/cart'}),
          message: 'Total stays at 0',
          categoryId: 'bug',
        ),
      );
    });
    await tester.pumpWidget(app());
    await open(tester);
    await settleIo(tester);

    expect(find.text('Unsent draft'), findsOneWidget, reason: 'own draft only');
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drafts'));
    await settleIo(tester);
    expect(find.text('Total stays at 0'), findsOneWidget);
    expect(find.textContaining('/cart'), findsOneWidget);
    expect(find.text('2 errors caught'), findsOneWidget);
    expect(find.text('Error on /settings'), findsNothing, reason: 'folded');

    await tester.tap(find.text('2 errors caught'));
    await tester.pumpAndSettle();
    expect(find.text('Error on /settings'), findsOneWidget);
    expect(find.textContaining('\u00d72'), findsOneWidget);

    await tester.ensureVisible(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report'));
    await settleIo(tester);
    await settleIo(tester);
    expect(
      find.text('Report a problem'),
      findsOneWidget,
      reason: 'error opened',
    );
    expect(find.text('Discard draft', skipOffstage: false), findsOneWidget);
  });
}
