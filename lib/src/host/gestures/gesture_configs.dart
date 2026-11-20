import 'package:flutter/foundation.dart';

/// Shake detection parameters.
@immutable
class ShakeGestureConfig {
  const ShakeGestureConfig({
    this.threshold = 12.0,
    this.window = const Duration(seconds: 1),
    this.peaks = 2,
    this.cooldown = const Duration(seconds: 2),
  });

  /// Acceleration of the device, gravity excluded (m/s²), that counts as a
  /// peak.
  final double threshold;

  /// Peaks must happen within this window.
  final Duration window;

  /// Number of peaks required.
  final int peaks;

  /// Ignore further shakes for this long after one fired.
  final Duration cooldown;
}

/// Multi-finger tap parameters.
@immutable
class MultiFingerTapGestureConfig {
  const MultiFingerTapGestureConfig({
    this.fingers = 3,
    this.taps = 3,
    this.window = const Duration(seconds: 2),
  });

  /// Fingers that must touch the screen at once.
  final int fingers;

  /// Number of such taps required.
  final int taps;

  /// All taps must happen within this window.
  final Duration window;
}

/// Screen edge.
enum ScreenEdge {
  /// Leading edge (left in LTR).
  start,

  /// Trailing edge (right in LTR).
  end,

  /// Top edge.
  top,

  /// Bottom edge.
  bottom,
}

/// Edge swipe parameters.
@immutable
class EdgeSwipeGestureConfig {
  const EdgeSwipeGestureConfig({
    this.edge = ScreenEdge.end,
    this.edgeWidth = 40.0,
    this.minDistance = 80.0,
  });

  /// Edge the swipe must start from.
  final ScreenEdge edge;

  /// Width of the start zone, in logical pixels.
  final double edgeWidth;

  /// Distance to travel before the gesture fires. A quick flick inward fires
  /// earlier.
  final double minDistance;
}
