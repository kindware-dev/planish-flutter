import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planish/planish.dart';

FeedbackReport _report({Uint8List? screenshot}) => FeedbackReport(
  message: 'It broke',
  category: FeedbackCategory.bug,
  screenshot: screenshot,
  error: StateError('bad state'),
  logs: <LogEntry>[LogEntry(level: LogLevel.info, message: 'hello')],
  context: const <String, String>{'os': 'iOS 19'},
  createdAt: DateTime(2026, 1, 2, 3, 4, 5),
  appName: 'Demo',
);

void main() {
  group('HttpFeedbackSender', () {
    test('posts a multipart request with fields and files', () async {
      late http.Request captured;
      final client = MockClient((http.Request r) async {
        captured = r;
        return http.Response('', 201);
      });
      final sender = HttpFeedbackSender(
        Uri.parse('https://example.com/feedback'),
        headers: const <String, String>{'x-api-key': 'k'},
        client: client,
      );

      final result = await sender.send(_report(screenshot: Uint8List(4)));

      expect(result, isA<FeedbackSent>());
      expect(captured.headers['x-api-key'], 'k');
      expect(
        captured.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      final body = utf8.decode(captured.bodyBytes, allowMalformed: true);
      expect(body, contains('name="message"\r\n\r\nIt broke'));
      expect(body, contains('name="category"\r\n\r\nbug'));
      expect(body, contains('filename="screenshot.png"'));
      expect(body, contains('filename="logs.txt"'));
      expect(body, contains('"os":"iOS 19"'));
    });

    test('non-2xx becomes FeedbackFailed with the server message', () async {
      final sender = HttpFeedbackSender(
        Uri.parse('https://example.com/feedback'),
        client: MockClient((_) async => http.Response('nope', 500)),
      );
      final result = await sender.send(_report());
      expect(result, isA<FeedbackFailed>());
      expect((result as FeedbackFailed).message, 'Server responded 500: nope');
    });

    test('network failure becomes FeedbackFailed', () async {
      final sender = HttpFeedbackSender(
        Uri.parse('https://example.com/feedback'),
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final result = await sender.send(_report());
      expect((result as FeedbackFailed).message, 'offline');
    });
  });

  group('PlanishCloudSender', () {
    test('posts to <server>/v1/reports with the key as bearer token', () async {
      late http.Request captured;
      final sender = PlanishCloudSender(
        'bs_test',
        server: 'https://inbox.example.com',
        client: MockClient((http.Request r) async {
          captured = r;
          return http.Response('', 201);
        }),
      );

      final result = await sender.send(_report());

      expect(result, isA<FeedbackSent>());
      expect(captured.url.toString(), 'https://inbox.example.com/v1/reports');
      expect(captured.headers['authorization'], 'Bearer bs_test');
    });

    test('keeps a server path, with or without a trailing slash', () {
      for (final server in [
        'https://x.dev/planish',
        'https://x.dev/planish/',
      ]) {
        expect(
          PlanishCloudSender('k', server: server).endpoint.toString(),
          'https://x.dev/planish/v1/reports',
        );
      }
    });

    test('a refused key surfaces the server message', () async {
      final sender = PlanishCloudSender(
        'bs_revoked',
        server: 'https://inbox.example.com',
        client: MockClient((_) async => http.Response('Invalid key', 401)),
      );
      final result = await sender.send(_report());
      expect(
        (result as FeedbackFailed).message,
        'Server responded 401: Invalid key',
      );
    });
  });

  group('CallbackFeedbackSender', () {
    test('completed callback is sent, thrown error is failed', () async {
      expect(
        await const CallbackFeedbackSender(_noop).send(_report()),
        isA<FeedbackSent>(),
      );
      final failed = await CallbackFeedbackSender(
        (_) => throw Exception('db down'),
      ).send(_report());
      expect((failed as FeedbackFailed).message, 'Exception: db down');
    });
  });

  test('FeedbackReport.toPlainText contains every section', () {
    final text = _report().toPlainText();
    expect(text, contains('Demo feedback report'));
    expect(text, contains('Category: Bug (bug)'));
    expect(text, contains('It broke'));
    expect(text, contains('Bad state: bad state'));
    expect(text, contains('os: iOS 19'));
    expect(text, contains('Logs (1):'));
  });
}

Future<void> _noop(FeedbackReport _) async {}
