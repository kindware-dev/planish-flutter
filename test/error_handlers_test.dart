import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/errors/error_handlers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? originalFlutter;
  late ErrorCallback? originalPlatform;

  setUp(() async {
    await Log.reset();
    originalFlutter = FlutterError.onError;
    originalPlatform = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    ErrorHandlers.uninstall();
    FlutterError.onError = originalFlutter;
    PlatformDispatcher.instance.onError = originalPlatform;
  });

  test('previous FlutterError.onError still runs', () {
    final seen = <FlutterErrorDetails>[];
    FlutterError.onError = seen.add;
    ErrorHandlers.install(
      const ErrorHandlingConfig(),
      onPrompt: (Object _, StackTrace? _) {},
    );

    FlutterError.onError!(FlutterErrorDetails(exception: StateError('x')));

    expect(seen, hasLength(1));
    expect(Log.entries.single.level, LogLevel.error);
    expect(Log.entries.single.tag, 'flutter');
  });

  test('previous PlatformDispatcher.onError decides the return value', () {
    PlatformDispatcher.instance.onError = (Object _, StackTrace _) => true;
    ErrorHandlers.install(
      const ErrorHandlingConfig(),
      onPrompt: (Object _, StackTrace? _) {},
    );

    final handled = PlatformDispatcher.instance.onError!(
      Exception('e'),
      StackTrace.empty,
    );

    expect(handled, isTrue);
    expect(Log.entries.single.tag, 'uncaught');
  });

  test(
    'without a previous platform handler the error is reported as unhandled',
    () {
      PlatformDispatcher.instance.onError = null;
      ErrorHandlers.install(
        const ErrorHandlingConfig(),
        onPrompt: (Object _, StackTrace? _) {},
      );
      expect(
        PlatformDispatcher.instance.onError!(Exception('e'), StackTrace.empty),
        isFalse,
      );
    },
  );

  test('prompt respects the filter, cooldown and silent flag', () {
    var prompts = 0;
    ErrorHandlers.install(
      const ErrorHandlingConfig(
        promptFeedbackOnError: true,
        promptCooldown: Duration(hours: 1),
      ),
      onPrompt: (Object _, StackTrace? _) => prompts++,
    );
    FlutterError.onError!(
      FlutterErrorDetails(exception: StateError('silent'), silent: true),
    );
    FlutterError.onError!(
      FlutterErrorDetails(
        exception: Exception('A RenderFlex overflowed by 3 pixels'),
      ),
    );
    expect(prompts, 0);
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('real')));
    FlutterError.onError!(
      FlutterErrorDetails(exception: StateError('too soon')),
    );
    expect(prompts, 1);
  });

  test(
    'install is idempotent and uninstall restores the previous handlers',
    () {
      FlutterError.onError = (_) {};
      final before = FlutterError.onError;
      ErrorHandlers.install(
        const ErrorHandlingConfig(),
        onPrompt: (Object _, StackTrace? _) {},
      );
      ErrorHandlers.install(
        const ErrorHandlingConfig(),
        onPrompt: (Object _, StackTrace? _) {},
      );
      expect(FlutterError.onError, isNot(same(before)));
      ErrorHandlers.uninstall();
      expect(FlutterError.onError, same(before));
    },
  );
}
