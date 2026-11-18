import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:planish/src/config.dart';
import 'package:planish/src/log/log.dart';

/// Hooks `FlutterError.onError` and `PlatformDispatcher.onError` without
/// replacing what was there: the previous handlers still run afterwards, so
/// Crashlytics, Sentry or your own reporter keep working whichever is
/// installed first.
abstract final class ErrorHandlers {
  static FlutterExceptionHandler? _previousFlutter;
  static ErrorCallback? _previousPlatform;
  static bool _installed = false;
  static DateTime? _lastPrompt;
  static bool Function()? _prompting;

  /// Installs the handlers. [onPrompt] is called when an error qualifies for
  /// an automatic feedback prompt; [onUncaught] for every error that passes
  /// the prompt filter, whatever the prompt mode and cooldown.
  static void install(
    ErrorHandlingConfig config, {
    required void Function(Object error, StackTrace? stackTrace) onPrompt,
    void Function(Object error, StackTrace? stackTrace)? onUncaught,
    bool Function()? prompting,
  }) {
    if (_installed) {
      return;
    }
    _installed = true;
    _prompting = prompting;

    if (config.captureFlutterErrors) {
      _previousFlutter = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        Log.error(
          describe(details),
          error: details.exception,
          stackTrace: details.stack,
          tag: 'flutter',
        );
        if (!details.silent) {
          _uncaught(config, details.exception, details.stack, onUncaught);
          _maybePrompt(config, details.exception, details.stack, onPrompt);
        }
        // presentError prints the same error through debugPrint.
        Log.withoutDebugPrintCapture(
          () => (_previousFlutter ?? FlutterError.presentError)(details),
        );
      };
    }

    if (config.capturePlatformErrors) {
      _previousPlatform = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        Log.error(
          error.toString(),
          error: error,
          stackTrace: stack,
          tag: 'uncaught',
        );
        _uncaught(config, error, stack, onUncaught);
        _maybePrompt(config, error, stack, onPrompt);
        // false lets the engine apply its default behaviour (print and, in
        // release, keep running) when nobody else handles the error.
        return _previousPlatform?.call(error, stack) ?? false;
      };
    }
  }

  static void _uncaught(
    ErrorHandlingConfig config,
    Object error,
    StackTrace? stack,
    void Function(Object, StackTrace?)? onUncaught,
  ) {
    if (onUncaught != null &&
        (config.shouldPrompt ?? defaultShouldPrompt)(error, stack)) {
      onUncaught(error, stack);
    }
  }

  static void _maybePrompt(
    ErrorHandlingConfig config,
    Object error,
    StackTrace? stack,
    void Function(Object, StackTrace?) onPrompt,
  ) {
    // ignore: deprecated_member_use_from_same_package
    if (!(_prompting?.call() ?? config.promptFeedbackOnError)) {
      return;
    }
    final filter = config.shouldPrompt ?? defaultShouldPrompt;
    if (!filter(error, stack)) {
      return;
    }
    final now = DateTime.now();
    if (_lastPrompt != null &&
        now.difference(_lastPrompt!) < config.promptCooldown) {
      return;
    }
    _lastPrompt = now;
    onPrompt(error, stack);
  }

  /// The exception, then what Flutter knows about where it happened: the
  /// library, the phase (`building MyWidget`) and the "relevant error-causing
  /// widget" lines, which carry a file and line number.
  static String describe(FlutterErrorDetails details) {
    final b = StringBuffer(details.exceptionAsString());
    if (details.library != null) {
      b.write('\n  library: ${details.library}');
    }
    final context = details.context?.toDescription();
    if (context != null && context.isNotEmpty) {
      b.write('\n  while: $context');
    }
    final info = details.informationCollector?.call();
    if (info != null) {
      for (final node in info.take(6)) {
        final line = node.toString().trim();
        if (line.isNotEmpty) {
          b.write('\n  $line');
        }
      }
    }
    return b.toString();
  }

  /// Default prompt filter: skips layout overflows and image loading
  /// failures, which are noisy and rarely something the user can describe.
  static bool defaultShouldPrompt(Object error, StackTrace? _) {
    final text = error.toString();
    return !text.contains('overflowed by') &&
        !text.contains('Unable to load asset');
  }

  /// Restores the previous handlers.
  static void uninstall() {
    if (!_installed) {
      return;
    }
    FlutterError.onError = _previousFlutter;
    PlatformDispatcher.instance.onError = _previousPlatform;
    _previousFlutter = null;
    _previousPlatform = null;
    _lastPrompt = null;
    _prompting = null;
    _installed = false;
  }
}
