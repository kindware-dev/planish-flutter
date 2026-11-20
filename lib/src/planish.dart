import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/config.dart';
import 'package:planish/src/debug/debug_plugin.dart';
import 'package:planish/src/debug/debug_tools_controller.dart';
import 'package:planish/src/env.dart';
import 'package:planish/src/errors/error_handlers.dart';
import 'package:planish/src/host/host.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/log/log.dart';
import 'package:planish/src/log/navigation_observer.dart';
import 'package:planish/src/log/persisted_logs.dart';
import 'package:planish/src/network/network_log.dart';
import 'package:planish/src/network/trace_ids.dart';
import 'package:planish/src/report/device_context.dart';
import 'package:planish/src/report/drafts.dart';
import 'package:planish/src/report/feedback_report.dart';
import 'package:planish/src/report/senders/email_feedback_sender.dart';
import 'package:planish/src/ui/debug/built_in_plugins.dart';
import 'package:planish/src/ui/feedback/error_card.dart';
import 'package:planish/src/ui/feedback/feedback_page.dart';
import 'package:planish/src/ui/feedback/quick_report_sheet.dart';
import 'package:planish/src/ui/planish_theme.dart';
import 'package:planish/src/ui/tutorial/tutorial_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry point of the package.
///
/// ```dart
/// void main() async {
///   await Planish.init(PlanishConfig(
///     sender: EmailFeedbackSender(to: ['support@example.com']),
///   ));
///   runApp(const MyApp());
/// }
///
/// MaterialApp(builder: Planish.builder(), home: ...);
/// ```
abstract final class Planish {
  static PlanishConfig? _config;
  static final _BindingObserver _backObserver = _BindingObserver();
  static bool _showing = false;
  static DateTime? _startedAt;

  /// Identifies this launch of the app in reports (`session.id`).
  static String sessionId = _newSessionId();

  /// Controls the floating debug button.
  static final DebugToolsController debugTools = DebugToolsController();

  /// Reports kept on this device until they are sent. Empty when
  /// `keepDrafts` is off or files are unavailable.
  static final PlanishDrafts drafts = PlanishDrafts._();

  /// Add to `navigatorObservers` (or a router's `observers`) to log screen
  /// changes and include the current screen in reports.
  static final LoggingNavigatorObserver navigationObserver =
      LoggingNavigatorObserver();

  static final Map<String, String> _tags = <String, String>{};

  /// Identifies the current user in reports (`user.id`, `user.email`,
  /// `user.name`). Call [clearUser] on logout.
  static void setUser({required String id, String? email, String? name}) {
    clearUser();
    _tags['user.id'] = id;
    if (email != null) {
      _tags['user.email'] = email;
    }
    if (name != null) {
      _tags['user.name'] = name;
    }
  }

  /// Removes the user identity from future reports.
  static void clearUser() =>
      _tags.removeWhere((String k, _) => k.startsWith('user.'));

  /// Adds a key/value pair to every report (`tag.<key>`): tenant, A/B
  /// variant, backend environment...
  static void setTag(String key, String value) => _tags['tag.$key'] = value;

  /// Removes a tag set with [setTag].
  static void removeTag(String key) => _tags.remove('tag.$key');

  /// Whether [init] has run.
  static bool get isInitialized => _config != null;

  /// Active configuration. Throws before [init].
  static PlanishConfig get config {
    final c = _config;
    if (c == null) {
      throw StateError('Call Planish.init() before using Planish.');
    }
    return c;
  }

  /// Built-in debug plugins followed by `config.debugTools.plugins`.
  static List<DebugPlugin> get debugPlugins => <DebugPlugin>[
    ...builtInDebugPlugins,
    ...config.debugTools.plugins,
  ];

  /// Configures the package. Call once, before `runApp`. Returns quickly:
  /// nothing here waits on the platform.
  ///
  /// Installs the error handlers (chaining any existing ones), applies the
  /// privacy settings to the log and network buffers and restores the debug
  /// button state.
  static Future<void> init(PlanishConfig config) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (_config != null) {
      Log.warning('Planish.init() called twice; ignoring', tag: 'feedback');
      return;
    }
    _config = config;
    _startedAt = DateTime.now();

    Log.redactors.addAll(config.privacy.redactors);
    // Replacing debugPrint trips flutter_test's debug-variable check.
    Log.captureDebugPrint(enabled: config.captureDebugPrint && !isFlutterTest);
    NetworkLog.sensitiveHeaders = config.privacy.sensitiveHeaders;
    NetworkLog.sensitiveQueryParameters =
        config.privacy.sensitiveQueryParameters;
    NetworkLog.traceHeaders = config.privacy.traceHeaders;

    ErrorHandlers.install(
      config.errorHandling,
      onPrompt: _promptAfterError,
      onUncaught: config.autoSendErrors ? _autoSend : null,
      prompting: () => _promptMode != PromptMode.off,
    );
    if (config.promptMode == PromptMode.notify) {
      SharedPreferences.getInstance().then((SharedPreferences p) {
        _quietChosen = p.getBool(_quietKey) ?? false;
        _askedQuiet = p.getBool(_askedKey) ?? false;
      }).ignore();
    }
    // Registered before WidgetsApp's own observer so our modals get the
    // Android back button first.
    WidgetsBinding.instance.addObserver(_backObserver);

    // Not awaited: a slow or missing plugin must not delay runApp().
    debugTools
        .load(
          enabled: config.debugTools.enabled,
          remember: config.debugTools.rememberState,
        )
        .ignore();
    if (config.persistLogs) {
      PersistedLogs.open().ignore();
    }
    if (config.draftsEnabled) {
      DraftStore.open().then((DraftStore? s) {
        activeDraftStore = s;
        if (s != null && config.remindDrafts) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => Future<void>.delayed(
              const Duration(milliseconds: 1500),
              _remindDrafts,
            ),
          );
        }
      }).ignore();
    }
  }

  /// How the previous launch ended. Known once `persistLogs` has loaded.
  static PreviousExit get previousExit => PersistedLogs.previousExit;

  /// Returns a `builder` for `MaterialApp`, `CupertinoApp` or `WidgetsApp`.
  /// Pass your own builder as [inner] if you already have one.
  static TransitionBuilder builder({TransitionBuilder? inner}) =>
      (BuildContext context, Widget? child) {
        final app = inner == null
            ? (child ?? const SizedBox())
            : inner(context, child);
        assert(
          isInitialized,
          'Planish.builder() needs Planish.init() to have run '
          'before runApp().',
        );
        if (!isInitialized) {
          return app;
        }
        return PlanishHost(config: config, debugTools: debugTools, child: app);
      };

  /// Opens the feedback form. Resolves with the outcome, or null when the user
  /// closed the form without sending. Does nothing while a form is open.
  ///
  /// Pass [error] and [stackTrace] to report a caught exception.
  static Future<FeedbackSendResult?> show({
    Object? error,
    StackTrace? stackTrace,
    FeedbackCategory? category,
  }) => _open(error: error, stackTrace: stackTrace, category: category);

  static Future<FeedbackSendResult?> _open({
    Object? error,
    StackTrace? stackTrace,
    FeedbackCategory? category,
    FeedbackDraft? draft,
  }) async {
    final host = PlanishHostState.current;
    assert(
      host != null,
      'Planish.show() needs Planish.builder() on your MaterialApp '
      '(builder: Planish.builder()).',
    );
    if (host == null) {
      Log.warning(
        'Planish.show() called but Planish.builder() is not in the widget tree',
        tag: 'feedback',
      );
      return null;
    }
    if (_showing) {
      return null;
    }
    _showing = true;
    try {
      final screenshot = draft != null || !config.privacy.includeScreenshot
          ? null
          : await host.captureScreenshot();
      // Not awaited, so the form opens at once. Under flutter test the
      // plugins never answer: the context is then taken on send.
      final frozen = isFlutterTest || draft != null
          ? null
          : freezeContext(error: error, stackTrace: stackTrace);
      final result = await host.showModal<FeedbackSendResult>(
        (_) => _themed(
          FeedbackPage(
            screenshot: screenshot,
            frozen: frozen,
            error: error,
            stackTrace: stackTrace,
            initialCategory: category,
            draft: draft,
          ),
        ),
      );
      if (host.mounted) {
        if (result is FeedbackSent) {
          host.showToast((PlanishLocalizations s) => s.sentThanks);
        } else if (result is FeedbackHandedOff) {
          host.showToast((PlanishLocalizations s) => s.handedOff);
        }
      }
      return result;
    } finally {
      _showing = false;
    }
  }

  /// Opens the quick report sheet ("Share feedback"), or the form directly
  /// when `quickReport.enabled` is false. This is what report gestures do.
  static Future<void> prompt() async {
    final host = PlanishHostState.current;
    if (host == null || _showing || host.hasOpenModal) {
      return;
    }
    if (!config.quickReport.enabled) {
      await show();
      return;
    }
    await host.showModal<void>(
      (context) => _themed(
        config.quickReport.builder?.call(context) ?? const QuickReportSheet(),
      ),
      opaque: false,
    );
  }

  /// Shows the floating console (debug tools must be enabled).
  static void showConsole() =>
      PlanishHostState.current?.setConsoleVisible(visible: true);

  /// Hides the floating console.
  static void hideConsole() =>
      PlanishHostState.current?.setConsoleVisible(visible: false);

  /// Opens the tutorial. Resolves with true when the user reached the end.
  static Future<bool> showTutorial() async {
    final host = PlanishHostState.current;
    if (host == null) {
      return false;
    }
    return await host.showModal<bool>(
          (_) => _themed(const TutorialPage()),
          dismissible: config.tutorial.canSkip,
        ) ??
        false;
  }

  /// Logs an error you caught yourself. Forwarded to every log sink and
  /// attached to the next report.
  static void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? message,
    bool fatal = false,
    String? tag,
  }) {
    final text = message ?? error.toString();
    if (fatal) {
      Log.fatal(text, error: error, stackTrace: stackTrace, tag: tag);
    } else {
      Log.error(text, error: error, stackTrace: stackTrace, tag: tag);
    }
  }

  /// What the app is doing now: context, logs, backend requests and the
  /// error. The form takes it on open; a draft sent later keeps it.
  static Future<FrozenContext> freezeContext({
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final privacy = config.privacy;
    final now = DateTime.now();
    final context = <String, String>{
      ...await DeviceContext.collect(privacy.deviceInfo),
      'session.id': sessionId,
      if (_startedAt != null)
        'app.uptime': '${now.difference(_startedAt!).inSeconds}s',
      'app.lifecycle': _backObserver.lifecycle.name,
      if (PersistedLogs.previousExit != PreviousExit.unknown)
        'app.previousExit': PersistedLogs.previousExit.name,
      if (_backObserver.resumedAt != null)
        'app.sinceResume':
            '${now.difference(_backObserver.resumedAt!).inSeconds}s',
      ..._tags,
      if (navigationObserver.currentRoute != null)
        'screen': navigationObserver.currentRoute!,
    };
    final providers = <ReportContextProvider>[
      ...config.reportContext,
      ...debugPlugins.whereType<ReportContextProvider>(),
    ];
    for (final provider in providers) {
      try {
        context.addAll(await provider.collectReportContext());
      } on Object catch (e) {
        context['${provider.runtimeType}.error'] = e.toString();
      }
    }
    return FrozenContext(
      context: context,
      logs: Log.entries,
      requests: pickRequests(
        NetworkLog.calls,
        firstErrorAt: Log.entries
            .where(
              (LogEntry e) =>
                  e.level >= LogLevel.error &&
                  (e.tag == 'flutter' || e.tag == 'uncaught'),
            )
            .firstOrNull
            ?.time,
      ),
      error: error == null ? null : Log.redact(error.toString()),
      stackTrace: stackTrace == null ? null : Log.redact(stackTrace.toString()),
    );
  }

  /// Assembles a report from the form's input and the context: [frozen]
  /// when given (a draft keeps the context of when it was started), else
  /// the current one. [id] keeps a draft's id.
  static Future<FeedbackReport> buildReport({
    required String message,
    FeedbackCategory? category,
    Uint8List? screenshot,
    Object? error,
    StackTrace? stackTrace,
    bool includeLogs = true,
    String? email,
    FrozenContext? frozen,
    String? id,
    ReportSource source = ReportSource.manual,
    String? relatedTo,
    bool appAttachments = true,
  }) async {
    final privacy = config.privacy;
    final f =
        frozen ?? await freezeContext(error: error, stackTrace: stackTrace);
    final frozenStack = f.stackTrace;
    var report = FeedbackReport(
      id: id,
      message: message,
      category: category,
      screenshot: screenshot,
      error: frozen == null ? error : f.error,
      stackTrace: frozen == null
          ? stackTrace
          : (frozenStack == null ? null : StackTrace.fromString(frozenStack)),
      logs: includeLogs && privacy.includeLogs ? f.logs : const <LogEntry>[],
      context: f.context,
      email: email,
      createdAt: DateTime.now(),
      appName: config.appName ?? await DeviceContext.appName() ?? 'App',
      sessionId: sessionId,
      requests: f.requests,
      source: source,
      relatedTo: relatedTo,
    );
    if (PersistedLogs.previousExit == PreviousExit.abnormal &&
        PersistedLogs.previousSession.isNotEmpty) {
      report = report.copyWith(
        attachments: <FeedbackAttachment>[
          ...report.attachments,
          FeedbackAttachment.text(
            'previous-session.txt',
            Log.entriesAsText(PersistedLogs.previousSession),
          ),
        ],
      );
    }
    final extra = appAttachments ? config.attachments : null;
    if (extra != null) {
      report = report.copyWith(attachments: await extra(report));
    }
    final notes = config.analysisNotes;
    if (notes != null) {
      report = report.copyWith(analysisNotes: notes(report));
    }
    return report;
  }

  /// Runs `privacy.beforeSend`, then the sender. Never throws.
  static Future<FeedbackSendResult> send(FeedbackReport report) async {
    try {
      final reviewed = config.privacy.beforeSend == null
          ? report
          : await config.privacy.beforeSend!(report);
      if (reviewed == null) {
        return const FeedbackCancelled();
      }
      final result = await config.sender.send(reviewed);
      if (result is FeedbackSent || result is FeedbackHandedOff) {
        _notifySent(reviewed);
      }
      if (result is FeedbackFailed) {
        Log.warning(
          'Feedback not sent: ${result.message}',
          error: result.error,
          tag: 'feedback',
        );
      }
      return result;
    } on Object catch (e, s) {
      Log.error(
        'Feedback sender threw',
        error: e,
        stackTrace: s,
        tag: 'feedback',
      );
      return FeedbackFailed(e.toString(), error: e, stackTrace: s);
    }
  }

  static void _notifySent(FeedbackReport report) {
    final callback = config.onReportSent;
    if (callback == null) {
      return;
    }
    try {
      callback(report);
    } on Object catch (e, s) {
      Log.error('onReportSent threw', error: e, stackTrace: s, tag: 'feedback');
    }
  }

  /// `config.theme`, else the app's theme with `useAppTheme`, else Planish's.
  static Widget _themed(Widget child) {
    final theme = config.theme;
    if (theme == null && config.useAppTheme) {
      return child;
    }
    return Builder(
      builder: (context) => Theme(
        data:
            theme?.call(context) ??
            planishTheme(context, brand: config.brandColor),
        child: child,
      ),
    );
  }

  // Prompt cards in this session, and the person's answer to "keep quiet".
  static const String _quietKey = 'planish.prompts.quiet';
  static const String _askedKey = 'planish.prompts.asked';
  static const int _maxCards = 3;
  static int _cards = 0;
  static int _laterInRow = 0;
  static bool _quietChosen = false;
  static bool _askedQuiet = false;
  static Timer? _cardTimer;

  static PromptMode get _promptMode {
    final mode = config.promptMode;
    return mode == PromptMode.notify && _quietChosen ? PromptMode.quiet : mode;
  }

  static void _promptAfterError(Object error, StackTrace? stackTrace) {
    // Wait for the frame after the error so the screenshot shows the broken
    // screen rather than a half-built one.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          unawaited(_prepare(error, stackTrace));
        });
      })
      // An error on an idle screen schedules no frame of its own.
      ..scheduleFrame();
  }

  /// An automatic draft for the error, then, in `notify`, the card.
  static Future<void> _prepare(Object error, StackTrace? stackTrace) async {
    final host = PlanishHostState.current;
    if (host == null || host.hasOpenModal || _showing) {
      return;
    }
    final store = activeDraftStore;
    FeedbackDraft? draft;
    if (store != null) {
      final shot = config.privacy.includeScreenshot
          ? await host.captureScreenshot()
          : null;
      final now = DateTime.now();
      draft = await store.save(
        FeedbackDraft(
          id: FeedbackReport.newId(),
          source: DraftSource.automatic,
          touched: false,
          createdAt: now,
          updatedAt: now,
          frozen: await freezeContext(error: error, stackTrace: stackTrace),
          relatedTo: _autoSent[_errorKey(error)],
        ),
        screenshot: shot,
      );
    }
    if (_promptMode != PromptMode.notify || _cards >= _maxCards) {
      return;
    }
    _cards++;
    _showCard(
      askQuiet: false,
      onPrimary: () {
        _laterInRow = 0;
        final d = draft;
        unawaited(
          d == null
              ? show(error: error, stackTrace: stackTrace)
              : _open(draft: d),
        );
      },
      onSecondary: () {
        _laterInRow++;
        if (_laterInRow >= 2 && !_askedQuiet) {
          _askQuiet();
        }
      },
    );
  }

  // Reports sent by autoSendErrors in this launch, by error.
  static const int _maxAutoSent = 5;
  static final Map<String, String> _autoSent = <String, String>{};
  static bool _emailWarned = false;

  static String _errorKey(Object error) {
    final text = Log.redact(error.toString());
    return text.length > 300 ? text.substring(0, 300) : text;
  }

  /// `autoSendErrors`: a minimal report for the error, sent at once.
  static void _autoSend(Object error, StackTrace? stackTrace) {
    if (config.sender is EmailFeedbackSender) {
      if (!_emailWarned) {
        _emailWarned = true;
        Log.warning(
          'autoSendErrors is ignored with EmailFeedbackSender: '
          'a mail needs the user to press send.',
          tag: 'feedback',
        );
      }
      return;
    }
    final key = _errorKey(error);
    if (_autoSent.containsKey(key) || _autoSent.length >= _maxAutoSent) {
      return;
    }
    final id = FeedbackReport.newId();
    _autoSent[key] = id;
    () async {
      final report = await buildReport(
        message: '',
        error: error,
        stackTrace: stackTrace,
        id: id,
        source: ReportSource.automatic,
        appAttachments: false,
      );
      final result = await send(report);
      if (result is! FeedbackSent) {
        Log.warning('Automatic error report not sent', tag: 'feedback');
      }
    }().ignore();
  }

  static const String _remindedKey = 'planish.drafts.remindedAt';

  /// Runs the launch reminder now. For tests.
  @visibleForTesting
  static Future<void> remindDraftsNow() => _remindDrafts();

  /// At launch: a card when drafts are waiting, at most once a day.
  static Future<void> _remindDrafts() async {
    final host = PlanishHostState.current;
    final store = activeDraftStore;
    if (host == null || store == null || host.hasOpenModal || _showing) {
      return;
    }
    final drafts = await store.list();
    if (drafts.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(prefs.getString(_remindedKey) ?? '');
    final now = DateTime.now();
    if (last != null && now.difference(last) < const Duration(days: 1)) {
      return;
    }
    await prefs.setString(_remindedKey, now.toIso8601String());
    _showCard(
      reminder: drafts.length,
      onPrimary: () => unawaited(_open(draft: drafts.first)),
      onSecondary: () {},
    );
  }

  static void _askQuiet() {
    _askedQuiet = true;
    SharedPreferences.getInstance()
        .then((SharedPreferences p) => p.setBool(_askedKey, true))
        .ignore();
    _showCard(
      askQuiet: true,
      onPrimary: () {
        _quietChosen = true;
        SharedPreferences.getInstance()
            .then((SharedPreferences p) => p.setBool(_quietKey, true))
            .ignore();
      },
      onSecondary: () => _laterInRow = 0,
    );
  }

  /// Shows a card that closes on either button, or by itself after 8 s
  /// (which does not count as a dismissal).
  static void _showCard({
    bool askQuiet = false,
    int? reminder,
    required VoidCallback onPrimary,
    required VoidCallback onSecondary,
  }) {
    final host = PlanishHostState.current;
    if (host == null) {
      return;
    }
    void close(VoidCallback then) {
      _cardTimer?.cancel();
      host.showCard(null);
      then();
    }

    _cardTimer?.cancel();
    host.showCard(
      _themed(
        ErrorCard(
          askQuiet: askQuiet,
          pendingDrafts: reminder,
          onPrimary: () => close(onPrimary),
          onSecondary: () => close(onSecondary),
        ),
      ),
    );
    _cardTimer = Timer(const Duration(seconds: 8), () => host.showCard(null));
  }

  /// Forgets the configuration and uninstalls the handlers. Meant for tests.
  @visibleForTesting
  static Future<void> reset() async {
    ErrorHandlers.uninstall();
    WidgetsBinding.instance.removeObserver(_backObserver);
    _config = null;
    _showing = false;
    activeDraftStore = null;
    _cardTimer?.cancel();
    _cards = 0;
    _laterInRow = 0;
    _autoSent.clear();
    _emailWarned = false;
    pendingDrafts.value = 0;
    _quietChosen = false;
    _askedQuiet = false;
    _tags.clear();
    debugTools.reset();
    await Log.reset();
  }

  static String _newSessionId() {
    final r = math.Random();
    final suffix = r.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-$suffix';
  }
}

class _BindingObserver with WidgetsBindingObserver {
  AppLifecycleState lifecycle = AppLifecycleState.resumed;
  DateTime? resumedAt;

  @override
  Future<bool> didPopRoute() async =>
      PlanishHostState.current?.handleBack() ?? false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      resumedAt = DateTime.now();
    }
    Log.info(state.name, tag: 'lifecycle', data: {'state': state.name});
    PersistedLogs.onLifecycle(state).ignore();
  }
}

/// `Planish.drafts`: list or delete the drafts kept on this device.
class PlanishDrafts {
  PlanishDrafts._();

  /// Newest change first. Expired drafts are removed while listing.
  Future<List<FeedbackDraft>> list() async =>
      await activeDraftStore?.list() ?? const <FeedbackDraft>[];

  /// Deletes a draft and its screenshot.
  Future<void> discard(String id) async => activeDraftStore?.discard(id);

  /// How many drafts wait on this device; updates as they are saved, sent or
  /// deleted. Use it for a badge on your own report button.
  ValueListenable<int> get pending => pendingDrafts;
}
