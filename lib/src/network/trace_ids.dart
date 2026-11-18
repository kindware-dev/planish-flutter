import 'package:flutter/foundation.dart';
import 'package:planish/src/network/network_log.dart';

/// Whether a call's request and trace ids were found.
enum IdsState {
  /// At least one id was read.
  found,

  /// The call carried no known id header.
  absent,

  /// The ids may exist but could not be read. Web only: a cross-origin
  /// response without `Access-Control-Expose-Headers`. Never set by this
  /// package.
  hidden,
}

/// The request and trace ids of one HTTP call, read from its headers so a
/// report links to the backend logs.
@immutable
class CallIds {
  /// Creates the ids of a call.
  const CallIds({this.requestId, this.traceId, this.state = IdsState.absent});

  /// From `x-request-id`, `request-id`, `x-correlation-id`, `correlation-id`
  /// or a name in `PrivacyConfig.traceHeaders`.
  final String? requestId;

  /// The trace part of `traceparent`, `sentry-trace`, `b3`, `x-b3-traceid` or
  /// `x-datadog-trace-id`.
  final String? traceId;

  final IdsState state;

  /// `{requestId?, traceId?, state}`.
  Map<String, Object?> toJson() => <String, Object?>{
    if (requestId != null) 'requestId': requestId,
    if (traceId != null) 'traceId': traceId,
    'state': state.name,
  };
}

/// One entry of the report's `requests`.
@immutable
class BackendRequest {
  /// Creates an entry.
  const BackendRequest({
    required this.at,
    required this.method,
    required this.url,
    required this.ms,
    this.status,
    this.ids = const CallIds(),
  });

  /// From a recorded call.
  factory BackendRequest.fromCall(NetworkCall call) => BackendRequest(
    at: call.startedAt,
    method: call.method,
    url: call.url,
    status: call.statusCode,
    ms: call.duration.inMilliseconds,
    ids: call.ids,
  );

  /// Inverse of [toJson].
  factory BackendRequest.fromJson(Map<String, Object?> json) {
    final requestId = json['requestId'] as String?;
    final traceId = json['traceId'] as String?;
    return BackendRequest(
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime(1970),
      method: json['method'] as String? ?? 'GET',
      url: json['url'] as String? ?? '',
      status: json['status'] as int?,
      ms: json['ms'] as int? ?? 0,
      ids: CallIds(
        requestId: requestId,
        traceId: traceId,
        state: IdsState.values.firstWhere(
          (IdsState s) => s.name == json['idsState'],
          orElse: () => IdsState.absent,
        ),
      ),
    );
  }

  final DateTime at;

  final String method;

  /// URL with sensitive query parameters hidden.
  final String url;

  /// HTTP status, null when the call failed before a response.
  final int? status;

  final int ms;

  final CallIds ids;

  /// `GET https://… 500 (85 ms) · request id req_1 · trace id 4bf9…`.
  /// [quote] wraps the ids, e.g. in backticks for Markdown.
  String summary({String quote = ''}) {
    final ids = <String>[
      if (this.ids.requestId != null)
        'request id $quote${this.ids.requestId}$quote',
      if (this.ids.traceId != null) 'trace id $quote${this.ids.traceId}$quote',
    ];
    return '$method $url ${status ?? 'failed'} ($ms ms) · '
        '${ids.isEmpty ? 'no request id' : ids.join(' · ')}';
  }

  /// The shape Planish Cloud reads.
  Map<String, Object?> toJson() => <String, Object?>{
    'at': offsetIso(at),
    'method': method,
    'url': url,
    if (status != null) 'status': status,
    'ms': ms,
    if (ids.requestId != null) 'requestId': ids.requestId,
    if (ids.traceId != null) 'traceId': ids.traceId,
    'idsState': ids.state.name,
  };
}

const List<String> _requestIdHeaders = <String>[
  'x-request-id',
  'request-id',
  'x-correlation-id',
  'correlation-id',
];

// In order of precedence; each keeps only the trace part of its format.
final List<(String, String? Function(String))> _traceIdHeaders =
    <(String, String? Function(String))>[
      (
        'traceparent',
        _hex(r'^[0-9a-f]{2}-([0-9a-f]{32})-[0-9a-f]{16}-[0-9a-f]{2}$'),
      ),
      ('sentry-trace', _hex(r'^([0-9a-f]{32})(?:-|$)')),
      ('b3', _hex(r'^([0-9a-f]{32}|[0-9a-f]{16})(?:-|$)')),
      ('x-b3-traceid', _whole),
      ('x-datadog-trace-id', _whole),
    ];

const String _redacted = '<redacted>';

String? Function(String) _hex(String pattern) {
  final re = RegExp(pattern, caseSensitive: false);
  return (String value) => re.firstMatch(value.trim())?.group(1)?.toLowerCase();
}

String? _whole(String value) {
  final v = value.trim();
  return v.isEmpty ? null : v;
}

/// The ids of a call. Response headers win over request headers of the same
/// name; [extra] names add request ids after the built-in ones. Values
/// already redacted are ignored.
CallIds readIds(
  Map<String, String> request,
  Map<String, String> response, {
  Iterable<String> extra = const <String>[],
}) {
  final headers = <String, String>{
    for (final e in request.entries) e.key.toLowerCase(): e.value,
    for (final e in response.entries) e.key.toLowerCase(): e.value,
  }..removeWhere((String _, String v) => v == _redacted);
  String? requestId;
  for (final name in <String>[
    ..._requestIdHeaders,
    ...extra.map((String n) => n.trim().toLowerCase()),
  ]) {
    requestId = _whole(headers[name] ?? '');
    if (requestId != null) {
      break;
    }
  }
  String? traceId;
  for (final (name, read) in _traceIdHeaders) {
    final value = headers[name];
    traceId = value == null ? null : read(value);
    if (traceId != null) {
      break;
    }
  }
  return CallIds(
    requestId: requestId,
    traceId: traceId,
    state: requestId != null || traceId != null
        ? IdsState.found
        : IdsState.absent,
  );
}

const Duration _window = Duration(seconds: 10);
const int _maxRequests = 20;

/// The calls a report carries: those in the 10 seconds up to the first
/// uncaught error (or, with none, the first failed call), plus every failed
/// call; at most 20, failures first, returned oldest first.
List<BackendRequest> pickRequests(
  Iterable<NetworkCall> calls, {
  DateTime? firstErrorAt,
}) {
  final failures = calls.where((NetworkCall c) => c.isFailure).toList();
  var reference = firstErrorAt;
  if (reference == null) {
    for (final c in failures) {
      if (reference == null || c.startedAt.isBefore(reference)) {
        reference = c.startedAt;
      }
    }
  }
  if (reference == null) {
    return const <BackendRequest>[];
  }
  final ref = reference;
  int distance(NetworkCall c) =>
      c.startedAt.difference(ref).inMicroseconds.abs();
  int near(NetworkCall a, NetworkCall b) => distance(a).compareTo(distance(b));
  final others =
      calls
          .where(
            (NetworkCall c) =>
                !c.isFailure &&
                !c.startedAt.isBefore(ref.subtract(_window)) &&
                !c.startedAt.isAfter(ref),
          )
          .toList()
        ..sort(near);
  final picked =
      <NetworkCall>[
        ...failures..sort(near),
        ...others,
      ].take(_maxRequests).toList()..sort(
        (NetworkCall a, NetworkCall b) => a.startedAt.compareTo(b.startedAt),
      );
  return picked.map(BackendRequest.fromCall).toList();
}

/// Local time with its UTC offset, `2026-11-05T14:03:07.120+01:00`.
String offsetIso(DateTime time) {
  final local = time.toLocal();
  final offset = local.timeZoneOffset;
  String pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');
  final minutes = offset.inMinutes.abs();
  return '${local.year.toString().padLeft(4, '0')}-${pad(local.month)}-'
      '${pad(local.day)}T${pad(local.hour)}:${pad(local.minute)}:'
      '${pad(local.second)}.${pad(local.millisecond, 3)}'
      '${offset.isNegative ? '-' : '+'}${pad(minutes ~/ 60)}:${pad(minutes % 60)}';
}
