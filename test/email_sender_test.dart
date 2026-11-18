import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory tmp;
  late List<Map<Object?, Object?>> sends;
  late Object? Function() reply;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('planish_mail_');
    sends = <Map<Object?, Object?>>[];
    reply = () => 'sent';
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => tmp.path,
    );
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_mailer'), (
      MethodCall call,
    ) async {
      final args = call.arguments as Map<Object?, Object?>;
      // The mail app reads the files while the composer is open.
      for (final path in args['attachments']! as List<Object?>) {
        final p = path! as String;
        expect(File(p).existsSync(), isTrue, reason: p);
      }
      sends.add(args);
      final r = reply();
      if (r is PlatformException) {
        throw r;
      }
      return r;
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_mailer'),
      null,
    );
    await tmp.delete(recursive: true);
  });

  FeedbackReport report() => FeedbackReport(
    message: 'It broke',
    createdAt: DateTime(2026, 1, 2, 3, 4, 5),
    appName: 'Demo',
    screenshot: Uint8List.fromList(<int>[1, 2, 3]),
    attachments: <FeedbackAttachment>[
      FeedbackAttachment.text('notes.txt', 'n'),
    ],
  );

  test(
    'writes the files, hands them to the mail app, then cleans up',
    () async {
      const sender = EmailFeedbackSender(
        to: <String>['a@b.c'],
        cc: <String>['d@e.f'],
      );
      final result = await sender.send(report());
      expect(result, isA<FeedbackSent>());
      final args = sends.single;
      expect(args['recipients'], <String>['a@b.c']);
      expect(args['ccRecipients'], <String>['d@e.f']);
      expect(args['subject'], '[Demo] Feedback');
      expect(args['body'], contains('It broke'));
      final names = (args['attachments']! as List<Object?>)
          .map((Object? p) => p! as String)
          .map((String p) => p.split('/').last)
          .toList();
      expect(names, <String>['screenshot.png', 'report.txt', 'notes.txt']);
      expect(tmp.listSync(), isEmpty, reason: 'temporary files removed');
    },
  );

  test('maps the mail app responses', () async {
    const sender = EmailFeedbackSender(to: <String>['a@b.c']);
    reply = () => 'android';
    expect(await sender.send(report()), isA<FeedbackHandedOff>());
    reply = () => 'cancelled';
    expect(await sender.send(report()), isA<FeedbackCancelled>());
    reply = () => 'saved';
    expect(await sender.send(report()), isA<FeedbackSent>());
    reply = () => PlatformException(code: 'no_mail', message: 'No mail app');
    final failed = await sender.send(report());
    expect(failed, isA<FeedbackFailed>());
    expect((failed as FeedbackFailed).message, 'No mail app');
  });
}
