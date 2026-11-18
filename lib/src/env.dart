import 'dart:io';

import 'package:flutter/foundation.dart';

/// True under `flutter test`, which sets this variable for the test process.
/// Used to leave the host app's tests alone: no `debugPrint` swap, no sensor
/// streams.
final bool isFlutterTest =
    !kIsWeb && Platform.environment['FLUTTER_TEST'] == 'true';
