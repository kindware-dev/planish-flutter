import 'package:flutter/material.dart';
import 'package:planish/planish.dart';
import 'package:planish_example/strings.dart';

/// Fake feature flags, to show a page plugin that also feeds reports.
class FeatureFlags {
  static final Map<String, bool> values = <String, bool>{
    'new_checkout': true,
    'dark_mode_v2': false,
    'beta_search': true,
  };
}

/// A page in the debug menu, plus one line per flag in every report.
class FeatureFlagsPlugin extends DebugPagePlugin with ReportContextProvider {
  const FeatureFlagsPlugin();

  @override
  IconData get icon => Icons.flag_outlined;

  @override
  String title(BuildContext context) => ExampleStrings.of(context).featureFlags;

  @override
  Widget buildPage(BuildContext context) => const _FeatureFlagsPage();

  @override
  Future<Map<String, String>> collectReportContext() async => {
    for (final MapEntry<String, bool> e in FeatureFlags.values.entries)
      'flag.${e.key}': e.value.toString(),
  };
}

class _FeatureFlagsPage extends StatefulWidget {
  const _FeatureFlagsPage();

  @override
  State<_FeatureFlagsPage> createState() => _FeatureFlagsPageState();
}

class _FeatureFlagsPageState extends State<_FeatureFlagsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ExampleStrings.of(context).featureFlags)),
      body: ListView(
        children: [
          for (final String key in FeatureFlags.values.keys)
            SwitchListTile(
              title: Text(key),
              value: FeatureFlags.values[key]!,
              onChanged: (bool v) => setState(() {
                FeatureFlags.values[key] = v;
                Log.info('Flag $key set to $v', tag: 'flags');
              }),
            ),
        ],
      ),
    );
  }
}

/// A one-shot action in the debug menu.
DebugActionPlugin clearCachePlugin() => _ClearCachePlugin();

class _ClearCachePlugin extends DebugActionPlugin {
  _ClearCachePlugin()
    : super(
        title: 'Clear cache',
        icon: Icons.cleaning_services_outlined,
        onTap: (BuildContext context) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          Log.info('Cache cleared', tag: 'cache');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ExampleStrings.of(context).cacheCleared)),
            );
          }
        },
      );

  @override
  String title(BuildContext context) => ExampleStrings.of(context).clearCache;
}
