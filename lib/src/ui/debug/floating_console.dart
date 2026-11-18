import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/ui/debug/console_view.dart';
import 'package:planish/src/ui/debug/debug_theme.dart';
import 'package:planish/src/ui/debug/tool_page_scaffold.dart';

/// Log window floating over the app. Drag the title bar to move it, the
/// bottom-right corner to resize it. The app stays usable around it.
class FloatingConsole extends StatefulWidget {
  const FloatingConsole({
    super.key,
    required this.onClose,
    required this.onExpand,
  });

  final VoidCallback onClose;
  final VoidCallback onExpand;

  @override
  State<FloatingConsole> createState() => _FloatingConsoleState();
}

class _FloatingConsoleState extends State<FloatingConsole> {
  static const double _minWidth = 240;
  static const double _minHeight = 140;
  static const double _barHeight = 36;
  static const double _margin = 8;

  final GlobalKey<ConsoleViewState> _view = GlobalKey<ConsoleViewState>();
  Rect? _frame;

  Rect _initialFrame(Size screen, EdgeInsets safe) {
    final width = screen.width - 2 * _margin;
    final height = screen.height * 0.35;
    // Above the bottom safe area and a typical bottom navigation bar.
    final bottom = screen.height - safe.bottom - 80;
    return Rect.fromLTWH(_margin, bottom - height, width, height);
  }

  Rect _clamp(Rect r, Size screen, EdgeInsets safe) {
    final width = r.width.clamp(_minWidth, screen.width - 2 * _margin);
    final height = r.height.clamp(
      _minHeight,
      screen.height - safe.top - safe.bottom - 2 * _margin,
    );
    final left = r.left.clamp(_margin, screen.width - width - _margin);
    final top = r.top.clamp(
      safe.top + _margin,
      screen.height - safe.bottom - height - _margin,
    );
    return Rect.fromLTWH(left, top, width, height);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final frame = _clamp(_frame ?? _initialFrame(screen, safe), screen, safe);

    return Positioned.fromRect(
      rect: frame,
      child: DebugToolsTheme(
        child: Builder(
          builder: (BuildContext context) => Material(
            color: DebugPalette.of(context).background,
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: DebugPalette.of(context).border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (d) => setState(() {
                        _frame = _clamp(frame.shift(d.delta), screen, safe);
                      }),
                      child: SizedBox(
                        height: _barHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 12),
                            Icon(
                              Icons.terminal,
                              size: 16,
                              color: DebugPalette.of(context).accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.console,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: DebugPalette.of(context).text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  height: 1,
                                ),
                              ),
                            ),
                            _BarButton(
                              size: 17,
                              icon: Icons.content_copy,
                              tooltip: s.copy,
                              onPressed: () => copyToClipboard(
                                context,
                                _view.currentState?.visibleText ?? '',
                              ),
                            ),
                            _BarButton(
                              icon: Icons.delete_outline,
                              tooltip: s.clear,
                              onPressed: () => _view.currentState?.clear(),
                            ),
                            _BarButton(
                              size: 22,
                              icon: Icons.fullscreen,
                              tooltip: s.openFullScreen,
                              onPressed: widget.onExpand,
                            ),
                            _BarButton(
                              size: 20,
                              icon: Icons.close,
                              tooltip: s.close,
                              onPressed: widget.onClose,
                            ),
                            const SizedBox(width: 2),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Expanded(child: ConsoleView(key: _view, compact: true)),
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) => setState(() {
                      _frame = _clamp(
                        Rect.fromLTWH(
                          frame.left,
                          frame.top,
                          frame.width + d.delta.dx,
                          frame.height + d.delta.dy,
                        ),
                        screen,
                        safe,
                      );
                    }),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.signal_cellular_4_bar,
                        size: 12,
                        color: DebugPalette.of(context).muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 18,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  // Hand-rolled rather than IconButton: Material 3 pads its icons to a
  // 48 px target and the glyph ends up off-center in a 36 px bar.
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkResponse(
      onTap: onPressed,
      radius: 20,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Icon(icon, size: size, color: DebugPalette.of(context).muted),
        ),
      ),
    ),
  );
}
