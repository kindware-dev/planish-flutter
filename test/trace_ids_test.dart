import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/network/trace_ids.dart';

NetworkCall _call(
  int second, {
  int? status = 200,
  String? error,
  Map<String, String> response = const {},
}) => NetworkCall(
  method: 'GET',
  url: 'https://api.test/$second',
  startedAt: DateTime(2026, 11, 5, 12, 0, second),
  duration: const Duration(milliseconds: 40),
  statusCode: status,
  error: error,
  responseHeaders: response,
);

void main() {
  group('readIds, shared cases', () {
    final fixtures =
        jsonDecode(
              File('test/fixtures/trace-ids.fixtures.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    for (final c in (fixtures['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        Map<String, String> headers(String key) =>
            (c[key] as Map).cast<String, String>();
        final ids = readIds(
          headers('request'),
          headers('response'),
          extra: ((c['extra'] as List?) ?? const []).cast<String>(),
        );
        expect(ids.toJson(), c['flutterIds'] ?? c['ids']);
      });
    }
  });

  group('pickRequests', () {
    test('nothing without an error or a failed call', () {
      expect(pickRequests([_call(1), _call(2)]), isEmpty);
    });

    test('calls in the 10 s before the first failure, plus every failure', () {
      final picked = pickRequests([
        _call(0),
        _call(5),
        _call(14),
        _call(15, status: 500),
        _call(20),
        _call(40, error: 'timeout'),
      ]);
      expect(picked.map((r) => r.url.split('/').last), ['5', '14', '15', '40']);
    });

    test('the first uncaught error is the reference', () {
      final picked = pickRequests([
        _call(0),
        _call(30),
      ], firstErrorAt: DateTime(2026, 11, 5, 12, 0, 31));
      expect(picked.map((r) => r.url.split('/').last), ['30']);
    });

    test('at most 20, failures kept first', () {
      final calls = [
        for (var i = 0; i < 10; i++) _call(i),
        for (var i = 10; i < 32; i++) _call(i, status: 500),
      ];
      final picked = pickRequests(calls);
      expect(picked, hasLength(20));
      expect(picked.every((r) => r.status == 500), isTrue);
      expect(picked.map((r) => r.url.split('/').last), [
        for (var i = 10; i < 30; i++) '$i',
      ]);
    });

    test('entries carry the ids and a local time with its offset', () {
      final call = NetworkCall(
        method: 'POST',
        url: 'https://api.test/orders',
        startedAt: DateTime(2026, 11, 5, 12),
        duration: const Duration(milliseconds: 85),
        statusCode: 502,
        ids: const CallIds(
          requestId: 'req_1',
          traceId: 'abc',
          state: IdsState.found,
        ),
      );
      final json = pickRequests([call]).single.toJson();
      expect(json, <String, Object?>{
        'at': offsetIso(call.startedAt),
        'method': 'POST',
        'url': 'https://api.test/orders',
        'status': 502,
        'ms': 85,
        'requestId': 'req_1',
        'traceId': 'abc',
        'idsState': 'found',
      });
      expect(
        json['at'],
        matches(RegExp(r'^2026-11-05T12:00:00\.000[+-]\d\d:\d\d$')),
      );
    });
  });

  group('NetworkLog.record', () {
    setUp(NetworkLog.clear);
    tearDown(() => NetworkLog.traceHeaders = const <String>[]);

    test('reads the ids and adds them to the http log line', () {
      NetworkLog.traceHeaders = ['x-shop-id'];
      NetworkLog.record(_call(1, response: {'X-Shop-Id': 'shop_9'}));
      expect(NetworkLog.calls.single.ids.requestId, 'shop_9');
      expect(Log.entries.last.data?['requestId'], 'shop_9');
    });

    test('a header listed as sensitive gives no id', () {
      final before = NetworkLog.sensitiveHeaders;
      NetworkLog.sensitiveHeaders = {...before, 'x-request-id'};
      addTearDown(() => NetworkLog.sensitiveHeaders = before);
      NetworkLog.record(_call(1, response: {'x-request-id': 'secret'}));
      expect(NetworkLog.calls.single.ids.state, IdsState.absent);
    });
  });

  test('toJson carries requests only when there are some', () {
    FeedbackReport build(List<BackendRequest> requests) => FeedbackReport(
      message: 'm',
      createdAt: DateTime(2026),
      appName: 'A',
      requests: requests,
    );
    expect(build(const []).toJson().containsKey('requests'), isFalse);
    final r = BackendRequest.fromCall(_call(1, status: 500));
    expect(build([r]).toJson()['requests'], [r.toJson()]);
    expect(build([r]).copyWith(message: 'n').requests, [r]);
  });

  test('text and Markdown list the requests with their ids', () {
    final report = FeedbackReport(
      message: 'm',
      createdAt: DateTime(2026),
      appName: 'A',
      requests: [
        BackendRequest(
          at: DateTime(2026),
          method: 'POST',
          url: 'https://api.test/pay',
          status: 500,
          ms: 85,
          ids: const CallIds(requestId: 'req_1', state: IdsState.found),
        ),
        BackendRequest(
          at: DateTime(2026),
          method: 'GET',
          url: 'https://api.test/me',
          ms: 9,
        ),
      ],
    );
    expect(
      report.toPlainText(),
      contains(
        'Backend requests:\n'
        'POST https://api.test/pay 500 (85 ms) · request id req_1\n'
        'GET https://api.test/me failed (9 ms) · no request id',
      ),
    );
    expect(
      report.toMarkdown(),
      contains('- POST https://api.test/pay 500 (85 ms) · request id `req_1`'),
    );
  });
}
