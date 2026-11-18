import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';

void main() {
  test('queryParameters hides only the named parameters', () {
    final r = Redactors.queryParameters(<String>{'token'});
    expect(
      r('https://api.example.com/v1/items?token=abc&page=2'),
      'https://api.example.com/v1/items?token=%3Credacted%3E&page=2',
    );
    expect(r('plain text, not a url'), 'plain text, not a url');
  });

  test('creditCard matches spaced and dashed numbers', () {
    expect(
      Redactors.creditCard('card 4111 1111 1111 1111 ok'),
      'card <card> ok',
    );
    expect(Redactors.creditCard('order 12345'), 'order 12345');
  });

  test('NetworkLog redacts headers and query parameters on record', () {
    NetworkLog.clear();
    NetworkLog.sensitiveHeaders = PrivacyConfig.defaultSensitiveHeaders;
    NetworkLog.sensitiveQueryParameters =
        PrivacyConfig.defaultSensitiveQueryParameters;
    NetworkLog.record(
      NetworkCall(
        method: 'GET',
        url: 'https://x.io/a?api_key=secret&q=1',
        startedAt: DateTime(2026),
        duration: Duration.zero,
        requestHeaders: const <String, String>{
          'Authorization': 'Bearer x',
          'Accept': '*/*',
        },
        requestBody: 'a' * 5000,
        statusCode: 200,
      ),
    );
    final c = NetworkLog.calls.single;
    expect(c.url, contains('api_key=%3Credacted%3E'));
    expect(c.url, contains('q=1'));
    expect(c.requestHeaders['Authorization'], '<redacted>');
    expect(c.requestHeaders['Accept'], '*/*');
    expect(c.requestBody!.length, lessThan(5000));
    expect(c.requestBody, endsWith('(904 more)'));
  });

  test('NetworkLog keeps the newest calls only', () {
    NetworkLog.clear();
    NetworkLog.capacity = 2;
    for (var i = 0; i < 3; i++) {
      NetworkLog.record(
        NetworkCall(
          method: 'GET',
          url: 'https://x.io/$i',
          startedAt: DateTime(2026),
          duration: Duration.zero,
        ),
      );
    }
    expect(NetworkLog.calls.map((NetworkCall c) => c.url), <String>[
      'https://x.io/2',
      'https://x.io/1',
    ]);
    NetworkLog.capacity = 100;
  });
}
