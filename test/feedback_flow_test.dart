import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSender implements FeedbackSender {
  _FakeSender(this.result);

  FeedbackSendResult result;
  final List<FeedbackReport> sent = <FeedbackReport>[];

  @override
  Future<FeedbackSendResult> send(FeedbackReport report) async {
    sent.add(report);
    return result;
  }
}

Widget _app({TransitionBuilder? builder}) => MaterialApp(
  builder: builder ?? Planish.builder(),
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
  SharedPreferences.setMockInitialValues(<String, Object>{});

  late _FakeSender sender;

  Future<void> init({
    bool categoryRequired = true,
    FeedbackReport? Function(FeedbackReport)? beforeSend,
    void Function(FeedbackReport)? onReportSent,
  }) async {
    sender = _FakeSender(const FeedbackSent());
    await Planish.init(
      PlanishConfig(
        sender: sender,
        appName: 'Test',
        persistLogs: false,
        onReportSent: onReportSent,
        categories: FeedbackCategory.defaults,
        categoryRequired: categoryRequired,
        captureDebugPrint: false,
        privacy: PrivacyConfig(
          deviceInfo: DeviceInfoLevel.none,
          includeScreenshot: false,
          beforeSend: beforeSend,
        ),
        debugTools: const DebugToolsConfig(
          enabled: true,
          gestures: <TriggerGesture>{},
        ),
      ),
    );
  }

  tearDown(Planish.reset);

  testWidgets('the README config works under flutter test as is', (
    WidgetTester tester,
  ) async {
    await Planish.reset();
    await Planish.init(
      PlanishConfig(sender: CallbackFeedbackSender((_) async {})),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: Planish.builder(),
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: Planish.show,
              child: const Text('report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('report'));
    await tester.pumpAndSettle();
    expect(find.text('Send feedback'), findsOneWidget);
    expect(find.text('Screenshot'), findsNothing, reason: 'none in tests');
    expect(tester.takeException(), isNull);
    await Planish.reset();
  });

  group('default config', () {
    setUp(init);

    testWidgets('show() opens the form and a successful send closes it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app());
      Log.info('something happened');

      final outcome = Planish.show();
      await tester.pumpAndSettle();

      expect(find.text('Send feedback'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byWidgetPredicate((Widget w) => w is FilledButton),
            )
            .onPressed,
        isNull,
        reason: 'category is required',
      );

      await tester.tap(find.text('Bug'));
      await tester.enterText(find.byType(TextField), 'It crashed');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(await outcome, isA<FeedbackSent>());
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Thanks, your feedback was sent.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Thanks, your feedback was sent.'), findsNothing);
      final report = sender.sent.single;
      expect(report.message, 'It crashed');
      expect(report.category, FeedbackCategory.bug);
      expect(report.appName, 'Test');
      expect(
        report.logs.map((LogEntry e) => e.message),
        contains('something happened'),
      );
    });

    testWidgets('a failed send shows the reason and keeps the form open', (
      WidgetTester tester,
    ) async {
      sender.result = const FeedbackFailed('server is down');
      await tester.pumpWidget(_app());
      final outcome = Planish.show();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Idea'));
      await tester.enterText(find.byType(TextField), 'keep me');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Could not send: server is down'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('keep me'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(await outcome, isNull);
    });

    testWidgets('Android back closes the form instead of the app route', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app());
      final outcome = Planish.show();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('home'), findsOneWidget);
      expect(await outcome, isNull);
    });

    testWidgets('the placeholder follows the category', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app());
      final outcome = Planish.show();
      await tester.pumpAndSettle();

      String hint() => tester
          .widget<TextField>(find.byType(TextField).first)
          .decoration!
          .hintText!;
      expect(hint(), 'What happened? What did you expect instead?');
      await tester.tap(find.text('Question'));
      await tester.pump();
      expect(hint(), 'What are you trying to do?');
      await tester.tap(find.text('Idea'));
      await tester.pump();
      expect(hint(), startsWith('What would you like to see'));

      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(await outcome, isNull);
    });

    testWidgets('review page shows what the user typed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app());
      final outcome = Planish.show();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Idea'));
      await tester.enterText(find.byType(TextField), 'the sound stops');
      await tester.pumpAndSettle();
      await tester.tap(find.text('What will be sent?'));
      await tester.pumpAndSettle();

      expect(find.text('What will be sent'), findsOneWidget);
      expect(find.text('the sound stops'), findsOneWidget);
      expect(find.text('Idea'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(await outcome, isNull);
    });

    testWidgets('debug menu uses the Planish palette for sheet and rows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app());
      Planish.debugTools.show();
      await tester.pumpAndSettle();
      await tester.tap(debugButton);
      await tester.pumpAndSettle();

      final sheet = tester
          .widgetList<Material>(find.byType(Material))
          .firstWhere((Material m) => m.color == PlanishColors.light.panel);
      expect(sheet, isNotNull);
      final row = find.ancestor(
        of: find.text('Network'),
        matching: find.byType(ListTile),
      );
      final rowTheme = Theme.of(tester.element(row));
      expect(rowTheme.listTileTheme.textColor, PlanishColors.light.text);
      expect(
        rowTheme.extension<DebugPalette>()?.surface,
        PlanishColors.light.panel,
      );
    });

    testWidgets('debug button opens the menu with built-in tools', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app());
      Planish.debugTools.show();
      await tester.pumpAndSettle();

      await tester.tap(debugButton);
      await tester.pumpAndSettle();
      expect(find.text('Console'), findsOneWidget);
      expect(find.text('Network'), findsOneWidget);

      await tester.tap(find.text('Console'));
      await tester.pumpAndSettle();
      expect(find.text('No logs yet.'), findsOneWidget);
      expect(find.text('Network'), findsNothing, reason: 'menu closed');
      expect(find.text('home'), findsOneWidget, reason: 'app still usable');

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('No logs yet.'), findsNothing);
    });

    testWidgets(
      'package strings follow the app locale without any delegate setup',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const <Locale>[Locale('fr')],
            // ignore: deprecated_member_use
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: Planish.builder(),
            home: const Scaffold(body: Text('home')),
          ),
        );
        await tester.pumpAndSettle();
        unawaited(Planish.show());
        await tester.pumpAndSettle();
        expect(find.text('Envoyer un retour'), findsOneWidget);
        expect(find.text('Idée'), findsOneWidget);
      },
    );

    testWidgets('an inner builder is kept', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          builder: Planish.builder(
            inner: (BuildContext _, Widget? child) =>
                KeyedSubtree(key: const Key('inner'), child: child!),
          ),
        ),
      );
      expect(find.byKey(const Key('inner')), findsOneWidget);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('user, tags and email', () {
    setUp(() async {
      await init(categoryRequired: false);
      await Planish.reset();
      sender = _FakeSender(const FeedbackSent());
      await Planish.init(
        PlanishConfig(
          sender: sender,
          appName: 'Test',
          persistLogs: false,
          askEmail: true,
          captureDebugPrint: false,
          privacy: const PrivacyConfig(
            deviceInfo: DeviceInfoLevel.none,
            includeScreenshot: false,
          ),
          debugTools: const DebugToolsConfig(enabled: false),
        ),
      );
    });

    testWidgets('are part of the report', (WidgetTester tester) async {
      Planish.setUser(id: '42', email: 'me@example.com');
      Planish.setTag('tenant', 'acme');
      await tester.pumpWidget(_app());
      Planish.show().ignore();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'hello');

      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'reply@example.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      final report = sender.sent.single;
      expect(report.email, 'reply@example.com');
      expect(report.context['user.id'], '42');
      expect(report.context['user.email'], 'me@example.com');
      expect(report.context['tag.tenant'], 'acme');
      expect(report.toPlainText(), contains('From: reply@example.com'));

      Planish.clearUser();
      Planish.removeTag('tenant');
      final again = await Planish.buildReport(message: '');
      expect(again.context.containsKey('user.id'), isFalse);
      expect(again.context.containsKey('tag.tenant'), isFalse);
    });
  });

  group('beforeSend', () {
    setUp(() => init(categoryRequired: false, beforeSend: (_) => null));

    testWidgets('returning null cancels without calling the sender', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app());
      Planish.show().ignore();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'hello');
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(sender.sent, isEmpty);
      expect(find.textContaining('Nothing was sent'), findsOneWidget);
    });
  });
  group('onReportSent', () {
    final notified = <FeedbackReport>[];
    setUp(() {
      notified.clear();
      return init(categoryRequired: false, onReportSent: notified.add);
    });

    testWidgets('receives the sent report', (WidgetTester tester) async {
      await tester.pumpWidget(_app());
      Planish.show().ignore();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'hello');
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(notified.single.id, sender.sent.single.id);
    });

    testWidgets('is not called when sending fails', (
      WidgetTester tester,
    ) async {
      sender.result = const FeedbackFailed('offline');
      await tester.pumpWidget(_app());
      Planish.show().ignore();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'hello');
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(sender.sent, hasLength(1));
      expect(notified, isEmpty);
    });
  });
}
