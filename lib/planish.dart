/// In-app bug reports with an annotated screenshot, recent logs and device
/// context, delivered by email, to your API or anywhere else.
///
/// See `Planish` to get started.
library;

export 'src/config.dart';
export 'src/debug/debug_plugin.dart';
export 'src/debug/debug_tools_controller.dart';
export 'src/host/gestures/gesture_configs.dart';
export 'src/host/modal_layer.dart' show PlanishModal;
export 'src/l10n/l10n.dart'
    show PlanishLocalizations, PlanishLocalizationsDelegate;
export 'src/log/log.dart';
export 'src/log/navigation_observer.dart';
export 'src/log/persisted_logs.dart' show PersistedLogs, PreviousExit;
export 'src/log/redaction.dart' show Redactor, Redactors;
export 'src/network/network_log.dart';
export 'src/network/trace_ids.dart' show BackendRequest, CallIds, IdsState;
export 'src/planish.dart';
export 'src/report/drafts.dart' show DraftSource, FeedbackDraft, FrozenContext;
export 'src/report/feedback_report.dart';
export 'src/report/senders/callback_feedback_sender.dart';
export 'src/report/senders/email_feedback_sender.dart';
export 'src/report/senders/http_feedback_sender.dart';
export 'src/report/senders/planish_cloud_sender.dart';
export 'src/ui/debug/built_in_plugins.dart';
export 'src/ui/debug/debug_theme.dart' show DebugPalette;
export 'src/ui/planish_theme.dart' show PlanishColors, planishTheme;
