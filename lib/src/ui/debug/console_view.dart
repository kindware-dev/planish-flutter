import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/log/log.dart';
import 'package:planish/src/ui/debug/debug_theme.dart';
import 'package:planish/src/ui/debug/tool_page_scaffold.dart';

/// Filtered, auto-scrolling list of [Log.entries]. Shared by the console page
/// and the floating console.
class ConsoleView extends StatefulWidget {
  const ConsoleView({super.key, this.compact = false});

  /// Tighter spacing and no level chips, for the floating panel.
  final bool compact;

  @override
  State<ConsoleView> createState() => ConsoleViewState();
}

/// State of [ConsoleView]; exposes copy and clear for toolbars.
class ConsoleViewState extends State<ConsoleView> {
  final ScrollController _scroll = ScrollController();
  StreamSubscription<LogEntry>? _subscription;
  bool _refreshScheduled = false;
  LogLevel _minLevel = LogLevel.trace;
  String _query = '';
  List<LogEntry> _visible = const <LogEntry>[];

  /// Entries currently shown, oldest first.
  List<LogEntry> get visible => _visible;

  /// Text of the visible entries.
  String get visibleText => Log.entriesAsText(_visible);

  @override
  void initState() {
    super.initState();
    _refresh(scrollToEnd: true);
    _subscription = Log.onEntry.listen((_) {
      // One rebuild per frame, however many entries arrive.
      if (_refreshScheduled) {
        return;
      }
      _refreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshScheduled = false;
        if (mounted) {
          _refresh(scrollToEnd: _isNearEnd);
        }
      });
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _scroll.dispose();
    super.dispose();
  }

  bool get _isNearEnd =>
      !_scroll.hasClients ||
      _scroll.position.maxScrollExtent - _scroll.position.pixels < 80;

  void _refresh({bool scrollToEnd = false}) {
    final q = _query.toLowerCase();
    setState(() {
      _visible = Log.entries
          .where((LogEntry e) => e.level >= _minLevel)
          .where(
            (LogEntry e) => q.isEmpty || e.format().toLowerCase().contains(q),
          )
          .toList();
    });
    if (scrollToEnd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  /// Empties the log buffer.
  void clear() {
    Log.clear();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12, widget.compact ? 6 : 8, 12, 8),
          child: Column(
            children: [
              TextField(
                // Explicit decoration: the host app's input theme (underline,
                // no fill, tall padding) must not leak into the console.
                decoration: InputDecoration(
                  hintText: s.filterHint,
                  hintStyle: TextStyle(
                    color: DebugPalette.of(context).muted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: DebugPalette.of(context).muted,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  filled: true,
                  fillColor: DebugPalette.of(context).surfaceHigh,
                  isDense: true,
                  contentPadding: const EdgeInsets.fromLTRB(0, 9, 12, 9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: DebugPalette.of(context).border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: DebugPalette.of(context).border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: DebugPalette.of(context).accent,
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: DebugPalette.of(context).text,
                ),
                onChanged: (String v) {
                  _query = v;
                  _refresh();
                },
              ),
              if (!widget.compact) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final LogLevel level in LogLevel.values) ...[
                        ChoiceChip(
                          label: Text(level.label),
                          visualDensity: VisualDensity.compact,
                          selected: _minLevel == level,
                          onSelected: (_) {
                            _minLevel = level;
                            _refresh();
                          },
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _visible.isEmpty
              ? EmptyHint(s.noLogs)
              : SelectionArea(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                    itemCount: _visible.length,
                    itemBuilder: (BuildContext context, int i) =>
                        _EntryTile(_visible[i], compact: widget.compact),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Color used for a log level in the console.
Color levelColor(BuildContext context, LogLevel level) => switch (level) {
  LogLevel.trace || LogLevel.debug => DebugPalette.of(context).dim,
  LogLevel.info => DebugPalette.of(context).info,
  LogLevel.warning => DebugPalette.of(context).warning,
  LogLevel.error || LogLevel.fatal => DebugPalette.of(context).error,
};

class _EntryTile extends StatelessWidget {
  const _EntryTile(this.entry, {required this.compact});

  final LogEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = levelColor(context, entry.level);
    final mono = monoStyle(
      context,
      color: DebugPalette.of(context).text,
    ).copyWith(fontSize: compact ? 11 : 12);
    final Widget line = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: entry.time.toIso8601String().substring(11, 23),
            style: mono.copyWith(color: DebugPalette.of(context).muted),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: entry.level.label.padRight(5),
            style: mono.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          if (entry.tag != null)
            TextSpan(
              text: ' [${entry.tag}]',
              style: mono.copyWith(color: DebugPalette.of(context).accent),
            ),
          TextSpan(text: ' ${entry.message}', style: mono),
        ],
      ),
    );
    final hasDetails = entry.errorText != null || entry.stackTrace != null;
    final padding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: compact ? 2 : 3,
    );
    if (!hasDetails) {
      return Padding(padding: padding, child: line);
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: padding,
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        dense: true,
        iconColor: DebugPalette.of(context).muted,
        collapsedIconColor: DebugPalette.of(context).muted,
        title: line,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              entry.formatFull(),
              style: mono.copyWith(color: DebugPalette.of(context).muted),
            ),
          ),
        ],
      ),
    );
  }
}
