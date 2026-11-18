import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:planish/src/config.dart';
import 'package:planish/src/log/log.dart';
import 'package:planish/src/log/redaction.dart';
import 'package:planish/src/network/trace_ids.dart';

/// One recorded HTTP call.
@immutable
class NetworkCall {
  /// Creates a call record.
  const NetworkCall({
    required this.method,
    required this.url,
    required this.startedAt,
    required this.duration,
    this.requestHeaders = const {},
    this.requestBody,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBody,
    this.error,
    this.ids = const CallIds(),
  });

  final String method;

  /// URL with sensitive query parameters already hidden.
  final String url;

  final DateTime startedAt;

  final Duration duration;

  /// Request headers with sensitive values hidden.
  final Map<String, String> requestHeaders;

  /// Request body, truncated. Null for streamed or binary bodies.
  final String? requestBody;

  /// Status code, null when the request failed before a response.
  final int? statusCode;

  /// Response headers.
  final Map<String, String> responseHeaders;

  /// Response body, truncated. Null for binary bodies.
  final String? responseBody;

  /// Error text when the request failed.
  final String? error;

  /// Request and trace ids, read by [NetworkLog.record].
  final CallIds ids;

  /// 2xx.
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  /// Failed or 4xx/5xx.
  bool get isFailure =>
      error != null || (statusCode != null && statusCode! >= 400);

  /// `GET https://... 200 (123 ms)`.
  String get summary {
    final status = statusCode?.toString() ?? (error == null ? '-' : 'failed');
    return '$method $url $status (${duration.inMilliseconds} ms)';
  }
}

/// In-memory list of recent HTTP calls. Nothing is persisted.
abstract final class NetworkLog {
  static final ListQueue<NetworkCall> _calls = ListQueue<NetworkCall>();
  static StreamController<void>? _controller;

  /// Maximum number of calls kept.
  static int capacity = 100;

  /// Maximum body length kept per direction, in characters.
  static int maxBodyLength = 4096;

  /// Keep request and response bodies in the records. Text responses are then
  /// read into memory before being handed to the caller; set this to false
  /// for apps that move large payloads.
  static bool recordBodies = true;

  /// Header names hidden from records. `Planish.init` applies
  /// `PrivacyConfig.sensitiveHeaders`.
  static Set<String> sensitiveHeaders = PrivacyConfig.defaultSensitiveHeaders;

  /// Query parameter names hidden from recorded URLs. `Planish.init`
  /// applies `PrivacyConfig.sensitiveQueryParameters`.
  static Set<String> sensitiveQueryParameters =
      PrivacyConfig.defaultSensitiveQueryParameters;

  /// Extra header names read as request ids. `Planish.init` applies
  /// `PrivacyConfig.traceHeaders`.
  static List<String> traceHeaders = const <String>[];

  /// Recorded calls, newest first.
  static List<NetworkCall> get calls => List<NetworkCall>.unmodifiable(_calls);

  /// Fires after every change.
  static Stream<void> get onChange =>
      (_controller ??= StreamController<void>.broadcast()).stream;

  /// Records a call and adds its one-line summary to [Log] (tag `http`),
  /// so reports show it in sequence with the other events. Headers and URL
  /// are redacted here, so callers can pass raw values.
  static void record(NetworkCall call) {
    final redactUrl = Redactors.queryParameters(sensitiveQueryParameters);
    final url = redactUrl(call.url);
    final requestHeaders = redactHeaders(call.requestHeaders, sensitiveHeaders);
    final responseHeaders = redactHeaders(
      call.responseHeaders,
      sensitiveHeaders,
    );
    final ids = readIds(requestHeaders, responseHeaders, extra: traceHeaders);
    final data = <String, Object?>{
      'method': call.method,
      'url': url,
      if (call.statusCode != null) 'status': call.statusCode,
      'ms': call.duration.inMilliseconds,
      if (call.error != null) 'error': call.error,
      if (ids.requestId != null) 'requestId': ids.requestId,
      if (ids.traceId != null) 'traceId': ids.traceId,
    };
    final line =
        '${call.method} $url ${call.statusCode ?? 'failed'} (${call.duration.inMilliseconds} ms)';
    if (call.isFailure) {
      Log.warning(
        call.error == null ? line : '$line ${call.error}',
        tag: 'http',
        data: data,
      );
    } else {
      Log.debug(line, tag: 'http', data: data);
    }
    _calls.addFirst(
      NetworkCall(
        method: call.method,
        url: url,
        startedAt: call.startedAt,
        duration: call.duration,
        requestHeaders: requestHeaders,
        requestBody: _truncate(call.requestBody),
        statusCode: call.statusCode,
        responseHeaders: responseHeaders,
        responseBody: _truncate(call.responseBody),
        error: call.error,
        ids: ids,
      ),
    );
    while (_calls.length > capacity) {
      _calls.removeLast();
    }
    _controller?.add(null);
  }

  /// Removes every record.
  static void clear() {
    _calls.clear();
    _controller?.add(null);
  }

  /// One line per call, newest first.
  static String summaryText() =>
      _calls.map((NetworkCall c) => c.summary).join('\n');

  static String? _truncate(String? body) {
    if (body == null || body.length <= maxBodyLength) {
      return body;
    }
    return '${body.substring(0, maxBodyLength)}… (${body.length - maxBodyLength} more)';
  }
}

/// A `package:http` client that records every call in [NetworkLog].
///
/// ```dart
/// final client = LoggingHttpClient();
/// await client.get(Uri.parse('https://example.com'));
/// ```
///
/// Text responses (`text/*`, JSON, XML, forms) are read into memory to be
/// recorded, truncated to [NetworkLog.maxBodyLength] in the record only; the
/// caller still receives the full body. Other responses (files, images,
/// streams) pass through untouched and are recorded without a body, as is
/// everything when [NetworkLog.recordBodies] is false.
class LoggingHttpClient extends http.BaseClient {
  /// Wraps [inner], or a new [http.Client].
  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final start = DateTime.now();
    final requestBody = NetworkLog.recordBodies && request is http.Request
        ? request.body
        : null;

    http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } on Object catch (e) {
      NetworkLog.record(
        NetworkCall(
          method: request.method,
          url: request.url.toString(),
          startedAt: start,
          duration: DateTime.now().difference(start),
          requestHeaders: request.headers,
          requestBody: requestBody,
          error: e.toString(),
        ),
      );
      rethrow;
    }

    if (!NetworkLog.recordBodies ||
        !_isText(response.headers['content-type'])) {
      NetworkLog.record(
        NetworkCall(
          method: request.method,
          url: request.url.toString(),
          startedAt: start,
          duration: DateTime.now().difference(start),
          requestHeaders: request.headers,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseHeaders: response.headers,
        ),
      );
      return response;
    }

    final bytes = await response.stream.toBytes();
    NetworkLog.record(
      NetworkCall(
        method: request.method,
        url: request.url.toString(),
        startedAt: start,
        duration: DateTime.now().difference(start),
        requestHeaders: request.headers,
        requestBody: requestBody,
        statusCode: response.statusCode,
        responseHeaders: response.headers,
        responseBody: _decode(bytes),
      ),
    );
    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();

  static bool _isText(String? contentType) {
    final type = (contentType ?? '').toLowerCase();
    return type.startsWith('text/') ||
        type.contains('json') ||
        type.contains('xml') ||
        type.contains('x-www-form-urlencoded');
  }

  static String _decode(Uint8List bytes) {
    final end = bytes.length < NetworkLog.maxBodyLength * 4
        ? bytes.length
        : NetworkLog.maxBodyLength * 4;
    return utf8.decode(bytes.sublist(0, end), allowMalformed: true);
  }
}
