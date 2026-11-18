import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';

class _RecordingSink extends LogSink {
  final List<LogEntry> entries = <LogEntry>[];

  @override
  void write(LogEntry entry) => entries.add(entry);
}

class _ThrowingSink extends LogSink {
  @override
  void write(LogEntry entry) => throw StateError('sink broken');
}

class _AsyncFailingSink extends LogSink {
  @override
  Future<void> write(LogEntry entry) async =>
      throw StateError('async sink broken');
}

class _ReentrantSink extends LogSink {
  int writes = 0;

  @override
  void write(LogEntry entry) {
    writes++;
    Log.info('from inside a sink');
  }
}

void main() {
  navigationObserverTests();
  setUp(Log.reset);

  test('entries below bufferLevel are dropped', () {
    Log.bufferLevel = LogLevel.warning;
    Log.info('ignored');
    Log.warning('kept');
    expect(Log.entries.map((LogEntry e) => e.message), <String>['kept']);
  });

  test('entries below minLevel are buffered but skip the sinks', () {
    final sink = _RecordingSink();
    Log.addSink(sink);
    Log.minLevel = LogLevel.warning;
    Log.debug('buffered only');
    Log.warning('both');
    expect(Log.entries.map((LogEntry e) => e.message), <String>[
      'buffered only',
      'both',
    ]);
    expect(sink.entries.map((LogEntry e) => e.message), <String>['both']);
  });

  test('buffer is bounded and keeps the newest entries', () {
    Log.capacity = 3;
    for (var i = 0; i < 10; i++) {
      Log.info('m$i');
    }
    expect(Log.entries.map((LogEntry e) => e.message), <String>[
      'm7',
      'm8',
      'm9',
    ]);
  });

  test('every sink receives the entry', () {
    final a = _RecordingSink();
    final b = _RecordingSink();
    Log.addSink(a);
    Log.addSink(b);
    Log.error('boom', error: Exception('x'), tag: 'test');
    expect(a.entries.single.message, 'boom');
    expect(b.entries.single.tag, 'test');
    expect(b.entries.single.error, isA<Exception>());
  });

  test('a throwing sink does not stop the others', () {
    final good = _RecordingSink();
    Log.addSink(_ThrowingSink());
    Log.addSink(good);
    expect(() => Log.info('still delivered'), returnsNormally);
    expect(good.entries, hasLength(1));
  });

  test(
    'a sink whose future fails does not surface as an uncaught error',
    () async {
      Log.addSink(_AsyncFailingSink());
      await runZonedGuarded(() async {
        Log.info('x');
        await Future<void>.delayed(Duration.zero);
      }, (Object e, StackTrace _) => fail('uncaught: $e'));
    },
  );

  test('logging from inside a sink does not recurse', () {
    final sink = _ReentrantSink();
    Log.addSink(sink);
    Log.info('outer');
    expect(sink.writes, 1);
    expect(Log.entries, hasLength(2));
  });

  test('default redactors hide bearer tokens and JWTs', () {
    Log.info('Authorization: Bearer abc.def-ghi');
    Log.info('token eyJhbGciOi.eyJzdWIiOi.SflKxwRJSM');
    expect(Log.entries[0].message, 'Authorization: Bearer <redacted>');
    expect(Log.entries[1].message, 'token <jwt>');
  });

  test('custom redactors apply to errors and stack traces in formatFull', () {
    Log.redactors.add(Redactors.email);
    Log.error('failed', error: Exception('user john@example.com'));
    final text = Log.entries.single.formatFull();
    expect(text, contains('<email>'));
    expect(text, isNot(contains('john@')));
  });

  test('captureDebugPrint records prints and can be turned off', () {
    Log.captureDebugPrint();
    debugPrint('hello');
    Log.captureDebugPrint(enabled: false);
    debugPrint('not recorded');
    expect(Log.entries.map((LogEntry e) => e.message), <String>['hello']);
  });

  test('fromLoggingRecord maps package:logging levels', () {
    Log.fromLoggingRecord(_FakeRecord(level: _FakeLevel(900), message: 'warn'));
    Log.fromLoggingRecord(
      _FakeRecord(level: _FakeLevel(1000), message: 'severe'),
    );
    expect(Log.entries[0].level, LogLevel.warning);
    expect(Log.entries[1].level, LogLevel.error);
    expect(Log.entries[1].tag, 'app.net');
  });

  test('format is single line and formatFull adds the stack trace', () {
    Log.error('bad', stackTrace: StackTrace.fromString('#0 main'), tag: 't');
    final e = Log.entries.single;
    expect(
      e.format(),
      matches(RegExp(r'^\d\d:\d\d:\d\d\.\d{3} ERROR \[t\] bad$')),
    );
    expect(e.formatFull(), contains('#0 main'));
  });
}

class _FakeLevel {
  _FakeLevel(this.value);
  final int value;
}

class _FakeRecord {
  _FakeRecord({required this.level, required this.message});
  final _FakeLevel level;
  final String message;
  final Object? error = null;
  final StackTrace? stackTrace = null;
  final String loggerName = 'app.net';
  final DateTime time = DateTime(2026);
}

class _FakeRoute extends PageRoute<void> {
  _FakeRoute(String? name) : super(settings: RouteSettings(name: name));

  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => Duration.zero;
  @override
  Widget buildPage(BuildContext c, Animation<double> a, Animation<double> b) =>
      const SizedBox();
}

void navigationObserverTests() {
  setUp(Log.reset);

  test('named page routes are logged and the current screen tracked', () {
    final observer = LoggingNavigatorObserver();
    observer.didPush(_FakeRoute('/home'), null);
    observer.didPush(_FakeRoute(null), _FakeRoute('/home'));
    observer.didPush(_FakeRoute('/settings'), _FakeRoute('/home'));
    observer.didPop(_FakeRoute('/settings'), _FakeRoute('/home'));

    expect(observer.currentRoute, '/home');
    expect(Log.entries.map((e) => e.message), [
      'Opened /home',
      'Opened /settings',
      'Back to /home',
    ]);
    expect(Log.entries.first.tag, 'nav');
  });
}
