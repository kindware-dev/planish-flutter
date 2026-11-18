# Working with other packages

## flutter test

Under `flutter test` (detected through the `FLUTTER_TEST` variable the tool
sets) the package behaves so that the host app's widget tests keep passing
with the default config:

- `captureDebugPrint` does not replace `debugPrint`, which flutter_test
  checks at the end of every test;
- the shake detector does not open the accelerometer stream, which has no
  platform implementation there;
- `show()` opens the form without a screenshot: image encoding runs on the
  engine, outside the test's fake clock, and would never complete.

Nothing to configure. To exercise the form in your own tests, call
`Planish.show()` and `pumpAndSettle()`; `Planish.reset()` clears the state
between tests.

Routers, HTTP clients, loggers, crash reporters and state management.

## Working with other packages

**`MaterialApp.router`, go_router, auto_route** — `builder:` works the same.
Already have a builder? Nest it:

```dart
MaterialApp.router(
  routerConfig: router.config(
    navigatorObservers: () => [Planish.navigationObserver], // auto_route
  ),
  builder: Planish.builder(
    inner: (context, child) => TextScaleFactorClamper(child: child!),
  ),
)
// go_router: GoRouter(observers: [Planish.navigationObserver], ...)
```

**`package:http`** — wrap your client once: `final client = LoggingHttpClient(http.Client());`.
Text responses are read into memory to be recorded; files and streams pass
through untouched. `NetworkLog.recordBodies = false` records no body at all.
Request and trace ids are read from the headers of every call, see
[configuration](configuration.md#request-and-trace-ids).
A custom `http.BaseClient` layer wraps the same way.

**Dio** — no dependency on it here; an interceptor is a dozen lines:

```dart
class PlanishInterceptor extends Interceptor {
  final _started = Expando<DateTime>();

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    _started[o] = DateTime.now();
    h.next(o);
  }

  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    _record(r.requestOptions, statusCode: r.statusCode, body: r.data?.toString(), headers: r.headers.map.map((k, v) => MapEntry(k, v.join(','))));
    h.next(r);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    _record(e.requestOptions, statusCode: e.response?.statusCode, headers: e.response?.headers.map.map((k, v) => MapEntry(k, v.join(','))), error: e.message);
    h.next(e);
  }

  void _record(RequestOptions o, {int? statusCode, String? body, Map<String, String>? headers, String? error}) {
    final started = _started[o] ?? DateTime.now();
    NetworkLog.record(NetworkCall(
      method: o.method,
      url: o.uri.toString(),
      startedAt: started,
      duration: DateTime.now().difference(started),
      requestHeaders: o.headers.map((k, v) => MapEntry(k, v.toString())),
      requestBody: o.data?.toString(),
      statusCode: statusCode,
      responseHeaders: headers ?? const {},
      responseBody: body,
      error: error,
    ));
  }
}
```

**`package:logging`** — `Logger.root.onRecord.listen(Log.fromLoggingRecord);`

**`logger`, `talker`** — add a `LogOutput` / `TalkerObserver` that calls
`Log.add(LogEntry(...))`; same idea as the `CrashReporterSink` in the example,
in the other direction.

**Crashlytics, Sentry** — initialize them before or after
`Planish.init`, both orders work: the previous `FlutterError.onError`
and `PlatformDispatcher.onError` are called. To also forward log lines, add a
`LogSink` (see `CrashReporterSink` in the example). To jump between a report
and the crash reporter's events, link the identifiers both ways:

```dart
PlanishConfig(
  sender: …,
  // Report → crash reporter: the last Sentry event goes into the context.
  reportContext: [
    ReportContext(() => {'sentry.event': Sentry.lastEventId.toString()}),
  ],
  // Crash reporter → report: later events carry the report id.
  onReportSent: (report) {
    FirebaseCrashlytics.instance.setCustomKey('planish.report', report.id);
    Sentry.configureScope((scope) => scope.setTag('planish.report', report.id));
  },
);
// Every event of this launch carries the session shown in reports.
FirebaseCrashlytics.instance.setCustomKey('planish.session', Planish.sessionId);
```

**provider, riverpod, bloc, get_it** — nothing to do. `Planish` is
static; call it from anywhere.
