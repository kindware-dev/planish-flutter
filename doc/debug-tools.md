# Debug tools

The floating button, console, network log, device info, preferences viewer and custom plugins.

## Debug tools

Shake the device (configurable) to show a floating button that opens the
debug menu:

- **Console**: a floating panel docked at the bottom, so you keep using the
  app while logs stream in. Resize it by dragging, or open the full page with
  level filters.
- **Network**: calls made through `LoggingHttpClient` (headers redacted,
  bodies truncated, nothing persisted)
- **Device & app**: everything `DeviceInfoLevel.full` would collect
- **Shared preferences**: read-only viewer
- **Tutorial**: the same walkthrough your users get
- your own `DebugPagePlugin` (a page, optionally contributing lines to every
  report through `ReportContextProvider`) or `DebugActionPlugin` (one tap)

```dart
debugTools: DebugToolsConfig(
  enabled: kDebugMode || kProfileMode,   // the default
  gestures: {TriggerGesture.shake},
  plugins: [FeatureFlagsPlugin(), clearCachePlugin()],
),
```

When a gesture is in both `reportGestures` and `debugTools.gestures`, the
debug tools win while they are enabled; the menu's first entry is "Send
feedback" anyway.

## In a release build, for some users

The store build keeps the tools off for everyone; your app turns them on for
the people who need them, once it knows who is signed in:

```dart
// After sign-in: testers, your QA team, yourself.
if (user.isTester) {
  await Planish.debugTools.allow(true, remember: true);
}
// On sign-out, or when the role goes away.
await Planish.debugTools.allow(false);
```

From then on a shake shows the floating button, as in a debug build.
`remember: true` keeps the grant on this device across restarts until
`allow(false)`; without it the grant lasts for the session. The package has
no hidden gesture or code of its own: who gets the tools is your app's
decision, from your user roles, a remote flag or an e-mail list.
`allow(false)` cannot take the tools away from a build where
`DebugToolsConfig.enabled` is true.

Whoever gets the tools can read their own device's logs, network calls and
shared preferences. Grant them to people you would show those to.

For a whole build of testers, a build flag still works:

```dart
enabled: kDebugMode || const bool.fromEnvironment('DEBUG_TOOLS'),
```

```bash
flutter build ipa --dart-define=DEBUG_TOOLS=true
```

`Planish.debugTools.show()` / `.hide()` / `.toggle()` and
`Planish.showConsole()` control the tools from code. The tools use
Planish's colours, light or dark with the app, so they look the same in every
app.
