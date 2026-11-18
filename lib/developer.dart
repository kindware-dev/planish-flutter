/// Drop-in for `dart:developer`'s `log`, routed through [Log] so the lines
/// end up in the console and in feedback reports.
///
/// Replace `import 'dart:developer';` with
/// `import 'package:planish/developer.dart';` and keep the
/// existing `log('...')` calls. `name` becomes the tag and `level` follows the
/// `package:logging` scale (900 = warning, 1000 = error).
library;

import 'dart:async';

import 'package:planish/src/log/log.dart';

export 'src/log/log.dart' show Log, LogEntry, LogLevel;

/// Same signature as `dart:developer`'s `log`.
void log(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
}) {
  Log.add(
    LogEntry(
      level: switch (level) {
        < 800 => LogLevel.debug,
        < 900 => LogLevel.info,
        < 1000 => LogLevel.warning,
        < 1200 => LogLevel.error,
        _ => LogLevel.fatal,
      },
      message: Log.redact(message),
      error: error,
      stackTrace: stackTrace,
      tag: name.isEmpty ? null : name,
      time: time,
    ),
  );
}
