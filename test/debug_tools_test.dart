// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/ui/tutorial/tutorial_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _noop(FeedbackReport _) async {}

/// The tutorial's phone illustration animates forever, so pumpAndSettle
/// would never return.
Future<void> pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _app() => MaterialApp(
  builder: Planish.builder(),
  home: const Scaffold(body: Center(child: Text('home'))),
);

/// The tappable part of the floating debug button. Tapping its `Semantics`
/// node does not reach the `InkWell` on Flutter 3.32.
final Finder debugButton = find.descendant(
  of: find.bySemanticsLabel('Open debug tools'),
  matching: find.byType(InkWell),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Planish.reset();
  });
  tearDown(Planish.reset);
  quickReportTests();

  testWidgets('floating console shows logs, expands to a page and closes', (
    WidgetTester tester,
  ) async {
    await Planish.init(
      const PlanishConfig(
        sender: CallbackFeedbackSender(_noop),
        captureDebugPrint: false,
        debugTools: DebugToolsConfig(
          enabled: true,
          gestures: <TriggerGesture>{},
        ),
      ),
    );
    await tester.pumpWidget(_app());
    Log.info('first line');

    Planish.showConsole();
    await tester.pumpAndSettle();
    expect(find.textContaining('first line'), findsOneWidget);
    expect(find.text('home'), findsOneWidget, reason: 'app stays visible');

    Log.warning('arrived later');
    await tester.pumpAndSettle();
    expect(find.textContaining('arrived later'), findsOneWidget);

    await tester.tap(find.byTooltip('Open full screen'));
    await tester.pumpAndSettle();
    expect(
      find.text('TRACE'),
      findsOneWidget,
      reason: 'level chips on the page',
    );

    await tester.tap(find.byTooltip('Floating window'));
    await tester.pumpAndSettle();
    expect(find.text('TRACE'), findsNothing, reason: 'page closed');
    expect(
      find.textContaining('first line'),
      findsOneWidget,
      reason: 'floating again',
    );
  });

  testWidgets('debug menu closes on swipe down and lists custom plugins', (
    WidgetTester tester,
  ) async {
    await Planish.init(
      PlanishConfig(
        sender: const CallbackFeedbackSender(_noop),
        captureDebugPrint: false,
        debugTools: DebugToolsConfig(
          enabled: true,
          gestures: const <TriggerGesture>{},
          plugins: <DebugPlugin>[
            DebugActionPlugin(
              title: 'Custom action',
              icon: Icons.star,
              onTap: (_) async {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(_app());
    Planish.debugTools.show();
    await tester.pumpAndSettle();
    await tester.tap(debugButton);
    await tester.pumpAndSettle();

    expect(find.text('Custom action'), findsOneWidget);
    expect(find.text('How to report a problem'), findsOneWidget);

    await tester.tap(find.text('How to report a problem'));
    await pump(tester);
    expect(find.text('Custom action'), findsNothing, reason: 'menu closed');
    expect(find.text('Skip'), findsOneWidget, reason: 'tutorial opened');
    await tester.tap(find.text('Skip'));
    await pump(tester);

    await tester.tap(debugButton);
    await tester.pumpAndSettle();

    await tester.drag(find.text('Debug tools'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Custom action'), findsNothing);
  });

  testWidgets(
    'skipping the tutorial counts as seen; back cannot bypass canSkip',
    (WidgetTester tester) async {
      await Planish.init(
        const PlanishConfig(
          sender: CallbackFeedbackSender(_noop),
          captureDebugPrint: false,
          debugTools: DebugToolsConfig(enabled: false),
          tutorial: TutorialConfig(showOnFirstLaunch: true, canSkip: false),
        ),
      );
      await tester.pumpWidget(_app());
      await pump(tester);
      expect(find.text('How to report a problem'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await tester.binding.handlePopRoute();
      await pump(tester);
      expect(
        find.text('How to report a problem'),
        findsOneWidget,
        reason: 'back is ignored',
      );

      // A fresh host, so the first-launch check runs again.
      await tester.pumpWidget(const SizedBox());
      await Planish.reset();
      await Planish.init(
        const PlanishConfig(
          sender: CallbackFeedbackSender(_noop),
          captureDebugPrint: false,
          debugTools: DebugToolsConfig(enabled: false),
          tutorial: TutorialConfig(showOnFirstLaunch: true),
        ),
      );
      await tester.pumpWidget(_app());
      await pump(tester);
      await tester.tap(find.text('Skip'));
      await pump(tester);
      expect(find.text('How to report a problem'), findsNothing);
      expect(await TutorialState.isDone(), isTrue);
    },
  );

  testWidgets('debug button stays on screen when the window shrinks', (
    WidgetTester tester,
  ) async {
    await Planish.init(
      const PlanishConfig(
        sender: CallbackFeedbackSender(_noop),
        captureDebugPrint: false,
        persistLogs: false,
        debugTools: DebugToolsConfig(enabled: true),
      ),
    );
    await tester.pumpWidget(_app());
    Planish.debugTools.show();
    await tester.pumpAndSettle();

    final button = find.bySemanticsLabel('Open debug tools');
    await tester.drag(button, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(600));

    tester.view.physicalSize = const Size(900, 600); // 300x200 logical
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpAndSettle();

    final rect = tester.getRect(button);
    expect(rect.right, lessThanOrEqualTo(300));
    expect(rect.bottom, lessThanOrEqualTo(200));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
  });

  testWidgets('tutorial shows once on first launch and can be finished', (
    WidgetTester tester,
  ) async {
    await Planish.init(
      const PlanishConfig(
        sender: CallbackFeedbackSender(_noop),
        captureDebugPrint: false,
        debugTools: DebugToolsConfig(enabled: false),
        tutorial: TutorialConfig(showOnFirstLaunch: true),
      ),
    );
    await tester.pumpWidget(_app());
    await pump(tester);
    expect(find.text('How to report a problem'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await pump(tester);
    }
    await tester.tap(find.text('Done'));
    await pump(tester);
    expect(find.text('How to report a problem'), findsNothing);

    // A fresh host, so the first-launch check runs again.
    await tester.pumpWidget(const SizedBox());
    await Planish.reset();
    await Planish.init(
      const PlanishConfig(
        sender: CallbackFeedbackSender(_noop),
        captureDebugPrint: false,
        debugTools: DebugToolsConfig(enabled: false),
        tutorial: TutorialConfig(showOnFirstLaunch: true),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app());
    await pump(tester);
    expect(find.text('How to report a problem'), findsNothing);
  });

  testWidgets('report gesture opens the form when debug tools are off', (
    WidgetTester tester,
  ) async {
    await Planish.init(
      const PlanishConfig(
        sender: CallbackFeedbackSender(_noop),
        captureDebugPrint: false,
        reportGestures: <TriggerGesture>{TriggerGesture.multiFingerTap},
        gestures: GestureConfig(
          multiFingerTap: MultiFingerTapGestureConfig(fingers: 2, taps: 1),
        ),
        privacy: PrivacyConfig(
          includeScreenshot: false,
          deviceInfo: DeviceInfoLevel.none,
        ),
        debugTools: DebugToolsConfig(enabled: false),
      ),
    );
    await tester.pumpWidget(_app());

    final center = tester.getCenter(find.text('home'));
    final a = await tester.startGesture(center);
    final b = await tester.startGesture(center + const Offset(40, 0));
    await a.up();
    await b.up();
    await tester.pumpAndSettle();

    expect(find.text('Share feedback'), findsOneWidget);
  });

  testWidgets(
    'allow() gives a release build the debug tools, and takes them back',
    (WidgetTester tester) async {
      await Planish.init(
        const PlanishConfig(
          sender: CallbackFeedbackSender(_noop),
          captureDebugPrint: false,
          persistLogs: false,
          reportGestures: <TriggerGesture>{TriggerGesture.multiFingerTap},
          gestures: GestureConfig(
            multiFingerTap: MultiFingerTapGestureConfig(fingers: 2, taps: 1),
          ),
          privacy: PrivacyConfig(
            includeScreenshot: false,
            deviceInfo: DeviceInfoLevel.none,
          ),
          debugTools: DebugToolsConfig(
            enabled: false,
            gestures: <TriggerGesture>{TriggerGesture.multiFingerTap},
          ),
        ),
      );
      await tester.pumpWidget(_app());
      var pointer = 10;
      Future<void> twoFingerTap() async {
        final center = tester.getCenter(find.text('home'));
        final a = await tester.startGesture(center, pointer: pointer++);
        final b = await tester.startGesture(
          center + const Offset(40, 0),
          pointer: pointer++,
        );
        await a.up();
        await b.up();
        await tester.pumpAndSettle();
      }

      expect(Planish.debugTools.isAvailable, isFalse);
      await tester.runAsync(() => Planish.debugTools.allow(true));
      await tester.pumpAndSettle();
      expect(Planish.debugTools.isAvailable, isTrue);

      await twoFingerTap();
      expect(debugButton, findsOneWidget, reason: 'the gesture now shows it');
      expect(find.text('Share feedback'), findsNothing);

      await tester.runAsync(() => Planish.debugTools.allow(false));
      await tester.pumpAndSettle();
      expect(debugButton, findsNothing, reason: 'revoked');
      await twoFingerTap();
      expect(
        find.text('Share feedback'),
        findsOneWidget,
        reason: 'back to the sheet',
      );
    },
  );

  test(
    'allow(remember: true) survives a restart; allow(false) forgets it',
    () async {
      const config = PlanishConfig(
        sender: CallbackFeedbackSender(_noop),
        captureDebugPrint: false,
        persistLogs: false,
        debugTools: DebugToolsConfig(enabled: false),
      );
      await Planish.init(config);
      await Planish.debugTools.allow(true, remember: true);

      await Planish.reset();
      await Planish.init(config);
      await Planish.debugTools.load(enabled: false, remember: true);
      expect(Planish.debugTools.isAvailable, isTrue);

      await Planish.debugTools.allow(false);
      await Planish.reset();
      await Planish.init(config);
      await Planish.debugTools.load(enabled: false, remember: true);
      expect(Planish.debugTools.isAvailable, isFalse);

      await Planish.debugTools.allow(true);
      await Planish.reset();
      await Planish.init(config);
      await Planish.debugTools.load(enabled: false, remember: true);
      expect(Planish.debugTools.isAvailable, isFalse, reason: 'session only');
    },
  );
}

void quickReportTests() {
  testWidgets('report gesture opens the quick sheet, then the form', (
    WidgetTester tester,
  ) async {
    final sent = <FeedbackReport>[];
    await Planish.init(
      PlanishConfig(
        sender: CallbackFeedbackSender(sent.add),
        appName: 'Test',
        persistLogs: false,
        captureDebugPrint: false,
        categories: FeedbackCategory.defaults,
        reportGestures: const {TriggerGesture.multiFingerTap},
        gestures: const GestureConfig(
          multiFingerTap: MultiFingerTapGestureConfig(fingers: 2, taps: 1),
        ),
        privacy: const PrivacyConfig(
          includeScreenshot: false,
          deviceInfo: DeviceInfoLevel.none,
        ),
        debugTools: const DebugToolsConfig(enabled: false),
      ),
    );
    await tester.pumpWidget(_app());

    final center = tester.getCenter(find.text('home'));
    final a = await tester.startGesture(center);
    final b = await tester.startGesture(center + const Offset(40, 0));
    await a.up();
    await b.up();
    await tester.pumpAndSettle();

    expect(find.text('Share feedback'), findsOneWidget);
    expect(find.byType(TextField), findsNothing, reason: 'form not open yet');

    await tester.drag(find.text('Share feedback'), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.text('Share feedback'), findsNothing, reason: 'swiped away');

    final c = await tester.startGesture(center);
    final d = await tester.startGesture(center + const Offset(40, 0));
    await c.up();
    await d.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    expect(find.text('Share feedback'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'broken');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(sent.single.category, FeedbackCategory.bug);
  });

  testWidgets('custom actions and builder are honoured', (
    WidgetTester tester,
  ) async {
    var custom = 0;
    await Planish.init(
      PlanishConfig(
        sender: const CallbackFeedbackSender(_noop),
        appName: 'Test',
        persistLogs: false,
        captureDebugPrint: false,
        quickReport: QuickReportConfig(
          title: (_) => 'Oops',
          actions: (_) => [
            QuickReportAction(
              icon: Icons.star,
              label: 'Call support',
              onTap: (_) async => custom++,
            ),
          ],
        ),
        privacy: const PrivacyConfig(
          includeScreenshot: false,
          deviceInfo: DeviceInfoLevel.none,
        ),
        debugTools: const DebugToolsConfig(enabled: false),
      ),
    );
    await tester.pumpWidget(_app());
    Planish.prompt().ignore();
    await tester.pumpAndSettle();

    expect(find.text('Oops'), findsOneWidget);
    await tester.tap(find.text('Call support'));
    await tester.pumpAndSettle();
    expect(custom, 1);
    expect(find.byType(TextField), findsNothing);
  });
}
