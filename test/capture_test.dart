import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/host/host.dart';
import 'package:planish/src/ui/feedback/annotate_page.dart';

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF336699),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

bool _isPng(Uint8List b) =>
    b.length > 8 &&
    b[0] == 0x89 &&
    b[1] == 0x50 &&
    b[2] == 0x4E &&
    b[3] == 0x47;

// Under runAsync, real engine work (decode, encode) completes between pumps;
// pumpAndSettle would spin on the progress indicator instead.
Future<void> _settle(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  await tester.pump();
}

void main() {
  setUp(() => Planish.reset());

  testWidgets('the host captures the app as a PNG', (
    WidgetTester tester,
  ) async {
    PlanishHostState.captureInTests = true;
    addTearDown(() => PlanishHostState.captureInTests = false);
    await Planish.init(
      PlanishConfig(
        sender: CallbackFeedbackSender((_) async {}),
        persistLogs: false,
        captureDebugPrint: false,
        debugTools: const DebugToolsConfig(enabled: false),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: Planish.builder(),
        home: const Scaffold(body: Center(child: Text('home'))),
      ),
    );
    final bytes = await tester.runAsync(() async {
      // The capture waits for a frame; pump one.
      final capture = PlanishHostState.current!.captureScreenshot(
        maxWidth: 200,
      );
      await tester.pump();
      return capture;
    });
    expect(bytes, isNotNull);
    expect(_isPng(bytes!), isTrue);
  });

  testWidgets('annotating returns a new PNG; undecodable input pops', (
    WidgetTester tester,
  ) async {
    final png = await tester.runAsync(() => _png(400, 600));
    Uint8List? result;
    var popped = false;
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [PlanishLocalizationsDelegate()],
        home: Builder(
          builder: (BuildContext c) {
            ctx = c;
            return const Scaffold(body: Text('home'));
          },
        ),
      ),
    );

    await tester.runAsync(() async {
      final future = Navigator.of(ctx).push<Uint8List>(
        MaterialPageRoute<Uint8List>(builder: (_) => AnnotatePage(image: png!)),
      );
      unawaited(
        future.then((Uint8List? r) {
          result = r;
          popped = true;
        }),
      );
      await _settle(
        tester,
        () =>
            find.byType(AnnotatePage).evaluate().isNotEmpty &&
            find.byType(CircularProgressIndicator).evaluate().isEmpty,
      );
      // Let the route transition finish before touching the page.
      await tester.pump(const Duration(milliseconds: 400));
      final canvas = find.byWidgetPredicate(
        (Widget w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_AnnotationPainter',
      );
      await tester.drag(canvas, const Offset(120, 160));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.delete_outline),
            )
            .onPressed,
        isNotNull,
        reason: 'a stroke was recorded',
      );
      await tester.tap(find.text('Done'));
      await _settle(tester, () => popped);
    });
    expect(popped, isTrue);
    expect(result, isNotNull);
    expect(_isPng(result!), isTrue);
    expect(result, isNot(equals(png)));

    popped = false;
    await tester.runAsync(() async {
      final future = Navigator.of(ctx).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) => AnnotatePage(image: Uint8List.fromList(<int>[1, 2])),
        ),
      );
      unawaited(
        future.then((Uint8List? r) {
          result = r;
          popped = true;
        }),
      );
      await _settle(tester, () => popped);
    });
    expect(popped, isTrue, reason: 'left the page on decode failure');
    expect(result, isNull);
  });
}
