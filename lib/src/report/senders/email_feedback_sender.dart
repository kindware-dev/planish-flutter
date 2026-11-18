import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planish/src/report/feedback_report.dart';

/// Opens the user's mail client with the report pre-filled. The user still
/// has to press send. iOS reports whether they did; Android cannot, and the
/// result is then [FeedbackHandedOff].
///
/// The body is the report brief (`FeedbackReport.toMarkdown`). Attachments:
/// `screenshot.png`, `report.txt` (message, error, context and all logs) and
/// any extra attachment. Android and iOS only.
class EmailFeedbackSender implements FeedbackSender {
  const EmailFeedbackSender({
    required this.to,
    this.cc = const <String>[],
    this.bcc = const <String>[],
    this.subject,
  });

  final List<String> to;

  final List<String> cc;

  final List<String> bcc;

  /// Builds the subject. Defaults to `[<app name>] Feedback` or
  /// `[<app name>] Bug report` when the report carries an error.
  final String Function(FeedbackReport report)? subject;

  @override
  Future<FeedbackSendResult> send(FeedbackReport report) async {
    final dir = await Directory(
      '${(await getTemporaryDirectory()).path}/feedback_${report.createdAt.millisecondsSinceEpoch}',
    ).create(recursive: true);

    try {
      final paths = <String>[];
      if (report.screenshot != null) {
        paths.add(
          (await File(
            '${dir.path}/screenshot.png',
          ).writeAsBytes(report.screenshot!)).path,
        );
      }
      paths.add(
        (await File(
          '${dir.path}/report.txt',
        ).writeAsString(report.toPlainText())).path,
      );
      for (final a in report.attachments) {
        paths.add(
          (await File('${dir.path}/${a.name}').writeAsBytes(a.bytes)).path,
        );
      }

      final response = await FlutterMailer.send(
        MailOptions(
          subject: subject?.call(report) ?? _defaultSubject(report),
          body: report.toMarkdown(),
          recipients: to,
          ccRecipients: cc,
          bccRecipients: bcc,
          attachments: paths,
        ),
      );
      return switch (response) {
        MailerResponse.sent || MailerResponse.saved => const FeedbackSent(),
        // Android returns as soon as the share sheet opens; the outcome is
        // never known.
        MailerResponse.android => const FeedbackHandedOff(),
        MailerResponse.cancelled => const FeedbackCancelled(),
        // iOS reports `unknown` when the composer closes without a result.
        MailerResponse.unknown => const FeedbackSent(),
      };
    } on PlatformException catch (e, s) {
      return FeedbackFailed(e.message ?? e.code, error: e, stackTrace: s);
    } finally {
      // The mail client has copied the files by the time send() returns.
      await dir.delete(recursive: true).catchError((Object _) => dir);
    }
  }

  static String _defaultSubject(FeedbackReport r) =>
      '[${r.appName}] ${r.error == null ? 'Feedback' : 'Bug report'}';
}
