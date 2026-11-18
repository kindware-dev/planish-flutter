import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/host/gestures/gesture_detectors.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  testWidgets('multi-finger tap fires after the configured taps', (
    WidgetTester tester,
  ) async {
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MultiFingerTapDetector(
          config: const MultiFingerTapGestureConfig(fingers: 2, taps: 2),
          onTrigger: () => fired++,
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    );
    var pointer = 10;
    // Fresh pointer ids each time; a reused id is not delivered again.
    Future<void> twoFingerTap() async {
      final a = await tester.createGesture(pointer: pointer++);
      final b = await tester.createGesture(pointer: pointer++);
      await a.down(const Offset(100, 100));
      await b.down(const Offset(200, 100));
      await a.up();
      await b.up();
      await tester.pump();
    }

    await tester.tapAt(const Offset(100, 100));
    expect(fired, 0, reason: 'one finger does not count');
    await twoFingerTap();
    expect(fired, 0);
    await twoFingerTap();
    expect(fired, 1);
  });

  testWidgets('edge swipe fires from the edge only, after the distance', (
    WidgetTester tester,
  ) async {
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: EdgeSwipeDetector(
          config: const EdgeSwipeGestureConfig(
            edge: ScreenEdge.end,
            edgeWidth: 24,
            minDistance: 120,
          ),
          onSwipe: () => fired++,
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    );
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    await tester.dragFrom(Offset(width / 2, 300), const Offset(-200, 0));
    await tester.pump();
    expect(fired, 0, reason: 'not from the edge');

    await tester.dragFrom(Offset(width - 5, 300), const Offset(-60, 0));
    await tester.pump();
    expect(fired, 0, reason: 'too short');

    final g = await tester.startGesture(Offset(width - 5, 300));
    await g.moveBy(const Offset(-80, 0));
    await g.moveBy(const Offset(-80, 0));
    await g.up();
    await tester.pump();
    expect(fired, 1);
  });

  testWidgets('a sideways flick counts; a gentle movement does not', (
    WidgetTester tester,
  ) async {
    final events = StreamController<UserAccelerometerEvent>();
    ShakeDetector.eventsForTest = () => events.stream;
    addTearDown(() {
      ShakeDetector.eventsForTest = null;
      unawaited(events.close());
    });
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ShakeDetector(
          config: const ShakeGestureConfig(),
          onShake: () => fired++,
          child: const SizedBox.expand(),
        ),
      ),
    );
    UserAccelerometerEvent e(double x) =>
        UserAccelerometerEvent(x, 0, 0, DateTime.now());

    // A sideways flick of 15 m/s². With gravity subtracted from the total
    // norm it measured about 8 and never reached the 12 threshold.
    events
      ..add(e(15))
      ..add(e(-15));
    await tester.pump();
    expect(fired, 1);

    // Walking with the phone: well under the threshold.
    events
      ..add(e(4))
      ..add(e(-5));
    await tester.pump(const Duration(seconds: 3));
    expect(fired, 1);
  });
}
