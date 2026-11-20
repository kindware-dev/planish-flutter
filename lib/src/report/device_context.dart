import 'dart:io';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planish/src/config.dart';

/// Collects app and device facts for reports and the device info page.
abstract final class DeviceContext {
  static PackageInfo? _packageInfo;

  // Platform plugins can stay silent (tests, missing registration); never
  // let that block a report.
  static const Duration _timeout = Duration(seconds: 2);

  static Future<PackageInfo> _info() async =>
      _packageInfo ??= await PackageInfo.fromPlatform().timeout(_timeout);

  /// This build as drafts record it (`app.version` and `build.commit`), or
  /// null when the platform does not say.
  static Future<String?> buildId() async {
    try {
      final p = await _info();
      const commit = String.fromEnvironment('PLANISH_COMMIT');
      return '${p.version}+${p.buildNumber} $commit'.trim();
    } on Object {
      return null;
    }
  }

  /// App name as declared on the platform, or null before the first collect.
  static Future<String?> appName() async {
    try {
      return (await _info()).appName;
    } on Object {
      return null;
    }
  }

  /// Returns key/value pairs for [level]. Never throws; a failing source
  /// becomes a single `error` entry.
  static Future<Map<String, String>> collect(DeviceInfoLevel level) async {
    if (level == DeviceInfoLevel.none) {
      return const {};
    }
    final full = level == DeviceInfoLevel.full;
    final out = <String, String>{};

    try {
      final p = await _info();
      out['app.name'] = p.appName;
      out['app.version'] = '${p.version}+${p.buildNumber}';
      if (full) {
        out['app.package'] = p.packageName;
      }
    } on Object catch (e) {
      out['app.error'] = e.toString();
    }

    out['build.mode'] = kReleaseMode
        ? 'release'
        : (kProfileMode ? 'profile' : 'debug');
    // flutter build ... --dart-define=PLANISH_COMMIT=$(git rev-parse --short HEAD)
    const commit = String.fromEnvironment('PLANISH_COMMIT');
    const env = String.fromEnvironment('PLANISH_ENV');
    if (commit.isNotEmpty) {
      out['build.commit'] = commit;
    }
    if (env.isNotEmpty) {
      out['build.env'] = env;
    }
    out['locale'] = ui.PlatformDispatcher.instance.locale.toLanguageTag();
    final now = DateTime.now();
    out['time.local'] = now.toIso8601String();
    out['time.zone'] =
        '${now.timeZoneName} (UTC${now.timeZoneOffset.isNegative ? '-' : '+'}${now.timeZoneOffset.inHours.abs()})';
    if (!kIsWeb) {
      out['memory.rss'] = '${ProcessInfo.currentRss ~/ (1024 * 1024)} MB';
    }
    if (full) {
      final view = ui.PlatformDispatcher.instance.implicitView;
      if (view != null) {
        final size = view.physicalSize / view.devicePixelRatio;
        out['screen'] =
            '${size.width.round()}x${size.height.round()} @${view.devicePixelRatio}x';
      }
    }

    try {
      out.addAll(await _device(full).timeout(_timeout));
    } on Object catch (e) {
      out['device.error'] = e.toString();
    }
    return out;
  }

  static Future<Map<String, String>> _device(bool full) async {
    final plugin = DeviceInfoPlugin();
    if (kIsWeb) {
      return {'os': 'web'};
    }
    if (Platform.isAndroid) {
      final a = await plugin.androidInfo;
      return {
        'os': 'Android ${a.version.release} (SDK ${a.version.sdkInt})',
        'device.model': '${a.manufacturer} ${a.model}',
        if (full) ...<String, String>{
          'device.brand': a.brand,
          'device.hardware': a.hardware,
          'device.physical': a.isPhysicalDevice.toString(),
          'device.id': a.id,
          'os.securityPatch': a.version.securityPatch ?? '-',
        },
      };
    }
    if (Platform.isIOS) {
      final i = await plugin.iosInfo;
      return {
        'os': '${i.systemName} ${i.systemVersion}',
        'device.model': i.utsname.machine,
        if (full) ...<String, String>{
          'device.name': i.name,
          'device.physical': i.isPhysicalDevice.toString(),
          'device.id': i.identifierForVendor ?? '-',
        },
      };
    }
    if (Platform.isMacOS) {
      final m = await plugin.macOsInfo;
      return {
        'os': 'macOS ${m.osRelease}',
        'device.model': m.model,
        if (full) 'device.name': m.computerName,
      };
    }
    if (Platform.isWindows) {
      final w = await plugin.windowsInfo;
      return {
        'os': 'Windows ${w.displayVersion}',
        if (full) 'device.name': w.computerName,
      };
    }
    if (Platform.isLinux) {
      final l = await plugin.linuxInfo;
      return {'os': l.prettyName};
    }
    return {'os': Platform.operatingSystem};
  }
}
