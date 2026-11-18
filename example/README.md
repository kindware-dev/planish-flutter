# Planish example

A playground for the `planish` package: one screen that produces logs, HTTP
calls and errors, and every way to open and send a report.

```bash
cd example
flutter pub get
flutter run
```

## What it shows

- **Shake to report** and the floating debug button. "Simulate shake" does
  what a real shake does: with the debug tools on it toggles the button,
  otherwise it opens the "Something wrong?" sheet.
- **Senders switched at runtime** (`lib/senders.dart`): console (prints the
  brief), email, HTTP to httpbin, a Slack webhook, and Planish Cloud.
  The Slack and Cloud ones need values at build time:

  ```bash
  flutter run --dart-define=PLANISH_KEY=… --dart-define=PLANISH_SERVER=…
  ```
- **Debug plugins** (`lib/plugins.dart`): a feature flags page that also
  adds `flag.*` lines to every report, and a one-tap "Clear cache" action.
- **A log sink** (`CrashReporterSink` in `lib/senders.dart`) that counts
  warnings and errors, the shape of a Crashlytics or Sentry bridge.
- **Report context and analysis notes**, a dark mode toggle, a language
  switcher for the six built-in locales, the tutorial.
- Buttons that write logs at every level, make an HTTP call through
  `LoggingHttpClient`, throw a Flutter error and fail an unawaited future.

## Flags

| Define | Effect |
|---|---|
| `DEBUG_TOOLS=true` | keeps the debug tools in a release build |
| `APP_THEME_TOOLS=true` | debug tools in the app's colors instead of the slate palette |
| `PLANISH_COMMIT=$(git rev-parse --short HEAD)` | `build.commit` in every report |
| `PLANISH_KEY`, `PLANISH_SERVER` | Planish Cloud sender |

Shake the iOS simulator with Device > Shake, or use "Simulate shake".
