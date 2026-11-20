// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/debug/debug_plugin.dart';
import 'package:planish/src/host/modal_layer.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/network/network_log.dart';
import 'package:planish/src/planish.dart';
import 'package:planish/src/ui/debug/device_info_page.dart';
import 'package:planish/src/ui/debug/network_page.dart';
import 'package:planish/src/ui/debug/preferences_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plugins shipped with the package, in menu order.
const List<DebugPlugin> builtInDebugPlugins = <DebugPlugin>[
  ConsolePlugin(),
  NetworkPlugin(),
  DeviceInfoPlugin(),
  PreferencesPlugin(),
];

/// Live log viewer. Opens the floating console so the app stays usable;
/// the panel has a button for the full-page version.
class ConsolePlugin extends DebugPlugin {
  const ConsolePlugin();

  @override
  IconData get icon => Icons.terminal;

  @override
  String title(BuildContext context) => context.planishStrings.console;

  @override
  Future<void> open(BuildContext context) async {
    PlanishModal.of(context).close(null);
    Planish.showConsole();
  }
}

/// Recent HTTP calls recorded by [LoggingHttpClient]. Adds a one-line summary
/// per call to reports when `PrivacyConfig.includeNetworkSummary` is on.
class NetworkPlugin extends DebugPagePlugin with ReportContextProvider {
  const NetworkPlugin();

  @override
  IconData get icon => Icons.swap_vert;

  @override
  String title(BuildContext context) => context.planishStrings.network;

  @override
  Widget buildPage(BuildContext context) => const NetworkPage();

  @override
  Future<Map<String, String>> collectReportContext() async {
    if (!Planish.config.privacy.includeNetworkSummary ||
        NetworkLog.calls.isEmpty) {
      return const {};
    }
    return {'network.recent': NetworkLog.summaryText()};
  }
}

/// App and device facts. Report context comes from `DeviceContext` directly;
/// this plugin only adds the page.
class DeviceInfoPlugin extends DebugPagePlugin {
  const DeviceInfoPlugin();

  @override
  IconData get icon => Icons.phone_android;

  @override
  String title(BuildContext context) => context.planishStrings.deviceInfo;

  @override
  Widget buildPage(BuildContext context) => const DeviceInfoPage();
}

/// Shared preferences viewer. Adds every key/value to reports only when
/// `PrivacyConfig.includeSharedPreferences` is on.
class PreferencesPlugin extends DebugPagePlugin with ReportContextProvider {
  const PreferencesPlugin();

  @override
  IconData get icon => Icons.storage_outlined;

  @override
  String title(BuildContext context) => context.planishStrings.preferences;

  @override
  Widget buildPage(BuildContext context) => const PreferencesPage();

  @override
  Future<Map<String, String>> collectReportContext() async {
    if (!Planish.config.privacy.includeSharedPreferences) {
      return const {};
    }
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final String key in prefs.getKeys().toList()..sort())
        'prefs.$key': prefs.get(key).toString(),
    };
  }
}
