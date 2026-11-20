import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:planish/src/env.dart';
import 'package:planish/src/host/gestures/gesture_configs.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Calls [onShake] when the device is shaken. Stops listening to the
/// accelerometer while the app is in the background.
class ShakeDetector extends StatefulWidget {
  const ShakeDetector({
    super.key,
    required this.config,
    required this.onShake,
    required this.child,
  });

  final ShakeGestureConfig config;

  final VoidCallback onShake;

  final Widget child;

  /// Replaces the sensor stream in tests.
  @visibleForTesting
  static Stream<UserAccelerometerEvent> Function()? eventsForTest;

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector>
    with WidgetsBindingObserver {
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final List<DateTime> _peaks = <DateTime>[];
  DateTime? _lastFired;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _listen();
    } else {
      _stop();
    }
  }

  void _listen() {
    final events = ShakeDetector.eventsForTest;
    if (_subscription != null || (isFlutterTest && events == null)) {
      return;
    }
    _peaks.clear();
    try {
      // Gravity excluded, so a sideways flick counts as much as a vertical
      // one; the default 200 ms period misses most flicks.
      _subscription =
          (events?.call() ??
                  userAccelerometerEventStream(
                    samplingPeriod: SensorInterval.uiInterval,
                  ))
              .listen(_onEvent, onError: (Object _) {});
    } on Object {
      // No sensor plugin registered (tests, unsupported platform): no shake.
    }
  }

  void _stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _onEvent(UserAccelerometerEvent event) {
    final now = DateTime.now();
    final c = widget.config;
    if (_lastFired != null && now.difference(_lastFired!) < c.cooldown) {
      return;
    }
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < c.threshold) {
      return;
    }
    _peaks
      ..removeWhere((DateTime t) => now.difference(t) > c.window)
      ..add(now);
    if (_peaks.length >= c.peaks) {
      _peaks.clear();
      _lastFired = now;
      widget.onShake();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Calls [onTrigger] after several simultaneous multi-finger taps.
class MultiFingerTapDetector extends StatefulWidget {
  const MultiFingerTapDetector({
    super.key,
    required this.config,
    required this.onTrigger,
    required this.child,
  });

  final MultiFingerTapGestureConfig config;

  final VoidCallback onTrigger;

  final Widget child;

  @override
  State<MultiFingerTapDetector> createState() => _MultiFingerTapDetectorState();
}

class _MultiFingerTapDetectorState extends State<MultiFingerTapDetector> {
  int _pointers = 0;
  final List<DateTime> _taps = <DateTime>[];

  void _down(PointerDownEvent _) {
    _pointers++;
    if (_pointers != widget.config.fingers) {
      return;
    }
    final now = DateTime.now();
    _taps
      ..removeWhere((DateTime t) => now.difference(t) > widget.config.window)
      ..add(now);
    if (_taps.length >= widget.config.taps) {
      _taps.clear();
      widget.onTrigger();
    }
  }

  void _up(PointerEvent _) => _pointers = math.max(0, _pointers - 1);

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _up,
    child: widget.child,
  );
}

/// Calls [onSwipe] after a swipe that starts on a screen edge.
class EdgeSwipeDetector extends StatefulWidget {
  const EdgeSwipeDetector({
    super.key,
    required this.config,
    required this.onSwipe,
    required this.child,
  });

  final EdgeSwipeGestureConfig config;

  final VoidCallback onSwipe;

  final Widget child;

  @override
  State<EdgeSwipeDetector> createState() => _EdgeSwipeDetectorState();
}

class _EdgeSwipeDetectorState extends State<EdgeSwipeDetector> {
  static const double _flickVelocity = 800;
  static const double _flickDistance = 24;

  Offset? _start;
  double _travel = 0;

  bool _onEdge(Offset p) {
    final size = MediaQuery.sizeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final c = widget.config;
    final edge = switch (c.edge) {
      ScreenEdge.start when rtl => ScreenEdge.end,
      ScreenEdge.end when rtl => ScreenEdge.start,
      final ScreenEdge e => e,
    };
    return switch (edge) {
      ScreenEdge.start => p.dx <= c.edgeWidth,
      ScreenEdge.end => p.dx >= size.width - c.edgeWidth,
      ScreenEdge.top => p.dy <= c.edgeWidth,
      ScreenEdge.bottom => p.dy >= size.height - c.edgeWidth,
    };
  }

  // With DragStartBehavior.down this is where the finger touched, not where
  // the pan was accepted (36 px later), so a swipe from the very edge counts.
  void _panStart(DragStartDetails d) {
    _start = _onEdge(d.globalPosition) ? d.globalPosition : null;
    _travel = 0;
  }

  /// Movement towards the inside of the screen.
  double _inward(Offset o) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return switch (widget.config.edge) {
      ScreenEdge.start => rtl ? -o.dx : o.dx,
      ScreenEdge.end => rtl ? o.dx : -o.dx,
      ScreenEdge.top => o.dy,
      ScreenEdge.bottom => -o.dy,
    };
  }

  void _fire() {
    _start = null;
    widget.onSwipe();
  }

  void _panUpdate(DragUpdateDetails d) {
    final start = _start;
    if (start == null) {
      return;
    }
    _travel = _inward(d.globalPosition - start);
    if (_travel >= widget.config.minDistance) {
      _fire();
    }
  }

  void _panEnd(DragEndDetails d) {
    if (_start != null &&
        _travel >= _flickDistance &&
        _inward(d.velocity.pixelsPerSecond) >= _flickVelocity) {
      _fire();
    }
    _start = null;
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.translucent,
    gestures: <Type, GestureRecognizerFactory>{
      PanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            PanGestureRecognizer.new,
            (PanGestureRecognizer r) {
              r
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = _panStart
                ..onUpdate = _panUpdate
                ..onEnd = _panEnd
                ..onCancel = () {
                  _start = null;
                };
            },
          ),
    },
    child: widget.child,
  );
}
