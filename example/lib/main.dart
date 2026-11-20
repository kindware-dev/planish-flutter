import 'dart:math' as math;

import 'package:planish/planish.dart';
import 'package:planish_example/plugins.dart';
import 'package:planish_example/senders.dart';
import 'package:planish_example/strings.dart';
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// `flutter run --release --dart-define=DEBUG_TOOLS=true` keeps the debug
/// tools in a release build, for testers.
const bool debugToolsFlag = bool.fromEnvironment('DEBUG_TOOLS');

final CrashReporterSink crashReporter = CrashReporterSink();

/// The example lets you switch senders at runtime; a real app picks one.
final ValueNotifier<SenderChoice> senderChoice = ValueNotifier<SenderChoice>(
  cloudKey.isEmpty ? SenderChoice.console : SenderChoice.cloud,
);
final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

Future<void> main() async {
  Log.addSink(crashReporter);
  await Planish.init(
    PlanishConfig(
      sender: SelectedSender(senderChoice),
      // Tag your crash reporter here (Crashlytics custom key, Sentry tag).
      onReportSent: (FeedbackReport r) =>
          Log.info('Report ${r.id} sent', tag: 'feedback'),
      categories: FeedbackCategory.defaults,
      askEmail: true,
      analysisNotes: (FeedbackReport r) =>
          'Tags: home = HomePage, profile = fake profile loader. '
          'Feature flags are listed as flag.* in the context.',
      // Shake opens the feedback form in every build, like Google or
      // Instagram apps. While the debug tools are enabled, the same shake
      // shows the debug button instead (its menu has "Send feedback").
      reportGestures: const <TriggerGesture>{TriggerGesture.shake},
      debugTools: DebugToolsConfig(
        enabled: kDebugMode || kProfileMode || debugToolsFlag,
        // Try `useAppTheme: true` to see the tools in the app's colors.
        useAppTheme: const bool.fromEnvironment('APP_THEME_TOOLS'),
        plugins: <DebugPlugin>[const FeatureFlagsPlugin(), clearCachePlugin()],
      ),
      // After an uncaught error: a draft is prepared and a card offers it.
      prompts: PromptMode.notify,
      // 30 s by default; short here so repeated clicks show the card again.
      errorHandling: const ErrorHandlingConfig(
        promptCooldown: Duration(seconds: 3),
      ),
      privacy: const PrivacyConfig(includeNetworkSummary: true),
      tutorial: const TutorialConfig(showOnFirstLaunch: true),
    ),
  );
  Planish.setUser(id: 'demo-42', email: 'demo@example.com');
  Planish.setTag('environment', 'local');
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Locale? _locale;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (_, ThemeMode mode, _) => MaterialApp(
        themeMode: mode,
        onGenerateTitle: (context) => ExampleStrings.of(context).appTitle,
        locale: _locale,
        supportedLocales: PlanishLocalizations.supportedLocales,
        localizationsDelegates: const [
          // ignore: deprecated_member_use
          ...GlobalMaterialLocalizations.delegates,
          PlanishLocalizations.delegate,
        ],
        theme: ThemeData(colorSchemeSeed: Colors.teal),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
        ),
        builder: Planish.builder(),
        navigatorObservers: [Planish.navigationObserver],
        home: HomePage(
          onLocaleChanged: (Locale l) => setState(() => _locale = l),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onLocaleChanged});

  static const _tilePadding = EdgeInsets.symmetric(horizontal: 12);

  final ValueChanged<Locale> onLocaleChanged;

  static void _okCall() =>
      LoggingHttpClient().get(Uri.parse('https://httpbin.org/get?x=1'));

  // A traced call that fails: the report lists it with its trace id.
  static void _failingCall() {
    final r = math.Random();
    String hex(int bytes) => List<String>.generate(
      bytes,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    LoggingHttpClient().get(
      Uri.parse('https://httpbin.org/status/500'),
      headers: <String, String>{'traceparent': '00-${hex(16)}-${hex(8)}-01'},
    );
  }

  static void _writeLogs() {
    Log.debug('Rendering home', tag: 'home');
    Log.info('Button tapped', tag: 'home');
    Log.warning('Token is Bearer abc.def.ghi and will be redacted');
    Log.error(
      'Could not load profile',
      error: const FormatException('bad json'),
      stackTrace: StackTrace.current,
      tag: 'profile',
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Planish.debugTools,
    builder: (BuildContext context, _) => _page(context),
  );

  Widget _page(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Built in (debug, profile, DEBUG_TOOLS) or allowed for this user.
    final debugOn = Planish.debugTools.isAvailable;
    final builtIn = Planish.config.debugTools.enabled;
    final locale = Localizations.localeOf(context).languageCode.toUpperCase();
    final s = ExampleStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          IconButton(
            tooltip: s.toggleDark,
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: () =>
                themeMode.value = theme.brightness == Brightness.dark
                ? ThemeMode.light
                : ThemeMode.dark,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<Locale>(
              tooltip: s.language,
              onSelected: onLocaleChanged,
              itemBuilder: (_) => [
                for (final Locale l in PlanishLocalizations.supportedLocales)
                  PopupMenuItem<Locale>(
                    value: l,
                    child: Text(l.languageCode.toUpperCase()),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, size: 18),
                    const SizedBox(width: 4),
                    Text(locale, style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        // Android 15 draws apps edge to edge: keep the end above the
        // navigation bar.
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _HeroCard(subtitle: debugOn ? s.heroDebugOn : s.heroDebugOff),
          _SectionLabel(s.sendVia),
          ValueListenableBuilder<SenderChoice>(
            valueListenable: senderChoice,
            builder: (_, SenderChoice choice, _) => _Segmented<SenderChoice>(
              values: SenderChoice.values,
              selected: choice,
              icon: (c) => switch (c) {
                SenderChoice.console => Icons.terminal,
                SenderChoice.email => Icons.mail_outline,
                SenderChoice.http => Icons.cloud_upload_outlined,
                SenderChoice.slack => Icons.forum_outlined,
                SenderChoice.cloud => Icons.inbox_outlined,
              },
              label: (c) => switch (c) {
                SenderChoice.console => 'Console',
                SenderChoice.email => s.email,
                SenderChoice.http => 'HTTP',
                SenderChoice.slack => 'Slack',
                SenderChoice.cloud => 'Cloud',
              },
              onChanged: (c) => senderChoice.value = c,
            ),
          ),
          if (!builtIn) ...[
            _SectionLabel(s.debugTools),
            _Card(
              children: [
                _Row(
                  child: SwitchListTile(
                    contentPadding: _tilePadding,
                    secondary: const _TileIcon(
                      Icons.admin_panel_settings_outlined,
                    ),
                    title: Text(s.allowTools),
                    subtitle: Text(s.allowToolsHint),
                    value: debugOn,
                    onChanged: (bool v) =>
                        Planish.debugTools.allow(v, remember: true),
                  ),
                ),
              ],
            ),
          ],
          if (debugOn) ...[
            if (builtIn) _SectionLabel(s.debugTools),
            _Card(
              children: [
                ListenableBuilder(
                  listenable: Planish.debugTools,
                  builder: (_, _) => _Row(
                    child: SwitchListTile(
                      contentPadding: _tilePadding,
                      secondary: const _TileIcon(Icons.bug_report_outlined),
                      title: Text(s.floatingButton),
                      subtitle: Text(
                        Planish.debugTools.isVisible
                            ? s.buttonVisible
                            : s.buttonHidden,
                      ),
                      value: Planish.debugTools.isVisible,
                      onChanged: (_) => Planish.debugTools.toggle(),
                    ),
                  ),
                ),
                _Row(
                  child: ListTile(
                    contentPadding: _tilePadding,
                    leading: const _TileIcon(Icons.terminal),
                    title: Text(s.openConsole),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: Planish.showConsole,
                  ),
                ),
                _Row(
                  child: ListTile(
                    contentPadding: _tilePadding,
                    leading: const _TileIcon(Icons.school_outlined),
                    title: Text(s.showTutorial),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: Planish.showTutorial,
                  ),
                ),
              ],
            ),
          ],
          _SectionLabel(s.activity),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              _ActionTile(
                icon: Icons.notes,
                title: s.writeLogs,
                subtitle: 'debug · info · warn · error',
                onTap: _writeLogs,
              ),
              _ActionTile(
                icon: Icons.language,
                title: s.httpCall,
                subtitle: 'GET httpbin.org/get',
                onTap: _okCall,
              ),
              _ActionTile(
                icon: Icons.cloud_off_outlined,
                title: s.httpFail,
                subtitle: 'GET httpbin.org/status/500',
                onTap: _failingCall,
              ),
              _ActionTile(
                icon: Icons.error_outline,
                title: s.flutterError,
                subtitle: s.flutterErrorHint,
                destructive: true,
                onTap: () =>
                    throw StateError('Button handler failed on purpose'),
              ),
              _ActionTile(
                icon: Icons.running_with_errors,
                title: s.asyncError,
                subtitle: s.asyncErrorHint,
                destructive: true,
                onTap: () =>
                    Future<void>.error(Exception('Unawaited future failed')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.errorsHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.footnote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.vibration, color: colors.onPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ExampleStrings.of(context).heroTitle,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.onPrimary,
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Planish.show(),
                  icon: const Icon(Icons.feedback_outlined, size: 16),
                  label: Text(
                    ExampleStrings.of(context).sendFeedback,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: colors.onPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  // Same as a real shake: the debug tools win when enabled.
                  onPressed: Planish.debugTools.isAvailable
                      ? Planish.debugTools.toggle
                      : Planish.prompt,
                  icon: const Icon(Icons.vibration, size: 16),
                  label: Text(
                    ExampleStrings.of(context).simulateShake,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final IconData Function(T) icon;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: v == selected
                      ? colors.surfaceContainerLowest
                      : Colors.transparent,
                  elevation: v == selected ? 1 : 0,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(v),
                    child: SizedBox(
                      height: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon(v),
                            size: 18,
                            color: v == selected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label(v),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: v == selected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 64),
    child: Center(child: child),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: colors.onSurfaceVariant),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fg = destructive ? colors.error : colors.onSurface;
    return Material(
      color: destructive
          ? colors.errorContainer.withValues(alpha: 0.35)
          : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: destructive
              ? colors.error.withValues(alpha: 0.3)
              : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: fg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(color: fg),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
