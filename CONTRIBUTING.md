# Contributing

Issues and pull requests are welcome. Before a big change, open an issue to
discuss it.

## Setup

```bash
flutter pub get
flutter gen-l10n
cd example && flutter pub get
```

## Checks

The CI runs these; run them before pushing:

```bash
dart format lib test example/lib
flutter analyze --fatal-infos
flutter test
dart pub publish --dry-run
```

## Conventions

- Keep the public API small. New options go on the existing config classes.
- Nothing leaves the device without the user pressing Send. A change that
  collects more data needs a `PrivacyConfig` switch, off by default, and a
  line in the "Privacy and collected data" table of the README.
- User-facing strings live in `lib/l10n/app_*.arb`, in all six languages.
- Tests go next to the feature in `test/`; a bug fix comes with the test that
  failed.
- Commit messages: `type(scope): description`, one line.
