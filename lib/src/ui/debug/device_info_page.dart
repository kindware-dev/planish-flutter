// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/config.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/report/device_context.dart';
import 'package:planish/src/ui/debug/debug_theme.dart';
import 'package:planish/src/ui/debug/tool_page_scaffold.dart';

/// Shows everything `DeviceContext` can collect.
class DeviceInfoPage extends StatelessWidget {
  const DeviceInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    return FutureBuilder<Map<String, String>>(
      future: DeviceContext.collect(DeviceInfoLevel.full),
      builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snap) {
        final info = snap.data ?? const {};
        return ToolPageScaffold(
          title: s.deviceInfo,
          actions: [
            IconButton(
              tooltip: s.copy,
              icon: const Icon(Icons.copy_outlined),
              onPressed: info.isEmpty
                  ? null
                  : () => copyToClipboard(
                      context,
                      info.entries
                          .map(
                            (MapEntry<String, String> e) =>
                                '${e.key}: ${e.value}',
                          )
                          .join('\n'),
                    ),
            ),
          ],
          body: !snap.hasData
              ? const Center(child: CircularProgressIndicator())
              : KeyValueList(info),
        );
      },
    );
  }
}

/// Two-column list of key/value pairs with copy-on-long-press.
class KeyValueList extends StatelessWidget {
  const KeyValueList(this.entries, {super.key, this.types = const {}});

  final Map<String, String> entries;

  /// Optional type label per key, shown as a colored badge.
  final Map<String, String> types;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.symmetric(vertical: 8),
    itemCount: entries.length,
    separatorBuilder: (_, _) => const Divider(indent: 16, endIndent: 16),
    itemBuilder: (BuildContext context, int i) {
      final e = entries.entries.elementAt(i);
      final type = types[e.key];
      return ListTile(
        dense: true,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                e.key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: DebugPalette.of(context).text,
                ),
              ),
            ),
            if (type != null) ...[const SizedBox(width: 12), _TypeBadge(type)],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _ValueText(
            e.value,
            style: monoStyle(context, color: typeColor(context, type)),
          ),
        ),
        trailing: IconButton(
          tooltip: context.planishStrings.copy,
          icon: const Icon(Icons.content_copy, size: 18),
          color: DebugPalette.of(context).muted,
          onPressed: () => copyToClipboard(context, e.value),
        ),
      );
    },
  );
}

/// Long values (a JSON blob in a preference) are cut after a few lines;
/// a tap shows the whole thing.
class _ValueText extends StatefulWidget {
  const _ValueText(this.value, {required this.style});

  static const int limit = 240;

  final String value;
  final TextStyle style;

  @override
  State<_ValueText> createState() => _ValueTextState();
}

class _ValueTextState extends State<_ValueText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final long = widget.value.length > _ValueText.limit;
    if (!long || _expanded) {
      return SelectableText(widget.value, style: widget.style);
    }
    return GestureDetector(
      onTap: () => setState(() => _expanded = true),
      child: Text.rich(
        TextSpan(
          text: widget.value.substring(0, _ValueText.limit),
          children: [
            TextSpan(
              text: '… ${widget.value.length - _ValueText.limit} more',
              style: TextStyle(color: DebugPalette.of(context).muted),
            ),
          ],
        ),
        style: widget.style,
      ),
    );
  }
}

/// Color of a value given its runtime type name.
Color typeColor(BuildContext context, String? type) => switch (type) {
  'bool' => DebugPalette.of(context).warning,
  'int' || 'double' => DebugPalette.of(context).info,
  'String' => DebugPalette.of(context).accent,
  'List<String>' => DebugPalette.of(context).error,
  _ => DebugPalette.of(context).text,
};

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.type);

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = typeColor(context, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
