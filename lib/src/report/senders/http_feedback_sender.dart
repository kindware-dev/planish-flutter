import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:planish/src/report/feedback_report.dart';

/// Posts the report as `multipart/form-data` to your backend.
///
/// Fields: `id`, `appName`, `createdAt`, `message`, `category`, `error`,
/// `stackTrace`, `context` (JSON object) and `report` (the full JSON, see
/// `FeedbackReport.toJson`). Files: `screenshot` (image/png), `logs`
/// (text/plain), `brief` (`brief.md`, see `FeedbackReport.toMarkdown`) and
/// one file per extra attachment, named after the attachment.
///
/// `id` is stable across retries of the same report: deduplicate on it.
///
/// Any 2xx response counts as sent.
class HttpFeedbackSender implements FeedbackSender {
  HttpFeedbackSender(
    this.url, {
    this.headers = const {},
    this.timeout = const Duration(seconds: 30),
    http.Client? client,
  }) : _client = client;

  final Uri url;

  /// Extra headers, e.g. an API key for your own backend.
  final Map<String, String> headers;

  final Duration timeout;

  final http.Client? _client;

  @override
  Future<FeedbackSendResult> send(FeedbackReport report) async {
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..fields['id'] = report.id
      ..fields['appName'] = report.appName
      ..fields['createdAt'] = report.createdAt.toIso8601String()
      ..fields['message'] = report.message
      ..fields['context'] = jsonEncode(report.context)
      ..fields['report'] = jsonEncode(report.toJson());
    request.fields['source'] = report.source.name;
    if (report.relatedTo != null) {
      request.fields['relatedTo'] = report.relatedTo!;
    }
    if (report.email != null) {
      request.fields['email'] = report.email!;
    }
    if (report.category != null) {
      request.fields['category'] = report.category!.id;
    }
    if (report.errorText != null) {
      request.fields['error'] = report.errorText!;
    }
    if (report.stackTraceText != null) {
      request.fields['stackTrace'] = report.stackTraceText!;
    }
    if (report.screenshot != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'screenshot',
          report.screenshot!,
          filename: 'screenshot.png',
        ),
      );
    }
    if (report.logs.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromString(
          'logs',
          report.logsAsText,
          filename: 'logs.txt',
        ),
      );
    }
    request.files.add(
      http.MultipartFile.fromString(
        'brief',
        report.toMarkdown(),
        filename: 'brief.md',
      ),
    );
    for (final a in report.attachments) {
      request.files.add(
        http.MultipartFile.fromBytes(a.name, a.bytes, filename: a.name),
      );
    }

    final client = _client ?? http.Client();
    try {
      final response = await client.send(request).timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const FeedbackSent();
      }
      final body = await response.stream.bytesToString();
      return FeedbackFailed(
        'Server responded ${response.statusCode}${body.isEmpty ? '' : ': ${_short(body)}'}',
      );
    } on TimeoutException {
      return const FeedbackFailed('The server did not respond in time.');
    } on http.ClientException catch (e, s) {
      return FeedbackFailed(e.message, error: e, stackTrace: s);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  static String _short(String s) =>
      s.length > 200 ? '${s.substring(0, 200)}…' : s;
}
