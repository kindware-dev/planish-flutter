import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/log/log.dart';
import 'package:planish/src/network/trace_ids.dart';

/// A category the user can pick in the feedback form.
///
/// [label] is shown as-is. To localize it, build the list where you have a
/// `BuildContext`, or map [id] to your own strings.
@immutable
class FeedbackCategory {
  /// Creates a category.
  const FeedbackCategory({
    required this.id,
    required this.label,
    this.icon,
    this.labelBuilder,
    this.hintBuilder,
  });

  /// Stable identifier sent with the report.
  final String id;

  /// Text shown in the picker.
  final String label;

  /// Optional icon shown next to the label.
  final IconData? icon;

  /// Localized label for the form; [label] is still used in reports.
  /// ```dart
  /// FeedbackCategory(id: 'bug', label: 'Bug', labelBuilder: (c) => L10n.of(c).bug)
  /// ```
  final String Function(BuildContext context)? labelBuilder;

  /// Placeholder of the message field while this category is picked, e.g.
  /// "What are you trying to do?" for a question. Null keeps the default.
  final String Function(BuildContext context)? hintBuilder;

  /// Label to show in [context].
  String displayLabel(BuildContext context) =>
      labelBuilder?.call(context) ?? label;

  static final FeedbackCategory bug = FeedbackCategory(
    id: 'bug',
    label: 'Bug',
    icon: Icons.bug_report_outlined,
    labelBuilder: (BuildContext c) => c.planishStrings.categoryBug,
  );

  static final FeedbackCategory idea = FeedbackCategory(
    id: 'idea',
    label: 'Idea',
    icon: Icons.lightbulb_outline,
    labelBuilder: (BuildContext c) => c.planishStrings.categoryIdea,
    hintBuilder: (BuildContext c) => c.planishStrings.messageHintIdea,
  );

  static final FeedbackCategory question = FeedbackCategory(
    id: 'question',
    label: 'Question',
    icon: Icons.help_outline,
    labelBuilder: (BuildContext c) => c.planishStrings.categoryQuestion,
    hintBuilder: (BuildContext c) => c.planishStrings.messageHintQuestion,
  );

  static final FeedbackCategory other = FeedbackCategory(
    id: 'other',
    label: 'Other',
    icon: Icons.more_horiz,
    labelBuilder: (BuildContext c) => c.planishStrings.categoryOther,
    hintBuilder: (BuildContext c) => c.planishStrings.messageHintOther,
  );

  /// [bug], [idea], [question], [other], labelled in the app's locale in the
  /// form; `label` stays English in reports.
  static final List<FeedbackCategory> defaults = <FeedbackCategory>[
    bug,
    idea,
    question,
    other,
  ];

  @override
  bool operator ==(Object other) => other is FeedbackCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A file attached to a report.
@immutable
class FeedbackAttachment {
  /// Creates an attachment.
  const FeedbackAttachment({
    required this.name,
    required this.bytes,
    this.mimeType = 'application/octet-stream',
  });

  /// Plain-text attachment.
  FeedbackAttachment.text(this.name, String content)
    : bytes = Uint8List.fromList(utf8.encode(content)),
      mimeType = 'text/plain';

  final String name;

  final Uint8List bytes;

  final String mimeType;
}

/// Everything collected for one feedback submission.
///
/// Senders receive this object. Adding fields to it later is not a breaking
/// Where a report comes from.
enum ReportSource {
  /// The person, in the form.
  manual,

  /// The package, after an uncaught error, without the person's action
  /// (`autoSendErrors`).
  automatic,

  /// An AI agent.
  agent,
}

/// change for senders, which is why they do not take positional arguments.
@immutable
class FeedbackReport {
  /// Creates a report. Prefer letting the package build it.
  FeedbackReport({
    required this.message,
    required this.createdAt,
    required this.appName,
    this.category,
    this.screenshot,
    this.error,
    this.stackTrace,
    this.logs = const <LogEntry>[],
    this.context = const {},
    this.attachments = const <FeedbackAttachment>[],
    this.email,
    this.sessionId,
    this.analysisNotes,
    this.requests = const <BackendRequest>[],
    this.source = ReportSource.manual,
    this.relatedTo,
    String? id,
  }) : id = id ?? _newId();

  /// Version of [toJson]'s shape. Bumped on incompatible changes.
  static const int schemaVersion = 1;

  /// Random identifier, unique per report. Lets a backend deduplicate
  /// retries.
  final String id;

  /// `Planish.sessionId` at the time of the report.
  final String? sessionId;

  /// Who or what created the report.
  final ReportSource source;

  /// Id of an earlier report about the same problem: the one sent
  /// automatically for the error this report adds details to.
  final String? relatedTo;

  /// Team-written guidance for whoever analyses the report. See
  /// `PlanishConfig.analysisNotes`.
  final String? analysisNotes;

  final String message;

  /// Category picked by the user, if any.
  final FeedbackCategory? category;

  /// Reply address typed by the user, when `askEmail` is on.
  final String? email;

  /// PNG screenshot, possibly annotated. Null when the user removed it or
  /// capture failed.
  final Uint8List? screenshot;

  /// The error that triggered the report, if any.
  final Object? error;

  /// Stack trace of [error], if any.
  final StackTrace? stackTrace;

  /// Recent log entries, oldest first. Empty when logs are excluded.
  final List<LogEntry> logs;

  /// Backend calls around the error, with their request and trace ids.
  final List<BackendRequest> requests;

  /// Key/value context (app version, device model, route, ...), already
  /// filtered by the privacy settings.
  final Map<String, String> context;

  /// Extra files from `PlanishConfig.attachments` and plugins.
  final List<FeedbackAttachment> attachments;

  final DateTime createdAt;

  final String appName;

  /// Redacted `error.toString()`, or null.
  String? get errorText => error == null ? null : Log.redact(error.toString());

  /// Redacted stack trace, or null.
  String? get stackTraceText =>
      stackTrace == null ? null : Log.redact(stackTrace.toString());

  /// Logs as a text block.
  String get logsAsText => Log.entriesAsText(logs);

  /// Context as `key: value` lines.
  String get contextAsText => context.entries
      .map((MapEntry<String, String> e) => '${e.key}: ${e.value}')
      .join('\n');

  /// A plain-text rendering of the whole report (without the screenshot).
  String toPlainText() {
    final b = StringBuffer()
      ..writeln('$appName feedback report')
      ..writeln('Created: ${createdAt.toIso8601String()}');
    if (category != null) {
      b.writeln('Category: ${category!.label} (${category!.id})');
    }
    if (email != null) {
      b.writeln('From: $email');
    }
    b
      ..writeln()
      ..writeln('Message:')
      ..writeln(message.isEmpty ? '(empty)' : message);
    if (errorText != null) {
      b
        ..writeln()
        ..writeln('Error:')
        ..writeln(errorText);
    }
    if (stackTraceText != null) {
      b
        ..writeln()
        ..writeln('Stack trace:')
        ..writeln(stackTraceText);
    }
    if (requests.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Backend requests:')
        ..writeln(requests.map((BackendRequest r) => r.summary()).join('\n'));
    }
    if (context.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Context:')
        ..writeln(contextAsText);
    }
    if (logs.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Logs (${logs.length}):')
        ..writeln(logsAsText);
    }
    return b.toString();
  }

  /// JSON-friendly map (without binary data). Logs are objects, see
  /// [LogEntry.toJson].
  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'id': id,
    'sessionId': sessionId,
    'source': source.name,
    if (relatedTo != null) 'relatedTo': relatedTo,
    'appName': appName,
    'createdAt': createdAt.toIso8601String(),
    'message': message,
    'category': category?.id,
    'email': email,
    'error': errorText,
    'stackTrace': stackTraceText,
    'context': context,
    'logs': logs.map((LogEntry e) => e.toJson()).toList(),
    if (requests.isNotEmpty)
      'requests': requests.map((BackendRequest r) => r.toJson()).toList(),
    'hasScreenshot': screenshot != null,
    'attachments': attachments.map((FeedbackAttachment a) => a.name).toList(),
    if (analysisNotes != null) 'analysisNotes': analysisNotes,
  };

  /// A brief for the person or tool that will analyse the report: what the
  /// user said, what went wrong, what the app was doing in the minutes
  /// before, and the full error. Everything in it is derived from the report
  /// by fixed rules; nothing is guessed.
  String toMarkdown({Duration window = const Duration(minutes: 3)}) {
    final b = StringBuffer();
    final build = <String?>[
      context['build.mode'],
      context['build.env'],
      context['build.commit'],
    ].whereType<String>().join(', ');
    b
      ..writeln(
        '# $appName ${context['app.version'] ?? ''}'
        '${build.isEmpty ? '' : ' ($build)'}'
        '${category == null ? '' : ' — ${category!.id}'}'
        '${context['screen'] == null ? '' : ' — ${context['screen']}'}'
        ' — ${createdAt.toIso8601String()}',
      )
      ..writeln()
      ..writeln('**Message**: ${message.isEmpty ? '(empty)' : message}');
    if (email != null) {
      b.writeln('**From**: $email');
    }

    final recent = _recent(window);
    final errors = recent.where((LogEntry e) => e.level >= LogLevel.error);
    final warnings = recent.where((LogEntry e) => e.level == LogLevel.warning);
    b
      ..writeln()
      ..writeln('## Summary');
    if (errorText != null) {
      b.writeln('- Error: ${errorText!.split('\n').first}');
    }
    b.writeln(
      '- ${errors.length} error(s), ${warnings.length} warning(s) in the '
      '${window.inMinutes} min before the report'
      '${errors.isEmpty ? '' : '; last error: `${errors.last.format()}`'}'
      '${warnings.isEmpty ? '' : '; last warning: `${warnings.last.format()}`'}',
    );
    final background = _lastBackgroundSpan(logs);
    b.writeln(
      background == null
          ? '- No background period since launch'
          : '- Last background period: $background',
    );
    if (context['app.previousExit'] == 'abnormal') {
      b.writeln(
        '- The previous launch ended while in the foreground (crash, kill or '
        'force quit); its logs are attached as previous-session.txt',
      );
    }
    final runtime = <String>[
      for (final key in const [
        'app.lifecycle',
        'app.uptime',
        'app.sinceResume',
        'memory.rss',
      ])
        if (context[key] != null) '$key ${context[key]}',
    ];
    if (runtime.isNotEmpty) {
      b.writeln('- ${runtime.join(', ')}');
    }

    if (analysisNotes != null) {
      b
        ..writeln()
        ..writeln('## Notes for analysis')
        ..writeln(analysisNotes);
    }

    if (requests.isNotEmpty) {
      b
        ..writeln()
        ..writeln('## Backend requests')
        ..writeln('Search these ids in the backend logs or traces.');
      for (final r in requests) {
        b.writeln('- ${r.summary(quote: '`')}');
      }
    }

    if (context.isNotEmpty) {
      b
        ..writeln()
        ..writeln('## Context')
        ..writeln(contextAsText);
    }

    b
      ..writeln()
      ..writeln(
        '## Timeline (${recent.length} of ${logs.length} entries, '
        'last ${window.inMinutes} min)',
      )
      ..writeln('```')
      ..writeln(recent.map((LogEntry e) => e.formatFull()).join('\n'))
      ..writeln('```');

    if (errorText != null) {
      b
        ..writeln()
        ..writeln('## Error')
        ..writeln('```')
        ..writeln(errorText);
      if (stackTraceText != null) {
        b.writeln(stackTraceText);
      }
      b.writeln('```');
    }
    return b.toString();
  }

  // The entries of the last [window], or the last 20 when the window is
  // quieter than that.
  List<LogEntry> _recent(Duration window) {
    final since = createdAt.subtract(window);
    final inWindow = logs.where((LogEntry e) => !e.time.isBefore(since));
    if (inWindow.length >= 20 || logs.length <= 20) {
      return inWindow.toList();
    }
    return logs.sublist(logs.length - 20);
  }

  static String? _lastBackgroundSpan(List<LogEntry> logs) {
    DateTime? paused;
    String? last;
    for (final e in logs) {
      if (e.tag != 'lifecycle') {
        continue;
      }
      if (e.message == 'paused' || e.message == 'hidden') {
        paused ??= e.time;
      } else if (e.message == 'resumed' && paused != null) {
        final seconds = e.time.difference(paused).inSeconds;
        last =
            '${_clock(paused)} → ${_clock(e.time)} (${seconds}s in background)';
        paused = null;
      }
    }
    if (paused != null) {
      last = '${_clock(paused)} → still in background';
    }
    return last;
  }

  static String _clock(DateTime t) => t.toIso8601String().substring(11, 19);

  /// A random report id, as the package gives each report.
  static String newId() => _newId();

  static String _newId() {
    final r = math.Random();
    final b = StringBuffer();
    for (var i = 0; i < 16; i++) {
      b.write(r.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return b.toString();
  }

  /// Copy with some fields replaced.
  FeedbackReport copyWith({
    String? message,
    FeedbackCategory? category,
    String? email,
    Uint8List? screenshot,
    bool removeScreenshot = false,
    List<LogEntry>? logs,
    Map<String, String>? context,
    List<FeedbackAttachment>? attachments,
    String? analysisNotes,
    ReportSource? source,
    String? relatedTo,
  }) => FeedbackReport(
    id: id,
    sessionId: sessionId,
    analysisNotes: analysisNotes ?? this.analysisNotes,
    requests: requests,
    message: message ?? this.message,
    category: category ?? this.category,
    email: email ?? this.email,
    screenshot: removeScreenshot ? null : (screenshot ?? this.screenshot),
    error: error,
    stackTrace: stackTrace,
    logs: logs ?? this.logs,
    context: context ?? this.context,
    attachments: attachments ?? this.attachments,
    createdAt: createdAt,
    appName: appName,
    source: source ?? this.source,
    relatedTo: relatedTo ?? this.relatedTo,
  );
}

/// Outcome of [FeedbackSender.send].
sealed class FeedbackSendResult {
  const FeedbackSendResult();
}

/// The report left the device (or the user's mail client accepted it).
class FeedbackSent extends FeedbackSendResult {
  const FeedbackSent();
}

/// The report was handed to another app (the mail client on Android) and
/// whether it was then sent is unknown: Android gives no result back from
/// a share intent. The form closes; the user is told the report was handed
/// over, not that it was sent.
class FeedbackHandedOff extends FeedbackSendResult {
  const FeedbackHandedOff();
}

/// The user backed out (closed the mail client, for example). Nothing was
/// sent; the form stays open so nothing typed is lost.
class FeedbackCancelled extends FeedbackSendResult {
  const FeedbackCancelled();
}

/// Sending failed. [message] is shown to the user.
class FeedbackFailed extends FeedbackSendResult {
  const FeedbackFailed(this.message, {this.error, this.stackTrace});

  final String message;

  final Object? error;

  final StackTrace? stackTrace;
}

/// Delivers a [FeedbackReport] somewhere.
///
/// Return [FeedbackFailed] rather than throwing; thrown errors are converted to
/// a generic failure.
abstract interface class FeedbackSender {
  /// Sends [report].
  Future<FeedbackSendResult> send(FeedbackReport report);
}
