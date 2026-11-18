// ignore_for_file: avoid_dynamic_calls, avoid_annotating_with_dynamic
// `fromLoggingRecord` takes a package:logging LogRecord without depending on it.

import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:planish/src/log/redaction.dart';

/// Severity of a [LogEntry], from least to most severe.
enum LogLevel {
  /// Very verbose diagnostics.
  trace,

  /// Developer diagnostics.
  debug,

  /// Normal application events.
  info,

  /// Something unexpected that the app recovered from.
  warning,

  /// A failure.
  error,

  /// A failure the app cannot recover from.
  fatal;

  /// Whether this level is at least as severe as [other].
  bool operator >=(LogLevel other) => index >= other.index;

  /// Short uppercase label, e.g. `WARN`.
  String get label => switch (this) {
    LogLevel.trace => 'TRACE',
    LogLevel.debug => 'DEBUG',
    LogLevel.info => 'INFO',
    LogLevel.warning => 'WARN',
    LogLevel.error => 'ERROR',
    LogLevel.fatal => 'FATAL',
  };
}

/// One log line, as stored in memory and delivered to every [LogSink].
@immutable
class LogEntry {
  /// Creates an entry. [time] defaults to now.
  LogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.tag,
    this.data,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  final LogLevel level;

  final String message;

  final Object? error;

  final StackTrace? stackTrace;

  final String? tag;

  /// Structured details (an HTTP status, a lifecycle state, ...). Kept for
  /// `toJson`; the message already says the same in words.
  final Map<String, Object?>? data;

  final DateTime time;

  /// Redacted `error.toString()`, or null.
  String? get errorText => error == null ? null : Log.redact(error.toString());

  /// Inverse of [toJson]. The error comes back as its text.
  factory LogEntry.fromJson(Map<String, Object?> json) => LogEntry(
    level: LogLevel.values.firstWhere(
      (LogLevel l) => l.label == json['level'],
      orElse: () => LogLevel.info,
    ),
    message: json['message'] as String? ?? '',
    error: json['error'],
    stackTrace: json['stackTrace'] == null
        ? null
        : StackTrace.fromString(json['stackTrace']! as String),
    tag: json['tag'] as String?,
    data: (json['data'] as Map?)?.cast<String, Object?>(),
    time: DateTime.tryParse(json['time'] as String? ?? ''),
  );

  /// JSON object with ISO time, level label, tag, message, error, stack trace
  /// and [data].
  Map<String, Object?> toJson() => <String, Object?>{
    'time': time.toIso8601String(),
    'level': level.label,
    if (tag != null) 'tag': tag,
    'message': message,
    if (errorText != null) 'error': errorText,
    if (stackTrace != null) 'stackTrace': Log.redact(stackTrace.toString()),
    if (data != null) 'data': data,
  };

  /// Single-line form: `12:03:44.120 WARN [auth] message`.
  String format({bool includeDate = false}) {
    final t = time.toIso8601String();
    final stamp = includeDate ? t : t.substring(11, 23);
    final tagPart = tag == null ? '' : ' [$tag]';
    return '$stamp ${level.label}$tagPart $message';
  }

  /// Multi-line form used in reports: message, then error and stack trace.
  String formatFull() {
    final b = StringBuffer(format(includeDate: true));
    final e = errorText;
    if (e != null && e != message) {
      b.write('\n  $e');
    }
    if (stackTrace != null) {
      b.write('\n${Log.redact(stackTrace.toString())}');
    }
    return b.toString();
  }

  @override
  String toString() => format();
}

/// Receives every entry that passes [Log.minLevel].
///
/// Implement this to forward logs to a file, Sentry, Crashlytics, etc.
/// A sink that throws is isolated: the other sinks still receive the entry.
abstract class LogSink {
  const LogSink();

  /// Called for every entry, on the main isolate.
  FutureOr<void> write(LogEntry entry);

  /// Called by [Log.removeSink] and [Log.reset].
  FutureOr<void> close() {}
}

/// Forwards entries to `dart:developer` so they show up in the IDE and
/// DevTools. Silent in release builds.
class DeveloperLogSink extends LogSink {
  const DeveloperLogSink();

  @override
  void write(LogEntry entry) {
    if (kReleaseMode) {
      return;
    }
    developer.log(
      entry.message,
      time: entry.time,
      level: _developerLevel(entry.level),
      name: entry.tag ?? 'app',
      error: entry.error,
      stackTrace: entry.stackTrace,
    );
  }

  // Values from package:logging, which DevTools understands.
  static int _developerLevel(LogLevel level) => switch (level) {
    LogLevel.trace => 300,
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
    LogLevel.fatal => 1200,
  };
}

/// Application logger.
///
/// Every entry is redacted, kept in a bounded in-memory buffer (used by the
/// console and attached to feedback reports) and handed to each [LogSink].
///
/// ```dart
/// Log.info('cart loaded', tag: 'cart');
/// Log.error('checkout failed', error: e, stackTrace: s);
/// ```
///
/// Already using `package:logging`? Forward it in one line:
/// ```dart
/// Logger.root.onRecord.listen(Log.fromLoggingRecord);
/// ```
abstract final class Log {
  static final ListQueue<LogEntry> _buffer = ListQueue<LogEntry>();
  static final List<LogSink> _sinks = <LogSink>[const DeveloperLogSink()];
  static StreamController<LogEntry>? _controller;
  static DebugPrintCallback? _originalDebugPrint;
  static bool _dispatching = false;

  /// Entries below this level are not handed to the sinks. They still reach
  /// the buffer (see [bufferLevel]), so reports keep the debug trail even in
  /// release builds.
  static LogLevel minLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;

  /// Entries below this level are dropped entirely.
  static LogLevel bufferLevel = LogLevel.debug;

  /// Maximum number of entries kept in memory.
  static int capacity = 2000;

  /// Applied to every message, error and stack trace before storage.
  /// See [Redactors] for ready-made ones.
  static List<Redactor> redactors = <Redactor>[
    Redactors.bearerToken,
    Redactors.jwt,
  ];

  /// Current sinks. Defaults to a single [DeveloperLogSink].
  static List<LogSink> get sinks => List<LogSink>.unmodifiable(_sinks);

  /// Entries currently in memory, oldest first.
  static List<LogEntry> get entries => List<LogEntry>.unmodifiable(_buffer);

  /// Emits every entry that was accepted.
  static Stream<LogEntry> get onEntry =>
      (_controller ??= StreamController<LogEntry>.broadcast()).stream;

  /// Adds a sink. Adding the same instance twice is a no-op.
  static void addSink(LogSink sink) {
    if (!_sinks.contains(sink)) {
      _sinks.add(sink);
    }
  }

  /// Removes and closes a sink.
  static Future<void> removeSink(LogSink sink) async {
    if (_sinks.remove(sink)) {
      await sink.close();
    }
  }

  /// Logs at [LogLevel.trace].
  static void trace(Object? message, {String? tag}) =>
      add(_entry(LogLevel.trace, message, tag: tag));

  /// Logs at [LogLevel.debug].
  static void debug(
    Object? message, {
    String? tag,
    Map<String, Object?>? data,
  }) => add(_entry(LogLevel.debug, message, tag: tag, data: data));

  /// Logs at [LogLevel.info].
  static void info(
    Object? message, {
    String? tag,
    Map<String, Object?>? data,
  }) => add(_entry(LogLevel.info, message, tag: tag, data: data));

  /// Logs at [LogLevel.warning].
  static void warning(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    Map<String, Object?>? data,
  }) => add(
    _entry(
      LogLevel.warning,
      message,
      error: error,
      stackTrace: stackTrace,
      tag: tag,
      data: data,
    ),
  );

  /// Logs at [LogLevel.error].
  static void error(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    Map<String, Object?>? data,
  }) => add(
    _entry(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      tag: tag,
      data: data,
    ),
  );

  /// Logs at [LogLevel.fatal].
  static void fatal(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) => add(
    _entry(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      tag: tag,
    ),
  );

  /// Stores [entry] and forwards it to the sinks.
  static void add(LogEntry entry) {
    if (!(entry.level >= bufferLevel)) {
      return;
    }
    _buffer.addLast(entry);
    while (_buffer.length > capacity) {
      _buffer.removeFirst();
    }
    _controller?.add(entry);
    if (!(entry.level >= minLevel)) {
      return;
    }

    // A sink that logs from inside `write` must not recurse into the sinks.
    if (_dispatching) {
      return;
    }
    _dispatching = true;
    try {
      for (final sink in List<LogSink>.of(_sinks)) {
        try {
          final result = sink.write(entry);
          if (result is Future<void>) {
            unawaited(result.catchError(_reportSinkFailure));
          }
        } on Object catch (e) {
          _reportSinkFailure(e);
        }
      }
    } finally {
      _dispatching = false;
    }
  }

  /// Adapter for `package:logging`. The argument is a `LogRecord`; it is
  /// typed as `dynamic` so this package does not depend on `package:logging`.
  ///
  /// ```dart
  /// Logger.root.onRecord.listen(Log.fromLoggingRecord);
  /// ```
  static void fromLoggingRecord(dynamic record) {
    final value = (record.level.value as num).toInt();
    final level = switch (value) {
      < 500 => LogLevel.trace,
      < 800 => LogLevel.debug,
      < 900 => LogLevel.info,
      < 1000 => LogLevel.warning,
      < 1200 => LogLevel.error,
      _ => LogLevel.fatal,
    };
    add(
      _entry(
        level,
        record.message,
        error: record.error,
        stackTrace: record.stackTrace as StackTrace?,
        tag: record.loggerName as String?,
        time: record.time as DateTime?,
      ),
    );
  }

  /// Also records everything printed with `debugPrint` (which Flutter itself
  /// uses for framework errors). Off by default: third-party packages often
  /// print raw payloads.
  static void captureDebugPrint({bool enabled = true}) {
    if (enabled && _originalDebugPrint == null) {
      final original = debugPrint;
      _originalDebugPrint = original;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && !_muteDebugPrint) {
          add(_entry(LogLevel.debug, message, tag: 'print'));
        }
        original(message, wrapWidth: wrapWidth);
      };
    } else if (!enabled && _originalDebugPrint != null) {
      debugPrint = _originalDebugPrint!;
      _originalDebugPrint = null;
    }
  }

  static bool _muteDebugPrint = false;

  /// Runs [body] without recording its `debugPrint` output, for text that is
  /// already in the log under another entry.
  static void withoutDebugPrintCapture(void Function() body) {
    final before = _muteDebugPrint;
    _muteDebugPrint = true;
    try {
      body();
    } finally {
      _muteDebugPrint = before;
    }
  }

  /// Applies [redactors] to [text].
  static String redact(String text) {
    var result = text;
    for (final redactor in redactors) {
      result = redactor(result);
    }
    return result;
  }

  /// Formats [entries] as a text block for reports.
  static String entriesAsText(Iterable<LogEntry> entries) =>
      entries.map((LogEntry e) => e.formatFull()).join('\n');

  /// Empties the in-memory buffer.
  static void clear() => _buffer.clear();

  /// Restores the defaults and closes every sink. Useful in tests.
  static Future<void> reset() async {
    clear();
    captureDebugPrint(enabled: false);
    for (final sink in _sinks) {
      await sink.close();
    }
    _sinks
      ..clear()
      ..add(const DeveloperLogSink());
    minLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;
    bufferLevel = LogLevel.debug;
    capacity = 2000;
    redactors = <Redactor>[Redactors.bearerToken, Redactors.jwt];
    _dispatching = false;
  }

  static LogEntry _entry(
    LogLevel level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    Map<String, Object?>? data,
    DateTime? time,
  }) => LogEntry(
    level: level,
    message: redact(message.toString()),
    error: error,
    stackTrace: stackTrace,
    tag: tag,
    data: data,
    time: time,
  );

  static void _reportSinkFailure(Object error) {
    // Deliberately not logged through the sinks: that is where it failed.
    developer.log('Log sink failed', error: error, name: 'planish');
  }
}
