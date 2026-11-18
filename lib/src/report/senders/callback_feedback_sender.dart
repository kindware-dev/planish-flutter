import 'dart:async';

import 'package:planish/src/report/feedback_report.dart';

/// Wraps a function as a [FeedbackSender].
///
/// ```dart
/// sender: CallbackFeedbackSender((report) async {
///   await myApi.submit(report.toJson());
/// }),
/// ```
///
/// A completed future counts as sent; a thrown error becomes a failure whose
/// message is `error.toString()`.
class CallbackFeedbackSender implements FeedbackSender {
  const CallbackFeedbackSender(this.onSend);

  /// Called with the report.
  final FutureOr<void> Function(FeedbackReport report) onSend;

  @override
  Future<FeedbackSendResult> send(FeedbackReport report) async {
    try {
      await onSend(report);
      return const FeedbackSent();
    } on Object catch (e, s) {
      return FeedbackFailed(e.toString(), error: e, stackTrace: s);
    }
  }
}
