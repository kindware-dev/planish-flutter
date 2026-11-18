import 'package:http/http.dart' as http;
import 'package:planish/src/report/feedback_report.dart';
import 'package:planish/src/report/senders/http_feedback_sender.dart';

/// Sends reports to a Planish Cloud inbox.
///
/// [key] is the app's ingest key, shown once when the app is created;
/// [server] is the inbox's address, e.g. `https://planish.kindware.eu`.
///
/// ```dart
/// PlanishCloudSender('pl_…', server: 'https://planish.kindware.eu')
/// ```
class PlanishCloudSender implements FeedbackSender {
  factory PlanishCloudSender(
    String key, {
    required String server,
    Duration timeout = const Duration(seconds: 30),
    http.Client? client,
  }) {
    assert(key.isNotEmpty, 'PlanishCloudSender needs the ingest key');
    final base = server.endsWith('/') ? server : '$server/';
    final endpoint = Uri.parse(base).resolve('v1/reports');
    return PlanishCloudSender._(
      key,
      endpoint,
      HttpFeedbackSender(
        endpoint,
        headers: {'Authorization': 'Bearer $key'},
        timeout: timeout,
        client: client,
      ),
    );
  }

  PlanishCloudSender._(this.key, this.endpoint, this._http);

  final String key;

  /// Where reports are posted: `<server>/v1/reports`.
  final Uri endpoint;

  final HttpFeedbackSender _http;

  @override
  Future<FeedbackSendResult> send(FeedbackReport report) => _http.send(report);
}
