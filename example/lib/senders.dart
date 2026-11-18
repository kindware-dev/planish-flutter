import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:planish/planish.dart';
import 'package:http/http.dart' as http;

/// Every way a report can leave the app. Pick one in the example's settings.
enum SenderChoice { console, email, http, slack, cloud }

/// `--dart-define=PLANISH_KEY=pl_… --dart-define=PLANISH_SERVER=https://…`
const String cloudKey = String.fromEnvironment('PLANISH_KEY');
const String cloudServer = String.fromEnvironment('PLANISH_SERVER');

FeedbackSender senderFor(SenderChoice choice) => switch (choice) {
  // Prints the report; handy while developing.
  SenderChoice.console => CallbackFeedbackSender((FeedbackReport r) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    debugPrint(r.toPlainText());
  }),
  // Opens the user's mail client with screenshot.png and report.txt attached.
  SenderChoice.email => const EmailFeedbackSender(
    to: <String>['support@example.com'],
  ),
  // multipart/form-data POST to your own backend.
  SenderChoice.http => HttpFeedbackSender(
    Uri.parse('https://httpbin.org/post'),
    headers: const <String, String>{'x-api-key': 'public-demo-key'},
  ),
  // Your own sender: see below.
  SenderChoice.slack => SlackFeedbackSender(
    webhookUrl: Uri.parse('https://hooks.slack.com/services/XXX/YYY/ZZZ'),
  ),
  // A Planish Cloud inbox.
  SenderChoice.cloud =>
    cloudKey.isEmpty || cloudServer.isEmpty
        ? CallbackFeedbackSender((_) {
            throw StateError(
              'Run with --dart-define=PLANISH_KEY=… '
              '--dart-define=PLANISH_SERVER=…',
            );
          })
        : PlanishCloudSender(cloudKey, server: cloudServer),
};

/// Forwards to the sender picked in the example's settings, keeping its
/// result (a failure stays a failure).
class SelectedSender implements FeedbackSender {
  const SelectedSender(this.choice);

  final ValueListenable<SenderChoice> choice;

  @override
  Future<FeedbackSendResult> send(FeedbackReport report) =>
      senderFor(choice.value).send(report);
}

/// Example of a custom [FeedbackSender] posting to a Slack incoming webhook.
///
/// Webhooks cannot carry files, so the screenshot is dropped and only the
/// last log lines are inlined. Ship the webhook URL through your own backend
/// rather than in the app if the channel matters to you.
class SlackFeedbackSender implements FeedbackSender {
  SlackFeedbackSender({required this.webhookUrl, http.Client? client})
    : _client = client ?? http.Client();

  final Uri webhookUrl;
  final http.Client _client;

  @override
  Future<FeedbackSendResult> send(FeedbackReport report) async {
    final String logs = report.logs.reversed
        .take(15)
        .map((LogEntry e) => e.format())
        .join('\n');
    final Map<String, Object> payload = <String, Object>{
      'blocks': [
        <String, Object>{
          'type': 'header',
          'text': <String, String>{
            'type': 'plain_text',
            'text':
                '${report.appName}: ${report.category?.label ?? 'Feedback'}',
          },
        },
        <String, Object>{
          'type': 'section',
          'text': <String, String>{
            'type': 'mrkdwn',
            'text': report.message.isEmpty ? '_(no message)_' : report.message,
          },
        },
        if (report.errorText != null)
          <String, Object>{
            'type': 'section',
            'text': <String, String>{
              'type': 'mrkdwn',
              'text': '*Error*\n```${report.errorText}```',
            },
          },
        <String, Object>{
          'type': 'context',
          'elements': [
            <String, String>{'type': 'mrkdwn', 'text': report.contextAsText},
          ],
        },
        if (logs.isNotEmpty)
          <String, Object>{
            'type': 'section',
            'text': <String, String>{
              'type': 'mrkdwn',
              'text': '*Recent logs*\n```$logs```',
            },
          },
      ],
    };
    try {
      final http.Response res = await _client.post(
        webhookUrl,
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(payload),
      );
      return res.statusCode == 200
          ? const FeedbackSent()
          : FeedbackFailed('Slack responded ${res.statusCode}: ${res.body}');
    } on http.ClientException catch (e, s) {
      return FeedbackFailed(e.message, error: e, stackTrace: s);
    }
  }
}

/// Example of a custom [LogSink]: forward warnings and errors to your crash
/// reporter (Crashlytics, Sentry, ...). Here it just counts them.
class CrashReporterSink extends LogSink {
  int forwarded = 0;

  @override
  void write(LogEntry entry) {
    if (entry.level >= LogLevel.warning) {
      forwarded++;
      // FirebaseCrashlytics.instance.log(entry.format());
    }
  }
}
