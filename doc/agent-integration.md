# Integrating planish: a guide for AI coding agents

This guide is for an AI coding agent (Claude Code, Codex, Cursor, Copilot...)
asked to add the `planish` package to an existing Flutter app. Follow the
sections in order. The code snippets are reference examples for the version
documented in the README; adapt them to the project and to the API of the
version actually installed.

## Working rules

Before making changes, inspect the existing application: architecture,
dependencies, error handling, logging, navigation, HTTP clients and release
configuration.

- Reuse existing infrastructure wherever possible. planish complements
  existing tools; it does not replace them.
- Preserve existing application behaviour, security controls, privacy settings
  and build configuration.
- Ask the human before decisions that affect report delivery, user
  interaction, data collection or other product behaviour. Do not ask about
  choices the project has already made.
- Do not invent APIs, configuration options or package behaviour. When a
  snippet does not compile against the installed version, read the installed
  package's source and `CHANGELOG.md` rather than guessing.
- Make the smallest coherent set of changes needed. No unrelated refactoring,
  no repository-wide migrations, no extra dependencies.
- Never disable or work around a privacy protection to make a report easier
  to diagnose.
- Review the final diff and report every assumption, unresolved decision,
  platform limitation and check that could not be run.
- Never claim that the integration or the delivery works without having run
  the relevant checks.

## Step 0: inventory

Record, before touching anything:

- Flutter and Dart versions (`.fvmrc`, `pubspec.yaml`), target platforms.
- Router: `MaterialApp`, `MaterialApp.router` with go_router, auto_route,
  other. Existing `navigatorObservers` and `builder`.
- Error handling: `runZonedGuarded`, `FlutterError.onError`,
  `PlatformDispatcher.onError`, crash reporters (Crashlytics, Sentry...).
- Logging: `print` / `debugPrint` / `dart:developer` / `package:logging` /
  `logger` / `talker`, and whether a structured logger is in place.
- HTTP: `package:http`, Dio, other; existing wrappers and interceptors.
- Where sign-in and sign-out happen, what identifies a user.
- Release build commands and flags (`--obfuscate`, `--split-debug-info`,
  dart-defines).

## Questions to ask the human

Ask these unless the project already answers them. Do not guess.

1. Where should reports go? `EmailFeedbackSender(to: [...])` (no backend,
   opens the mail client), `HttpFeedbackSender(url)` (multipart POST to their
   API), `PlanishCloudSender('pl_…', server: 'https://planish.kindware.eu')`
   (a Planish Cloud inbox; the ingest key comes from the app's settings
   there), or `CallbackFeedbackSender` to their own code. Never put a Slack,
   Trello or Jira token in the app; those belong behind their backend.
2. How should users open the form? A shake, an edge swipe
   (`TriggerGesture.edgeSwipe`, from the right edge by default), a button in
   the app, or several of them.
3. Which categories, if any? `FeedbackCategory.defaults` is bug, idea,
   question, other. Without `categories`, the form offers none.
4. May an optional reply e-mail field be shown (`askEmail`)?
5. What may a report contain? Screenshot, logs, device facts are on by
   default and reviewable by the user. The app's own data (what the screen
   shows, what the logs mention, what `reportContext` returns) is the
   project's responsibility: ask what must never appear (health data, login
   screens, personal data) and who receives the reports.
6. After an uncaught error, should the app offer a report (`prompts:
   PromptMode.notify`: a small card offers it)? Only for internal or test
   builds, never in store builds.

## Step 1: dependency

```yaml
dependencies:
  planish: ^0.1.0
```

`flutter pub get`. Do not add other dependencies for this integration.

## Step 2: one configuration, before runApp

There is exactly one `PlanishConfig`, passed to `Planish.init()` once. Later
steps add fields to this same object; never call `init` a second time.

```dart
import 'package:planish/planish.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Planish.init(
    PlanishConfig(
      sender: EmailFeedbackSender(to: ['support@example.com']), // from the human
      categories: FeedbackCategory.defaults,
      reportGestures: {TriggerGesture.shake},                  // if the human said yes
      askEmail: true,                                          // if the human said yes
      prompts: isInternalBuild ? PromptMode.notify : PromptMode.off, // question 6
    ),
  );
  runApp(const MyApp());
}
```

`isInternalBuild` stands for however the project tells test builds from store
builds (a flavor, a `--dart-define`); use what exists.

`init` installs `FlutterError.onError` and `PlatformDispatcher.onError`
handlers and calls the previous ones afterwards. Leave existing crash
reporters and zones exactly where they are, in whatever order they are
initialised. After integrating, confirm no SDK initialised later replaces
the handlers without chaining them.

## Step 3: builder and navigation observer, added to what exists

Add `Planish.navigationObserver` to the existing observers; do not remove
any. Compose an existing `builder` with `inner:`; do not replace it.

`MaterialApp`:

```dart
MaterialApp(
  builder: Planish.builder(),               // or Planish.builder(inner: existingBuilder)
  navigatorObservers: [...existingObservers, Planish.navigationObserver],
)
```

`MaterialApp.router` with go_router:

```dart
GoRouter(observers: [...existingObservers, Planish.navigationObserver], ...);
MaterialApp.router(routerConfig: router, builder: Planish.builder());
```

auto_route:

```dart
MaterialApp.router(
  routerConfig: _router.config(
    navigatorObservers: () => [...existingObservers, Planish.navigationObserver],
  ),
  builder: Planish.builder(),
);
```

## Step 4: HTTP calls in the timeline

Keep the existing client, wrappers and interceptors. Add planish as one more
layer.

`package:http`: wrap the client where it is created, keeping any existing
wrapper inside: `LoggingHttpClient(existingClient)`. If the app calls the
top-level functions (`http.get(...)`) and has no client, introduce one
shared client (`final client = LoggingHttpClient(http.Client());`) where
the calls are made, and route them through it; ask before touching shared
code used by apps without planish.

Dio: add an interceptor that calls `NetworkLog.record(NetworkCall(...))`; the
guide `doc/integrations.md` has the full class. Pass the response headers,
on errors too: reports read the backend's request and trace ids from them. If
the backend names its request id differently, add it to
`PrivacyConfig(traceHeaders: [...])`. Sensitive
headers and query parameters are redacted by the package; request and
response bodies never leave the device.

## Step 5: who the user is

Where the app signs in and out, next to the existing code:

```dart
Planish.setUser(id: user.id, email: user.email);
Planish.clearUser();
```

Stable facts once at startup: `Planish.setTag('env', 'staging')`.

## Step 6: logs, without a migration

Inspect the existing logging setup first and keep it. Connect it to planish
where a bridge exists:

- `package:logging`: `Logger.root.onRecord.listen(Log.fromLoggingRecord);`
- `dart:developer` `log(...)` everywhere: change the import to
  `package:planish/developer.dart`, same signature, nothing else changes.
- `logger`, `talker`: an output / observer that calls `Log.add(LogEntry(...))`.

Use `Log.*` with a tag (the class or feature name) for new code and for the
targeted changes that capture diagnostics the reports need, typically the
`catch` blocks that currently swallow errors:
`Log.warning('what failed', error: e, stackTrace: s, tag: ...)`.
Do not perform a repository-wide replacement of `print` / `debugPrint`
unless explicitly asked. Do not log request bodies, tokens or whole model
objects.

## Step 7: a snapshot of the app's state

Add `reportContext` and `analysisNotes` to the existing `PlanishConfig`
from step 2. One provider per main subsystem, short values, read at report
time:

```dart
reportContext: [
  ReportContext(() => {
    'cart.items': '${cart.items.length}',
    'sync.pending': '${outbox.length}',
  }),
],
analysisNotes: (report) =>
    'Tags: cart = CartController, sync = SyncService. '
    'Stack traces keep file and line numbers; build.commit is the commit to check out.',
```

`analysisNotes` is a fixed text for whoever analyses reports: how tags map to
classes, where to start reading, how builds are made. Check with the human
that nothing in `reportContext` is personal or sensitive data.

## Step 8: build facts in every report

Add to the existing release build commands or scripts, without changing other
flags:

```bash
--dart-define=PLANISH_COMMIT=$(git rev-parse --short HEAD) --dart-define=PLANISH_ENV=prod
```

They become `build.commit` and `build.env` in every report: the build line of
the report, and the version and environment filters in Planish Cloud. Use the
project's own names for environments (`dev`, `staging`, `prod`).

Preserve the project's release flags. If `--obfuscate` is in use, make sure
the `--split-debug-info` symbol files are retained per build so stack traces
can be symbolised (`flutter symbolize`); say so in `analysisNotes`. Do not
change the project's build security settings to improve stack traces.

## Step 9: an entry point in the UI

Add an entry in the app's own style (a settings tile, a menu item, an app
bar action) that calls `Planish.show()`. The translated label is available
as `PlanishLocalizations.of(context).sendFeedback`. If the human chose a
shake gesture, this entry is in addition, not instead.

## Step 9b: platform setup

No permission prompt is involved. Two native details:

- iOS: add `NSMotionUsageDescription` to `Info.plist` (for example "Shake the
  phone to report a problem."). The sensor plugin links the motion APIs, and
  App Store review asks for the key even though the shake only reads the
  accelerometer.
- Android: nothing to add; the mail and sensor plugins declare what they
  need.

## Step 10: checks

Run what the project's platforms allow; say which checks were not run.

1. `flutter analyze` and `flutter test` pass; the project's own checks pass.
   The package detects `flutter test` and stays out of the way (no
   `debugPrint` swap, no sensors, no screenshot), so existing widget tests
   need no change.
2. Open the form, type a message, tap "What will be sent?": the message, the
   screenshot, `app.version`, `screen`, `build.commit`, the `user.*` keys and
   the `reportContext` keys are listed; the log lines include `nav`, `http`
   and `lifecycle` entries. Nothing on that page is data the human said must
   never appear.
3. Send one report with the configured sender and confirm it arrived.
4. Failure paths: send with the network off (the form shows the reason and
   keeps the text; email sender saves a draft); send against a failing
   endpoint if `HttpFeedbackSender` is used (the user sees the server's
   message and can retry).
5. Crash path: force-quit the app while in the foreground, relaunch, open
   the form. The package documents `app.previousExit: abnormal` plus a
   `previous-session.txt` attachment for a launch that ended in the
   foreground; verify that on each target platform rather than assuming it,
   and report what you observed.
6. Review the diff: only the files this guide touches, no replaced observers,
   builders, handlers or wrappers, no new dependencies, no change to release
   flags beyond the two dart-defines.

## What is on in production

With the defaults, a store build has: error handlers, the log buffer on disk
(bounded, read back on the next launch, never sent on its own), redaction,
the feedback form, `Planish.show()` and `reportGestures`. Off: the debug
button, console, network and preferences viewers (`DebugToolsConfig.enabled`
is debug and profile only), `debugPrint` capture, the automatic prompt after
an uncaught error. A report leaves the device only when the user presses
Send, after the "What will be sent?" page is available to them.

## Do not

- Do not set `autoSendErrors: true` unless the human asks for it: it sends
  errors and logs without the user's action, a privacy decision that is
  theirs to make and to declare.
- Do not enable `DebugToolsConfig(enabled: true)` in release builds. To give
  the tools to some users of a release build, ask the human who should get
  them, then call `Planish.debugTools.allow(true)` from the app's own user or
  role logic. Never add a hidden gesture or code that grants them.
- Do not set `includeSharedPreferences: true` without reading what the app
  stores there.
- Do not set `prompts: PromptMode.notify` in store builds.
- Do not ship tokens for third-party services in the app.
- Do not remove or reorder existing observers, builders, zones, error
  handlers, HTTP wrappers or interceptors.
- Do not write a custom theme for the feedback form unless asked; it uses
  Planish's colours by design. `brandColor:` gives it the app's brand,
  `useAppTheme: true` the app's theme. The debug tools use Planish's colours
  too; `DebugToolsConfig(useAppTheme: true)` switches them to the app's.

## Versions

The snippets match the README of the version they ship with. Before relying
on one, confirm the API exists in the installed version (`pub.dev`
changelog, or the package source under `.pub-cache`). Renames are listed in
`CHANGELOG.md`; the package was `flutter_feedback_logging` with a
`FeedbackLogging` facade before 0.1.0.
