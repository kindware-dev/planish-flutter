# Release builds and production

What runs in a store build, how to gate the tools, build defines and symbolication.

## Release builds and production

What runs in a store build with the defaults:

| | Debug / profile | Release |
|---|---|---|
| Error handlers, `Log` buffer, redaction | on | on |
| `Planish.show()`, `reportGestures` | on | on |
| Automatic draft and card after an uncaught error | off | off (`prompts`) |
| Debug button, console, network log, prefs viewer | on | **off**, unless your app calls `Planish.debugTools.allow(true)` for a user |
| `debugPrint` capture | on | off (`captureDebugPrint`) |
| `Log.minLevel` | `debug` | `info` |

Typical setup with an environment switch:

```dart
PlanishConfig(
  sender: HttpFeedbackSender(Uri.parse('${settings.base}/api/feedback')),
  reportGestures: {TriggerGesture.shake},            // users can always report
  debugTools: DebugToolsConfig(
    enabled: !settings.isProdEnvironment,             // dev & staging builds only
  ),
  prompts: settings.isProdEnvironment ? PromptMode.off : PromptMode.notify,
)
```

On disk: two booleans (debug button shown, tutorial done) and, with
`persistLogs`, a bounded log file under the app support directory, read back
on the next launch and never sent on its own.
