import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/errors/error_handlers.dart';

void main() {
  setUp(() async {
    NetworkLog.clear();
    await Log.reset();
    await PersistedLogs.reset();
  });

  test('LogEntry survives a JSON round trip', () {
    final entry = LogEntry(
      level: LogLevel.warning,
      message: 'slow',
      tag: 'http',
      error: const FormatException('bad'),
      stackTrace: StackTrace.fromString('#0 main (a.dart:1:1)'),
      data: <String, Object?>{'status': 500, 'ms': 12},
    );
    final back = LogEntry.fromJson(
      jsonDecode(jsonEncode(entry.toJson())) as Map<String, Object?>,
    );
    expect(back.level, LogLevel.warning);
    expect(back.message, 'slow');
    expect(back.tag, 'http');
    expect(back.errorText, 'FormatException: bad');
    expect(back.stackTrace.toString(), '#0 main (a.dart:1:1)');
    expect(back.data, <String, Object?>{'status': 500, 'ms': 12});
    expect(back.time, entry.time);
  });

  test('HTTP calls land in the log timeline, failures as warnings', () async {
    final client = LoggingHttpClient(
      MockClient(
        (http.Request r) async => r.url.path == '/ok'
            ? http.Response('{}', 200)
            : http.Response('nope', 503),
      ),
    );
    await client.get(Uri.parse('https://api.example.com/ok?token=x'));
    await client.get(Uri.parse('https://api.example.com/down'));

    final http_ = Log.entries.where((LogEntry e) => e.tag == 'http').toList();
    expect(http_, hasLength(2));
    expect(http_[0].level, LogLevel.debug);
    expect(http_[0].message, startsWith('GET https://api.example.com/ok'));
    expect(http_[0].message, isNot(contains('token=x')));
    expect(http_[0].data?['status'], 200);
    expect(http_[1].level, LogLevel.warning);
    expect(http_[1].data?['status'], 503);
  });

  test('binary responses pass through without a recorded body', () async {
    final client = LoggingHttpClient(
      MockClient(
        (http.Request r) async => http.Response.bytes(
          List<int>.filled(10, 1),
          200,
          headers: {'content-type': 'application/octet-stream'},
        ),
      ),
    );
    final res = await client.get(Uri.parse('https://api.example.com/file'));
    expect(res.bodyBytes, hasLength(10));
    expect(NetworkLog.calls.single.responseBody, isNull);
    expect(NetworkLog.calls.single.statusCode, 200);
  });

  test('recordBodies false keeps bodies out of the records', () async {
    NetworkLog.recordBodies = false;
    addTearDown(() => NetworkLog.recordBodies = true);
    final client = LoggingHttpClient(
      MockClient(
        (http.Request r) async => http.Response(
          '{"a":1}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final res = await client.post(
      Uri.parse('https://api.example.com/x'),
      body: 'secret',
    );
    expect(res.body, '{"a":1}');
    expect(NetworkLog.calls.single.responseBody, isNull);
    expect(NetworkLog.calls.single.requestBody, isNull);
  });

  test('Flutter error details keep the library and the context', () {
    final text = ErrorHandlers.describe(
      FlutterErrorDetails(
        exception: StateError('boom'),
        library: 'widgets library',
        context: ErrorDescription('building MyWidget'),
        informationCollector: () => <DiagnosticsNode>[
          ErrorDescription('The relevant error-causing widget was: MyWidget'),
        ],
      ),
    );
    expect(text, contains('Bad state: boom'));
    expect(text, contains('library: widgets library'));
    expect(text, contains('while: building MyWidget'));
    expect(text, contains('error-causing widget was: MyWidget'));
  });

  test('the brief summarises errors, background time and context', () {
    final now = DateTime.now();
    final report = FeedbackReport(
      message: 'sound stopped',
      createdAt: now,
      appName: 'BIP',
      category: FeedbackCategory.bug,
      context: <String, String>{
        'app.version': '1.0.0+1',
        'build.mode': 'release',
        'screen': 'RunRoute',
        'app.lifecycle': 'resumed',
        'app.previousExit': 'abnormal',
      },
      logs: <LogEntry>[
        LogEntry(
          level: LogLevel.info,
          message: 'paused',
          tag: 'lifecycle',
          time: now.subtract(const Duration(seconds: 90)),
        ),
        LogEntry(
          level: LogLevel.warning,
          message: 'play skipped',
          tag: 'audio',
          time: now.subtract(const Duration(seconds: 70)),
        ),
        LogEntry(
          level: LogLevel.info,
          message: 'resumed',
          tag: 'lifecycle',
          time: now.subtract(const Duration(seconds: 50)),
        ),
      ],
      analysisNotes: 'tag audio = AudioRunSignals',
    );
    final md = report.toMarkdown();
    expect(md, startsWith('# BIP 1.0.0+1 (release) — bug — RunRoute — '));
    expect(md, contains('**Message**: sound stopped'));
    expect(md, contains('0 error(s), 1 warning(s) in the 3 min'));
    expect(md, contains('last warning: `'));
    expect(md, contains('(40s in background)'));
    expect(md, contains('previous launch ended while in the foreground'));
    expect(md, contains('## Notes for analysis\ntag audio = AudioRunSignals'));
    expect(md, contains('## Timeline (3 of 3 entries, last 3 min)'));
    expect(report.toJson()['schemaVersion'], 1);
    expect(report.toJson()['logs'], isA<List<Map<String, Object?>>>());
    expect(report.id, hasLength(32));
  });

  test(
    'persisted logs come back on the next launch with the exit kind',
    () async {
      final dir = await Directory.systemTemp.createTemp('ffl_');
      addTearDown(() => dir.delete(recursive: true));

      await PersistedLogs.open(directory: dir);
      Log.info('before the crash', tag: 't');
      await PersistedLogs.onLifecycle(AppLifecycleState.paused);
      await PersistedLogs.onLifecycle(AppLifecycleState.resumed);
      // No close(): the app "crashed" while in the foreground.

      await PersistedLogs.reset();
      await Log.reset();
      await PersistedLogs.open(directory: dir);
      expect(PersistedLogs.previousExit, PreviousExit.abnormal);
      expect(
        PersistedLogs.previousSession.map((LogEntry e) => e.message),
        contains('before the crash'),
      );
      expect(Log.entries, isEmpty, reason: 'previous logs stay separate');

      await PersistedLogs.onLifecycle(AppLifecycleState.paused);
      await PersistedLogs.reset();
      await PersistedLogs.open(directory: dir);
      expect(PersistedLogs.previousExit, PreviousExit.clean);
    },
  );
}
