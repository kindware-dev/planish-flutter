# Changelog

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
