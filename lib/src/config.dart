import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:planish/src/debug/debug_plugin.dart';
import 'package:planish/src/host/gestures/gesture_configs.dart';
import 'package:planish/src/log/redaction.dart';
import 'package:planish/src/report/feedback_report.dart';

/// How much device and app information goes into a report.
enum DeviceInfoLevel {
  /// Nothing.
  none,

  /// App version, OS and version, device model, locale.
  basic,

  /// Also manufacturer, hardware, physical/emulator flag, screen size, and
  /// the platform device identifier.
  full,
}

/// Controls what a report may contain. Defaults are conservative: no shared
/// preferences, no network bodies, sensitive headers hidden.
@immutable
class PrivacyConfig {
  const PrivacyConfig({
    this.includeScreenshot = true,
    this.includeLogs = true,
    this.deviceInfo = DeviceInfoLevel.basic,
    this.includeSharedPreferences = false,
    this.includeNetworkSummary = false,
    this.sensitiveHeaders = defaultSensitiveHeaders,
    this.sensitiveQueryParameters = defaultSensitiveQueryParameters,
    this.traceHeaders = const <String>[],
    this.redactors = const <Redactor>[],
    this.beforeSend,
    this.letUserReviewData = true,
  });

  /// Common authentication headers.
  static const Set<String> defaultSensitiveHeaders = <String>{
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
  };

  /// Common secret-bearing query parameter names.
  static const Set<String> defaultSensitiveQueryParameters = <String>{
    'token',
    'access_token',
    'refresh_token',
    'key',
    'api_key',
    'apikey',
    'password',
    'secret',
  };

  /// Capture a screenshot. The user can still remove it from the form.
  final bool includeScreenshot;

  /// Attach recent logs. The user can still untick it in the form.
  final bool includeLogs;

  /// Device and app context level.
  final DeviceInfoLevel deviceInfo;

  /// Attach all shared preferences (keys and values). They often contain
  /// tokens; enable only if you know what your app stores.
  final bool includeSharedPreferences;

  /// Attach a summary of recent HTTP calls recorded by `LoggingHttpClient`:
  /// method, URL, status and duration. Bodies are never attached.
  final bool includeNetworkSummary;

  /// Header names (case-insensitive) hidden from the network log.
  final Set<String> sensitiveHeaders;

  /// Query parameter names (case-insensitive) hidden from logged URLs.
  final Set<String> sensitiveQueryParameters;

  /// Extra response or request header names read as a call's request id,
  /// after `x-request-id`, `request-id`, `x-correlation-id` and
  /// `correlation-id`. Trace ids come from `traceparent`, `sentry-trace`,
  /// `b3`, `x-b3-traceid` and `x-datadog-trace-id`.
  final List<String> traceHeaders;

  /// Extra redactors applied to log messages, in addition to `Log.redactors`.
  final List<Redactor> redactors;

  /// Last chance to inspect or modify a report. Return `null` to cancel the
  /// send; the user sees a "cancelled" state.
  final FutureOr<FeedbackReport?> Function(FeedbackReport report)? beforeSend;

  /// Show a "What will be sent?" link in the form.
  final bool letUserReviewData;
}

/// A gesture that can open the debug tools or the feedback form.
enum TriggerGesture {
  /// Shake the device.
  shake,

  /// Tap with several fingers, several times.
  multiFingerTap,

  /// Swipe inwards from a screen edge.
  edgeSwipe,
}

/// Tuning for the trigger gestures.
@immutable
class GestureConfig {
  const GestureConfig({
    this.shake = const ShakeGestureConfig(),
    this.multiFingerTap = const MultiFingerTapGestureConfig(),
    this.edgeSwipe = const EdgeSwipeGestureConfig(),
  });

  /// Shake sensitivity.
  final ShakeGestureConfig shake;

  /// Multi-finger tap settings.
  final MultiFingerTapGestureConfig multiFingerTap;

  /// Edge swipe settings.
  final EdgeSwipeGestureConfig edgeSwipe;
}

/// Debug tools: floating button, console, network log, device info,
/// preferences viewer, and your own plugins.
@immutable
class DebugToolsConfig {
  const DebugToolsConfig({
    this.enabled = kDebugMode || kProfileMode,
    this.gestures = const <TriggerGesture>{TriggerGesture.shake},
    this.plugins = const <DebugPlugin>[],
    this.rememberState = true,
    this.useAppTheme = false,
    this.theme,
  });

  /// Debug tools are not even built unless this is true. Defaults to debug and
  /// profile builds only. For internal or beta release builds, gate it on a
  /// flag you control, e.g.
  /// `enabled: kDebugMode || const bool.fromEnvironment('DEBUG_TOOLS')` with
  /// `flutter build ipa --dart-define=DEBUG_TOOLS=true`. To give them to some
  /// users only, keep this false and call `Planish.debugTools.allow(true)`
  /// for them at run time. Turning them on for everyone exposes logs,
  /// network calls and preferences to whoever holds the device.
  final bool enabled;

  /// Gestures that toggle the floating debug button. When a gesture is also
  /// listed in `PlanishConfig.reportGestures`, the debug tools win
  /// while they are enabled: the menu has a "Send feedback" entry anyway.
  final Set<TriggerGesture> gestures;

  /// Extra entries in the debug menu.
  final List<DebugPlugin> plugins;

  /// Keep the button visible across restarts once it has been shown.
  final bool rememberState;

  /// Render the debug tools with the app's own theme (light and dark,
  /// following it live) instead of the built-in dark slate palette.
  final bool useAppTheme;

  /// Builds a custom theme for the debug tools, e.g.
  /// `theme: (context) => Theme.of(context).copyWith(...)`. Ignored when
  /// [useAppTheme] is true.
  final ThemeData Function(BuildContext context)? theme;
}

/// What happens after an uncaught error, besides logging it.
enum PromptMode {
  /// Nothing automatic. Logs, network capture and manual reports work as
  /// always.
  off,

  /// A draft is prepared with the screenshot and context; it waits in the
  /// form's Drafts list.
  quiet,

  /// The draft is prepared and a card offers to add details, at most 3 per
  /// session; after two dismissals in a row it offers to switch to [quiet].
  notify,
}

/// What the package does with uncaught errors.
@immutable
class ErrorHandlingConfig {
  const ErrorHandlingConfig({
    this.captureFlutterErrors = true,
    this.capturePlatformErrors = true,
    this.promptFeedbackOnError = false,
    this.promptCooldown = const Duration(seconds: 30),
    this.shouldPrompt,
  });

  /// Log errors reported through `FlutterError.onError`. The previous handler
  /// is still called.
  final bool captureFlutterErrors;

  /// Log errors reported through `PlatformDispatcher.onError`. The previous
  /// handler is still called.
  final bool capturePlatformErrors;

  /// `true` maps to `PlanishConfig(prompts: PromptMode.notify)`, `false` to
  /// [PromptMode.off]. `prompts`, when set, wins.
  @Deprecated('Use PlanishConfig.prompts')
  final bool promptFeedbackOnError;

  /// Minimum time between two automatic prompts.
  final Duration promptCooldown;

  /// Filter applied before prompting. Return `false` to skip. Defaults to
  /// skipping silent errors and layout overflows.
  final bool Function(Object error, StackTrace? stackTrace)? shouldPrompt;
}

/// One entry of the quick report sheet.
@immutable
class QuickReportAction {
  const QuickReportAction({
    required this.icon,
    required this.label,
    this.category,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Preselected in the form. Ignored when [onTap] is set.
  final FeedbackCategory? category;

  /// Replaces the default behaviour (opening the form).
  final Future<void> Function(BuildContext context)? onTap;
}

/// The small sheet a report gesture opens before the form: "Something
/// wrong?" with a couple of choices, like Google or Instagram apps.
@immutable
class QuickReportConfig {
  const QuickReportConfig({
    this.enabled = true,
    this.title,
    this.subtitle,
    this.actions,
    this.builder,
  });

  /// When false, gestures open the full form directly.
  final bool enabled;

  /// Replaces the default title.
  final String Function(BuildContext context)? title;

  /// Replaces the default subtitle.
  final String Function(BuildContext context)? subtitle;

  /// Replaces the default "Report a problem" / "Share an idea" / "Ask a
  /// question" entries.
  final List<QuickReportAction> Function(BuildContext context)? actions;

  /// Your own sheet. It is shown over the app in a transparent modal; close
  /// it with `PlanishModal.of(context).close(null)` and open the
  /// form with `Planish.show(category: ...)`.
  final WidgetBuilder? builder;
}

/// The short walkthrough that teaches users how to report a problem.
@immutable
class TutorialConfig {
  const TutorialConfig({this.showOnFirstLaunch = false, this.canSkip = true});

  /// Open the tutorial once, the first time the app starts.
  final bool showOnFirstLaunch;

  /// Show a close button so the user can leave before the last step.
  final bool canSkip;
}

/// Top-level configuration passed to `Planish.init`.
@immutable
class PlanishConfig {
  const PlanishConfig({
    required this.sender,
    this.appName,
    this.categories = const <FeedbackCategory>[],
    this.categoryRequired = false,
    this.askEmail = false,
    this.attachments,
    this.reportGestures = const <TriggerGesture>{},
    this.gestures = const GestureConfig(),
    this.privacy = const PrivacyConfig(),
    this.debugTools = const DebugToolsConfig(),
    this.errorHandling = const ErrorHandlingConfig(),
    this.tutorial = const TutorialConfig(),
    this.quickReport = const QuickReportConfig(),
    this.brandColor,
    this.useAppTheme = false,
    this.theme,
    this.captureDebugPrint = kDebugMode,
    this.reportContext = const <ReportContextProvider>[],
    this.analysisNotes,
    this.persistLogs = true,
    this.keepDrafts,
    this.prompts,
    this.onReportSent,
    this.remindDrafts = true,
    this.autoSendErrors = false,
  });

  /// At launch, when drafts are waiting, a card says how many and opens the
  /// newest; at most once a day. Nothing leaves the device. Read the count
  /// yourself with `Planish.drafts.pending`, e.g. for a badge.
  final bool remindDrafts;

  /// Off by default. When on, every uncaught error is also sent at once
  /// through [sender], without the user pressing Send: the error, its stack
  /// trace, the context and the logs, marked `source: automatic`. No
  /// screenshot, message, email or [attachments]; `beforeSend` still runs.
  /// The same error is sent once per launch, at most 5 per launch. Ignored
  /// with [EmailFeedbackSender], which needs the user.
  ///
  /// Turning this on is your decision: errors and their logs then leave the
  /// device without the user's action. Say so in your privacy policy and in
  /// the stores' data-safety forms.
  final bool autoSendErrors;

  /// Called after a report left the device (or was handed to the mail
  /// client). Use it to tag your crash reporter with `report.id`, so an
  /// event there can be traced back to the report.
  final void Function(FeedbackReport report)? onReportSent;

  /// Keep the log buffer on disk (bounded, under the app support directory)
  /// so that a report sent after a crash or a force quit can include the logs
  /// of the previous launch. Reports then carry `app.previousExit` and, when
  /// that launch ended in the foreground, a `previous-session.txt`
  /// attachment. Nothing is sent without the user pressing Send.
  final bool persistLogs;

  /// Keep a report closed before sending as a draft on the device (at most
  /// 10, for 30 days), with its screenshot and the technical context of when
  /// the form opened. Defaults to [persistLogs]. Turning it on without
  /// [persistLogs] is fine: drafts carry their own frozen context.
  final bool? keepDrafts;

  /// Whether drafts are kept: [keepDrafts], else [persistLogs].
  bool get draftsEnabled => keepDrafts ?? persistLogs;

  /// What happens after an uncaught error. Defaults to [PromptMode.off];
  /// consider `notify` only in internal or beta builds.
  final PromptMode? prompts;

  /// [prompts], else what the deprecated `promptFeedbackOnError` says.
  PromptMode get promptMode =>
      prompts ??
      // ignore: deprecated_member_use_from_same_package
      (errorHandling.promptFeedbackOnError
          ? PromptMode.notify
          : PromptMode.off);

  /// Where reports go.
  final FeedbackSender sender;

  /// Snapshots of application state added to every report's context.
  final List<ReportContextProvider> reportContext;

  /// Fixed text placed under "Notes for analysis" in the report brief: how
  /// tags map to classes, where to start reading, build conventions. Written
  /// once by the team for whoever (or whatever) analyses the report.
  final String Function(FeedbackReport report)? analysisNotes;

  /// Shown in the report. Defaults to the app name from the platform.
  final String? appName;

  /// Categories offered in the form. Empty hides the picker.
  final List<FeedbackCategory> categories;

  /// Require a category before sending.
  final bool categoryRequired;

  /// Show an optional e-mail field so you can reply. The value is remembered
  /// on the device for the next report and sent as `FeedbackReport.email`.
  final bool askEmail;

  /// Extra files to attach (a database export, a settings dump, ...).
  final Future<List<FeedbackAttachment>> Function(FeedbackReport report)?
  attachments;

  /// Gestures that open the feedback form directly, in every build type.
  /// `{TriggerGesture.shake}` gives the shake-to-report behaviour users know
  /// from Google or Instagram apps. Empty by default.
  final Set<TriggerGesture> reportGestures;

  /// Sensitivity of the gestures used by [reportGestures] and
  /// [DebugToolsConfig.gestures].
  final GestureConfig gestures;

  /// What goes into a report.
  final PrivacyConfig privacy;

  /// Debug tools.
  final DebugToolsConfig debugTools;

  /// Error handling.
  final ErrorHandlingConfig errorHandling;

  /// First-launch tutorial.
  final TutorialConfig tutorial;

  /// Sheet shown by [reportGestures] before the form.
  final QuickReportConfig quickReport;

  /// Your brand colour on the feedback form, quick sheet and tutorial:
  /// buttons take it as given, text and outlines a shade of it that stays
  /// readable. Ignored with [useAppTheme] or [theme].
  final Color? brandColor;

  /// Show the feedback form, quick sheet and tutorial in the app's own theme
  /// instead of Planish's colours. Ignored with [theme].
  final bool useAppTheme;

  /// Builds the theme of the feedback form, quick sheet and tutorial, e.g.
  /// `theme: (context) => planishTheme(context).copyWith(...)`. By default
  /// they use Planish's colours in the app's brightness, following it live.
  final ThemeData Function(BuildContext context)? theme;

  /// Record `debugPrint` output in the log buffer. Defaults to debug builds.
  final bool captureDebugPrint;
}
