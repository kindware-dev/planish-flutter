# Changelog

## 0.1.2

- Release and profile builds attach the screenshot again
- After an uncaught error on a still screen, the error card shows at once
  instead of waiting for the next touch
- The edge swipe fires from the very edge and on a short quick flick; it
  starts within 40 px of the edge and needs 80 px of travel by default
- Works with `package_info_plus` 8 and `device_info_plus` 10 and later
- The drafts list shows only the user's own drafts, each with its
  screenshot, words, screen and date; errors caught without the user fold
  into one line, grouped by screen, and "Delete all drafts" clears the list
- Errors caught and never opened are dropped when the app's version or build
  changes; the "Drafts" count and the launch reminder leave them out
- The "Share feedback" sheet lists its choices as rows, each with a short
  hint; `QuickReportAction.hint` adds one to your own entries
- The feedback form's title is bold
- The agent integration guide covers Planish Cloud, the error prompt, apps
  without an HTTP client and the iOS motion key

## 0.1.1

- Works with `device_info_plus` 13; 12 is still accepted
- Analyzes cleanly on Flutter 3.50 while still supporting Flutter 3.32
- The details of a network call use the Planish theme, like the rest of the
  debug tools

## 0.1.0

First release.

- Feedback from inside the app: bugs, ideas, questions or anything else, with
  a screenshot to annotate, a message whose hint follows the category, and a
  "What will be sent?" review page
- Opened by a button, `Planish.show()`, or a shake (also multi-finger tap or
  edge swipe) in any build: a small "Share feedback" sheet, then the form;
  customisable or replaceable
- Each report carries the recent logs, screen changes, HTTP calls with the
  backend's request and trace ids, device and build facts, and any error with
  its stack trace, plus a Markdown brief for an issue or a coding agent
- Senders: email (`EmailFeedbackSender`), HTTP multipart
  (`HttpFeedbackSender`), a Planish Cloud inbox (`PlanishCloudSender`), a
  callback (`CallbackFeedbackSender`) or your own `FeedbackSender`
- Drafts: a report closed before sending stays on the device, with what the
  app was doing when the form opened, and is offered again (`keepDrafts`,
  `Planish.drafts`)
- After an uncaught error: prepare a draft quietly or offer it in a small card
  (`prompts`); optionally send minimal error reports at once (`autoSendErrors`,
  off by default)
- `Log`: bounded in-memory logger with sinks, redaction and a `package:logging`
  bridge; `LoggingHttpClient` records HTTP calls
- Error handlers chain `FlutterError.onError` and `PlatformDispatcher.onError`,
  so Crashlytics or Sentry keep working
- Debug tools in debug and profile builds, or for chosen users in release
  (`Planish.debugTools.allow`): floating button, console, network log, device
  info, shared preferences viewer and your own plugins
- `PrivacyConfig`: conservative defaults, header and query redaction,
  `beforeSend` hook
- Tutorial, optionally shown on first launch
- English, French, German, Spanish, Italian and Dutch, with no setup
