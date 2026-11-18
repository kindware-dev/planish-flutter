import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planish/src/log/log.dart';

/// How the previous launch of the app ended.
enum PreviousExit {
  /// First launch, or persistence was off.
  unknown,

  /// The app was in the background or had detached: a normal end.
  clean,

  /// The app was in the foreground when it stopped: a crash, an OS kill under
  /// memory pressure, or a force quit.
  abnormal,
}

/// Keeps the log buffer on disk so a report can include what happened before
/// a crash. One NDJSON file per launch, batched writes, bounded size, and a
/// small marker telling whether the previous launch ended in the foreground.
///
/// Files live under the application support directory, `planish/`.
class PersistedLogs extends LogSink {
  PersistedLogs._(this._dir, {required this.maxBytes});

  static PersistedLogs? _instance;

  /// Logs of the previous launch, oldest first. Empty until [open] has run.
  static List<LogEntry> previousSession = const <LogEntry>[];

  /// How the previous launch ended.
  static PreviousExit previousExit = PreviousExit.unknown;

  final Directory _dir;

  /// Size above which the current file is cut down to its newest half.
  final int maxBytes;

  final List<LogEntry> _pending = <LogEntry>[];
  Timer? _timer;
  Future<void>? _inFlight;
  bool _closed = false;

  File get _current => File('${_dir.path}/current.ndjson');
  File get _marker => File('${_dir.path}/session.json');

  /// Reads the previous launch, records the start of this one and starts
  /// persisting [Log]. Never throws; a failure leaves persistence off.
  static Future<void> open({
    int maxBytes = 512 * 1024,
    Directory? directory,
  }) async {
    if (kIsWeb || _instance != null) {
      return;
    }
    try {
      final base = directory ?? await getApplicationSupportDirectory();
      final dir = await Directory(
        '${base.path}/planish',
      ).create(recursive: true);
      final sink = PersistedLogs._(dir, maxBytes: maxBytes);
      await sink._readPrevious();
      await sink._current.writeAsString('');
      await sink.markLifecycle(AppLifecycleState.resumed);
      _instance = sink;
      // Entries logged while this was loading (the first screen, typically).
      sink._pending.addAll(Log.entries);
      Log.addSink(sink);
      await sink.flush();
    } on Object catch (e) {
      Log.warning('Log persistence unavailable', error: e, tag: 'feedback');
    }
  }

  /// Records the lifecycle state and writes pending entries when the app
  /// leaves the foreground.
  static Future<void> onLifecycle(AppLifecycleState state) async {
    final sink = _instance;
    if (sink == null) {
      return;
    }
    await sink.markLifecycle(state);
    if (state != AppLifecycleState.resumed) {
      await sink.flush();
    }
  }

  Future<void> _readPrevious() async {
    if (await _marker.exists()) {
      try {
        final state = jsonDecode(await _marker.readAsString());
        final foreground = state is Map && state['state'] == 'resumed';
        previousExit = foreground ? PreviousExit.abnormal : PreviousExit.clean;
      } on Object {
        // An unreadable marker says nothing about the last exit; it must
        // not turn persistence off, or it would stay unreadable for good.
        previousExit = PreviousExit.unknown;
      }
    }
    if (!await _current.exists()) {
      return;
    }
    final entries = <LogEntry>[];
    for (final line in const LineSplitter().convert(
      await _current.readAsString(),
    )) {
      try {
        entries.add(
          LogEntry.fromJson(jsonDecode(line) as Map<String, Object?>),
        );
      } on Object {
        // A line cut short by the crash itself.
      }
    }
    previousSession = List<LogEntry>.unmodifiable(entries);
  }

  // Lifecycle changes come in bursts (inactive, hidden, paused): writes are
  // chained, and each replaces the file whole, so two never mix.
  Future<void> _markerWrite = Future<void>.value();

  Future<void> markLifecycle(AppLifecycleState state) =>
      _markerWrite = _markerWrite.then((_) async {
        try {
          final tmp = File('${_marker.path}.tmp');
          await tmp.writeAsString(
            jsonEncode({
              'state': state.name,
              'at': DateTime.now().toIso8601String(),
            }),
            flush: true,
          );
          await tmp.rename(_marker.path);
        } on Object catch (e) {
          developerWarn(e);
        }
      });

  @override
  void write(LogEntry entry) {
    if (_closed) {
      return;
    }
    _pending.add(entry);
    if (_pending.length >= 50) {
      unawaited(flush());
    } else {
      _timer ??= Timer(const Duration(seconds: 2), () => unawaited(flush()));
    }
  }

  /// Appends pending entries to the file. A call made while a write is in
  /// progress waits for it, then writes what arrived in the meantime, so a
  /// flush on `paused` never leaves the newest lines behind.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    while (_inFlight != null) {
      await _inFlight;
    }
    if (_pending.isEmpty) {
      return;
    }
    final batch = List<LogEntry>.of(_pending);
    _pending.clear();
    final write = _write(batch);
    _inFlight = write;
    try {
      await write;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _write(List<LogEntry> batch) async {
    try {
      await _current.writeAsString(
        '${batch.map((LogEntry e) => jsonEncode(e.toJson())).join('\n')}\n',
        mode: FileMode.append,
        flush: true,
      );
      if (await _current.length() > maxBytes) {
        await _trim();
      }
    } on Object catch (e) {
      developerWarn(e);
    }
  }

  // Keeps the newest half of [maxBytes], starting on a whole line.
  Future<void> _trim() async {
    final text = await _current.readAsString();
    var kept = text.substring(math.max(0, text.length - maxBytes ~/ 2));
    final newline = kept.indexOf('\n');
    if (newline >= 0 && newline < kept.length - 1) {
      kept = kept.substring(newline + 1);
    }
    await _current.writeAsString(kept);
  }

  @override
  Future<void> close() async {
    _closed = true;
    await flush();
    if (identical(_instance, this)) {
      _instance = null;
    }
  }

  /// Forgets the previous session and the open instance. For tests.
  @visibleForTesting
  static Future<void> reset() async {
    await _instance?.close();
    _instance = null;
    previousSession = const <LogEntry>[];
    previousExit = PreviousExit.unknown;
  }

  static void developerWarn(Object error) =>
      debugPrint('planish: log persistence failed: $error');
}
