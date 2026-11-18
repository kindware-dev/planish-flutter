# Configuration

Every option of `PlanishConfig`, section by section. The [README](https://github.com/kindware-dev/planish#readme) has the short version.

## The form

Send is disabled until the user has typed a message, unless the report
carries an error (`show(error:)` or the automatic prompt), and until a
category is picked when `categoryRequired` is on.

## Who sent it

```dart
Planish.setUser(id: user.id, email: user.email);   // on login
Planish.clearUser();                               // on logout
Planish.setTag('tenant', 'acme');                  // any key/value
```

These land in every report's context as `user.*` and `tag.*`. To let users
leave a reply address, `askEmail: true` adds an optional e-mail field to the
form (remembered on the device, sent as `FeedbackReport.email`).

## How a report is made

1. The screen is captured (the form itself is never in the screenshot).
2. The user can draw on it, pick a category, type a message, and open
   **What will be sent?** to see the exact content.
3. The report is built: message, screenshot, error (if any), the `Log`
   timeline (your logs, screen changes, HTTP calls, lifecycle changes),
   device and app facts, the state snapshots from `reportContext`, and your
   extra attachments.
4. `PrivacyConfig.beforeSend` can inspect, change or cancel it.
5. The sender delivers it. The user sees the real reason if it fails and can
   retry; nothing typed is lost.

## Where reports go

```dart
// Opens the user's mail client with screenshot.png and report.txt attached.
EmailFeedbackSender(to: ['support@example.com'], cc: ['dev@example.com'])

// multipart/form-data POST: fields id, message, category, error, context,
// report (JSON, see FeedbackReport.toJson); files screenshot, logs, brief.
HttpFeedbackSender(Uri.parse('https://api.example.com/feedback'),
    headers: {'x-api-key': 'public-key'})

// A Planish Cloud inbox: the app's ingest key and the inbox address.
PlanishCloudSender('pl_…', server: 'https://planish.kindware.eu')

// Anything else.
CallbackFeedbackSender((report) => myApi.submit(report.toJson()))
```

Or implement `FeedbackSender` and return `FeedbackSent`, `FeedbackHandedOff`
(another app has the report, outcome unknown), `FeedbackCancelled`
or `FeedbackFailed('reason shown to the user')`.

Every report has a random `id` (deduplicate retries on it), the `sessionId`
of the launch, `toJson()` with one object per log entry (`schemaVersion` 1),
and `toMarkdown()`: a brief for whoever analyses it, with the user's message,
error and warning counts for the last minutes, the last background period,
the backend requests with their ids, the context, the recent timeline and the full error. The email sender uses
it as the mail body; the HTTP sender attaches it as `brief.md`.

## What the app was doing

Logs say what happened. They do not say where the app *is* when the user
presses Send: how many items are in the cart, whether the user is offline,
which step of a flow is open. `reportContext` adds that snapshot to every
report. Each entry is a function called at report time that returns key/value
lines; they land in the report's context, next to `app.version` and `screen`,
and show up in "What will be sent?".

```dart
PlanishConfig(
  sender: ...,
  reportContext: [
    ReportContext(() => {
      'cart.items': '${cart.items.length}',
      'cart.total': cart.total.toString(),
      'network.online': '${connectivity.isOnline}',
    }),
  ],
)
```

Keep values short: this is a snapshot, not a dump. One `ReportContext` per
subsystem keeps them easy to find. A class can also implement
`ReportContextProvider` directly.

`analysisNotes` is a fixed text, written once by your team, placed under
"Notes for analysis" in the report brief for whoever reads it (or whatever
AI assistant you paste it into): which tag maps to which class, where to
start reading, how your builds are made.

```dart
analysisNotes: (report) =>
    'Tags: cart = CartController, sync = SyncService. '
    'Stack traces are not obfuscated; build.commit is the commit to check out.',
```

Pass the commit and environment at build time so the brief says which code
was running:

```bash
flutter build ipa --dart-define=PLANISH_COMMIT=$(git rev-parse --short HEAD) --dart-define=PLANISH_ENV=prod
```

The timeline then also carries, in order: screen changes (`nav`), HTTP calls
through `LoggingHttpClient` (`http`: method, redacted URL, status, duration;
failures as warnings), app lifecycle changes (`lifecycle`), and uncaught
errors with the library, the build phase and the "relevant error-causing
widget" lines Flutter knows about. Reports add `session.id`, `app.uptime`,
`app.sinceResume`, `app.lifecycle`, `time.zone` and `memory.rss`.

### Request and trace ids

Each recorded HTTP call keeps the ids your backend uses to find it in its own
logs and traces, read from the request and response headers:

| Header | Kept as |
|---|---|
| `x-request-id`, `request-id`, `x-correlation-id`, `correlation-id` (first found) | request id |
| `traceparent` | trace id: its trace-id part |
| `sentry-trace` | trace id: the part before the first `-` |
| `b3` | trace id: the part before the first `-` |
| `x-b3-traceid`, `x-datadog-trace-id` | trace id, as is |

An id your backend sends under another name goes in
`PrivacyConfig(traceHeaders: ['x-shop-id'])`; it is read as a request id after
the built-in ones. A header listed in `sensitiveHeaders` never gives an id.

Reports carry these calls in `requests`: every failed call, and the calls in
the 10 seconds before the first uncaught error (or, without one, before the
first failed call); 20 at most, failures first. The ids also show in the
`http` timeline entries, in `toPlainText()` and in the `## Backend requests`
section of `toMarkdown()`. Nothing else from the headers is added.

### After a crash

With `persistLogs` (on by default), the log buffer is also written to a
bounded file under the app support directory, in batches, off the frame. On
the next launch the package knows how the previous one ended:
`Planish.previousExit` is `abnormal` when the app was in the
foreground when it stopped (crash, kill, force quit). Reports then carry
`app.previousExit` and a `previous-session.txt` attachment with the logs of
that launch, so the user can shake and send even though the app restarted.
Nothing is sent without the user pressing Send.

## Drafts

A report closed before it is sent is kept on the device as a draft: the
message, category, email and screenshot, with what the app was doing when the
form opened (context, logs, backend requests, error). Opening the form again
offers to continue the newest draft; a "Drafts" chip lists them all. Sending a
draft uses that frozen context, not a fresh one, and its id, so a retried send
stays one report.

- At most 10 drafts, kept 30 days after their last change; untouched
  automatic drafts go first when the limit is reached.
- `keepDrafts` turns them on or off; it follows `persistLogs` unless set.
- `Planish.drafts.list()` and `Planish.drafts.discard(id)` for your own UI;
  `Planish.drafts.pending` is the count as a `ValueListenable<int>`, for a
  badge on your own report button.
- At launch, when drafts are waiting, a card says "2 reports not sent" and
  opens the newest; at most once a day. `remindDrafts: false` turns it off.
- Drafts stay on the device; nothing leaves it until the person sends. A
  draft nobody sends is never seen by your team: see `autoSendErrors` below
  for builds where that is not acceptable.

## After an uncaught error

```dart
PlanishConfig(
  prompts: PromptMode.notify, // off (default), quiet or notify
)
```

| Mode | What happens |
|---|---|
| `off` | Nothing automatic. Logs, network and manual reports work as always. |
| `quiet` | A draft is prepared with the screenshot of the broken screen and the context; it waits in the form's Drafts list. |
| `notify` | The same draft, and a card over the app offers to add details: at most 3 per session, gone after 8 s; after two "Later" in a row it asks once whether to keep these quiet. |

`ErrorHandlingConfig.promptCooldown` and `shouldPrompt` still filter which
errors count. The deprecated `promptFeedbackOnError: true` means `notify`.

### Sending errors without the user (`autoSendErrors`)

Off by default, and meant for internal, QA or beta builds.

```dart
PlanishConfig(
  sender: PlanishCloudSender(key, server: server), // or HttpFeedbackSender
  autoSendErrors: true,
)
```

Every uncaught error is then also sent at once, without the user pressing
Send: the error, its stack trace, the context and the logs, marked
`source: automatic`. No screenshot, no message, no email, none of your
`attachments`; `beforeSend` still runs. The same error is sent once per
launch, at most 5 per launch, best effort (a failed send is logged, not
retried). With `prompts` set, the draft prepared for the error points to that
report (`relatedTo`), so a report the person completes later can be joined to
it. It does nothing with `EmailFeedbackSender`, which needs the user.

**Turning it on is your decision.** Errors and their logs then leave the
device without the user's action, which this package otherwise never does.
Say so in your privacy policy and in the stores' data-safety forms, and keep
`shouldPrompt` and the redactors in line with what your logs contain.

Keep secrets out of the app: put a Trello, Slack or Jira integration behind
your own endpoint rather than shipping an API token in the binary.

## Theming

- The feedback form, the quick sheet and the tutorial use Planish's colours
  (the same as Planish Cloud and its web widget) in your app's brightness,
  and follow it live. They keep your app's fonts. To change them, in order of
  precedence:
  - `theme: (context) => planishTheme(context).copyWith(...)`: your own
    `ThemeData`; `planishTheme` and `PlanishColors` are exported to start from.
  - `useAppTheme: true`: your app's `ThemeData`, as any other screen.
  - `brandColor: Color(0xFFFFC90D)`: Planish's colours with your brand.
    Buttons take it as given; text, links and outlines take a shade of it
    that reads at 4.5:1.
- The debug tools use Planish's colours too, light or dark with your app. Two
  alternatives:
  - `DebugToolsConfig(useAppTheme: true)`: console, menu and pages take the
    app's `ColorScheme` (light and dark), with log levels colored from it.
  - `DebugToolsConfig(theme: (context) => myThemeData)`: your own theme. Add
    a `DebugPalette` extension to it to control the log level and badge
    colors; otherwise they are derived from its `ColorScheme`.
- Category labels can be localized: `FeedbackCategory(id: 'bug', label: 'Bug',
  labelBuilder: (context) => L10n.of(context).bug)`. `label` stays in the
  report, `labelBuilder` is what the user sees.

## Localization

English, French, German, Spanish, Italian and Dutch are built in and follow
the app locale with no setup. To list the delegate explicitly (for example
with `MaterialApp.router` and a custom `Localizations` tree):

```dart
localizationsDelegates: [
  ...GlobalMaterialLocalizations.delegates,
  PlanishLocalizations.delegate,
],
```

Category labels are plain strings; build the list where you have a context
if you need them translated.
