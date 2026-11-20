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

  Future<void> init(WidgetTester tester, PromptMode mode) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Planish.init(
      PlanishConfig(
        sender: CallbackFeedbackSender((_) async {}),
        appName: 'Test',
        persistLogs: false,
        keepDrafts: false,
        prompts: mode,
        captureDebugPrint: false,
        errorHandling: const ErrorHandlingConfig(promptCooldown: Duration.zero),
        privacy: const PrivacyConfig(
          deviceInfo: DeviceInfoLevel.none,
          includeScreenshot: false,
        ),
      ),
    );
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('prompts');
      activeDraftStore = await DraftStore.open(directory: dir);
    });
  }

  tearDown(() async {
    await Planish.reset();
    await dir?.delete(recursive: true);
    dir = null;
  });

  // Draft files are real I/O, outside the test's fake clock.
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

  Future<List<FeedbackDraft>> drafts(WidgetTester tester) async =>
      (await tester.runAsync(() => Planish.drafts.list()))!;

  test('prompts wins over the deprecated flag, which still maps', () {
    final sender = CallbackFeedbackSender((_) async {});
    const legacy = ErrorHandlingConfig(
      // ignore: deprecated_member_use_from_same_package
      promptFeedbackOnError: true,
    );
    expect(PlanishConfig(sender: sender).promptMode, PromptMode.off);
    expect(
      PlanishConfig(sender: sender, errorHandling: legacy).promptMode,
      PromptMode.notify,
    );
    expect(
      PlanishConfig(
        sender: sender,
        errorHandling: legacy,
        prompts: PromptMode.quiet,
      ).promptMode,
      PromptMode.quiet,
    );
  });

  testWidgets('notify: the error prepares a draft and the card opens it', (
    WidgetTester tester,
  ) async {
    await init(tester, PromptMode.notify);
    await tester.pumpWidget(app());
    await crash(tester, 'boom');

    final kept = await drafts(tester);
    expect(kept.single.source, DraftSource.automatic);
    expect(kept.single.touched, isFalse);
    expect(kept.single.frozen.error, contains('boom'));
    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Add details'));
    await settle(tester);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Discard draft'), findsOneWidget);
  });

  testWidgets('an error on an idle screen asks for a frame', (
    WidgetTester tester,
  ) async {
    await init(tester, PromptMode.notify);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);

    PlatformDispatcher.instance.onError!(
      StateError('idle'),
      StackTrace.current,
    );
    expect(tester.binding.hasScheduledFrame, isTrue);
    await settle(tester);
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('notify: two dismissals ask once, and quiet stops the cards', (
    WidgetTester tester,
  ) async {
    await init(tester, PromptMode.notify);
    await tester.pumpWidget(app());
    await crash(tester, 'one');
    await tester.tap(find.text('Later'));
    await tester.pump();
    await crash(tester, 'two');
    await tester.tap(find.text('Later'));
    await tester.pump();
    expect(find.text('Keep these quiet?'), findsOneWidget);
    await tester.tap(find.text('Keep quiet'));
    await tester.pump();

    await crash(tester, 'three');
    expect(find.text('Something went wrong'), findsNothing);
    expect(await drafts(tester), hasLength(3));
  });

  testWidgets('quiet: a draft, no card', (WidgetTester tester) async {
    await init(tester, PromptMode.quiet);
    await tester.pumpWidget(app());
    await crash(tester, 'boom');
    expect(find.text('Something went wrong'), findsNothing);
    expect((await drafts(tester)).single.source, DraftSource.automatic);
  });

  testWidgets('off: nothing automatic', (WidgetTester tester) async {
    await init(tester, PromptMode.off);
    await tester.pumpWidget(app());
    await crash(tester, 'boom');
    expect(find.text('Something went wrong'), findsNothing);
    expect(await drafts(tester), isEmpty);
  });
}
