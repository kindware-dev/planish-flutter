import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:planish/src/ui/debug/debug_theme.dart';

/// An entry in the debug menu.
///
/// Use [DebugActionPlugin] for a one-shot action and [DebugPagePlugin] for a
/// full page. Mix in [ReportContextProvider] to add data to feedback reports.
abstract class DebugPlugin {
  const DebugPlugin();

  String title(BuildContext context);

  IconData get icon;

  /// Called when the entry is tapped. [context] is inside the debug menu's
  /// navigator, so `Navigator.push` opens a page on top of the menu.
  Future<void> open(BuildContext context);
}

/// A debug menu entry that runs a callback.
class DebugActionPlugin extends DebugPlugin {
  const DebugActionPlugin({
    required String title,
    required this.icon,
    required this.onTap,
  }) : _title = title;

  final String _title;

  @override
  final IconData icon;

  final Future<void> Function(BuildContext context) onTap;

  @override
  String title(BuildContext context) => _title;

  @override
  Future<void> open(BuildContext context) => onTap(context);
}

/// A debug menu entry that opens a page.
abstract class DebugPagePlugin extends DebugPlugin {
  const DebugPagePlugin();

  /// Builds the page. Wrap it in a `Scaffold` with an `AppBar` so the user can
  /// go back.
  Widget buildPage(BuildContext context);

  @override
  Future<void> open(BuildContext context) => Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      pageBuilder: (BuildContext c, Animation<double> _, Animation<double> _) =>
          DebugToolsTheme(child: buildPage(c)),
      transitionsBuilder:
          (
            BuildContext _,
            Animation<double> a,
            Animation<double> _,
            Widget child,
          ) => FadeTransition(opacity: a, child: child),
    ),
  );
}

/// Contributes key/value pairs to every report: the state of the app at the
/// moment the user reports (current screen's data, sync status, feature
/// flags...). Register with `PlanishConfig.reportContext`, or mix
/// into a [DebugPlugin].
///
/// Keys are used as-is; prefix them (`run.phase`, `sync.pending`). Keep
/// values short: this is a snapshot, not a dump.
abstract mixin class ReportContextProvider {
  const ReportContextProvider();

  /// Returns context lines. Return an empty map to add nothing.
  Future<Map<String, String>> collectReportContext();
}

/// A [ReportContextProvider] built from a function.
class ReportContext extends ReportContextProvider {
  const ReportContext(this.collect);

  final FutureOr<Map<String, String>> Function() collect;

  @override
  Future<Map<String, String>> collectReportContext() async => collect();
}
