// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _appPrimary = Color(0xFF8E24AA);

Widget _app({Brightness brightness = Brightness.light}) => MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _appPrimary,
      brightness: brightness,
    ).copyWith(primary: _appPrimary),
  ),
  builder: Planish.builder(),
  home: const Scaffold(body: Center(child: Text('home'))),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  Future<void> init({
    Color? brandColor,
    bool useAppTheme = false,
    ThemeData Function(BuildContext)? theme,
  }) => Planish.init(
    PlanishConfig(
      sender: CallbackFeedbackSender((_) {}),
      appName: 'Test',
      persistLogs: false,
      captureDebugPrint: false,
      brandColor: brandColor,
      useAppTheme: useAppTheme,
      theme: theme,
      privacy: const PrivacyConfig(
        deviceInfo: DeviceInfoLevel.none,
        includeScreenshot: false,
      ),
      debugTools: const DebugToolsConfig(enabled: false),
    ),
  );

  Future<ThemeData> formTheme(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    Planish.show().ignore();
    await tester.pumpAndSettle();
    return Theme.of(tester.element(find.text('Send feedback')));
  }

  tearDown(Planish.reset);

  testWidgets('the form uses Planish colours in a light app', (
    WidgetTester tester,
  ) async {
    await init();
    final theme = await formTheme(tester, _app());
    expect(theme.colorScheme.primary, PlanishColors.light.brand);
    expect(theme.colorScheme.surface, PlanishColors.light.panel);
  });

  testWidgets('and in a dark one', (WidgetTester tester) async {
    await init();
    final theme = await formTheme(tester, _app(brightness: Brightness.dark));
    expect(theme.colorScheme.primary, PlanishColors.dark.brand);
    expect(theme.colorScheme.surface, PlanishColors.dark.panel);
  });

  testWidgets('pages opened from the form keep its colours', (
    WidgetTester tester,
  ) async {
    await init();
    await formTheme(tester, _app());
    await tester.tap(find.text('What will be sent?'));
    await tester.pumpAndSettle();
    final page = Theme.of(tester.element(find.byType(Scaffold).last));
    expect(page.colorScheme.primary, PlanishColors.light.brand);
  });

  testWidgets('useAppTheme keeps the app theme', (WidgetTester tester) async {
    await init(useAppTheme: true);
    final theme = await formTheme(tester, _app());
    expect(theme.colorScheme.primary, _appPrimary);
  });

  testWidgets('a theme builder wins over everything', (
    WidgetTester tester,
  ) async {
    await init(
      useAppTheme: true,
      brandColor: Colors.green,
      theme: (context) => ThemeData(colorScheme: const ColorScheme.dark()),
    );
    final theme = await formTheme(tester, _app());
    expect(theme.colorScheme.brightness, Brightness.dark);
  });

  testWidgets('brandColor fills buttons as given and keeps text readable', (
    WidgetTester tester,
  ) async {
    const yellow = Color(0xFFFFC90D);
    await init(brandColor: yellow);
    final theme = await formTheme(tester, _app());
    final fill = theme.filledButtonTheme.style!.backgroundColor!.resolve({});
    expect(fill, yellow);
    final ink = theme.colorScheme.primary;
    final contrast =
        (PlanishColors.light.panel.computeLuminance() + 0.05) /
        (ink.computeLuminance() + 0.05);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });
}
