# Logging and errors

The `Log` API, sinks, redaction, error handlers and the persisted log file.

## Logging

```dart
Log.info('cart loaded', tag: 'cart');
Log.warning('slow response', tag: 'net');
Log.error('checkout failed', error: e, stackTrace: s);
```

- Entries are kept in a bounded buffer (`Log.capacity`, default 2000) and
  attached to reports. `data: {...}` adds structured details that `toJson`
  keeps.
- The buffer keeps everything from `Log.bufferLevel` (default `debug`, also
  in release: that trail is what you need in a report). `Log.minLevel` is the
  threshold for the sinks: `debug` in debug builds, `info` in release.
- Sinks: `Log.addSink(MySink())` to forward entries to a file, Sentry, etc. A
  sink that throws never affects the others.
- Already on `package:logging`? One line:
  `Logger.root.onRecord.listen(Log.fromLoggingRecord);`
- `debugPrint` output is captured in debug builds (`captureDebugPrint`).
- Code full of `dart:developer` `log(...)` calls? Swap the import for
  `package:planish/developer.dart`: same `log` signature,
  `name` becomes the tag, and the lines reach the console and the reports.

## Errors

`Planish.init` hooks `FlutterError.onError` and
`PlatformDispatcher.onError` **and calls the previous handlers afterwards**,
so Crashlytics or Sentry keep working no matter the init order. Uncaught
errors are logged and attached to the next report.

```dart
prompts: PromptMode.notify,        // a draft and a card after an uncaught error
errorHandling: ErrorHandlingConfig(
  promptCooldown: Duration(minutes: 1),
  shouldPrompt: (error, stack) => error is! SocketException,
),
```

See [After an uncaught error](configuration.md#after-an-uncaught-error).

Caught something yourself? `Planish.recordError(e, s)`.
