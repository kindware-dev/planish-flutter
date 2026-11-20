// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/ui/debug/device_info_page.dart';
import 'package:planish/src/ui/debug/tool_page_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Read-only view of the app's shared preferences, one color per type.
class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  Future<Map<String, Object?>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final String key in prefs.getKeys().toList()..sort())
        key: prefs.get(key),
    };
  }

  static String _typeOf(Object? v) => switch (v) {
    bool() => 'bool',
    int() => 'int',
    double() => 'double',
    String() => 'String',
    List<Object?>() => 'List<String>',
    _ => v.runtimeType.toString(),
  };

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    return FutureBuilder<Map<String, Object?>>(
      future: _load(),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, Object?>> snap) {
            final prefs = snap.data ?? const {};
            return ToolPageScaffold(
              title: s.preferences,
              actions: [
                IconButton(
                  tooltip: s.copy,
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: prefs.isEmpty
                      ? null
                      : () => copyToClipboard(
                          context,
                          prefs.entries
                              .map((e) => '${e.key}: ${e.value}')
                              .join('\n'),
                        ),
                ),
              ],
              body: !snap.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : prefs.isEmpty
                  ? EmptyHint(s.noPreferences)
                  : KeyValueList(
                      {for (final e in prefs.entries) e.key: '${e.value}'},
                      types: {
                        for (final e in prefs.entries) e.key: _typeOf(e.value),
                      },
                    ),
            );
          },
    );
  }
}
