import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/ui/planish_theme.dart';

/// Draggable floating button that opens the debug menu. Snaps to the nearest
/// horizontal edge when released.
class DebugButton extends StatefulWidget {
  const DebugButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<DebugButton> createState() => _DebugButtonState();
}

class _DebugButtonState extends State<DebugButton> {
  static const double _size = 48;
  static const double _margin = 12;

  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final saved = _position;
    final position = saved == null
        ? Offset(
            screen.width - _size - _margin,
            safe.top + screen.height * 0.25,
          )
        : Offset(
            saved.dx.clamp(_margin, screen.width - _size - _margin),
            saved.dy.clamp(
              safe.top + _margin,
              screen.height - safe.bottom - _size - _margin,
            ),
          );
    final colors = PlanishColors.of(Theme.of(context).brightness);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails d) => setState(() {
          _position = Offset(
            (position.dx + d.delta.dx).clamp(
              _margin,
              screen.width - _size - _margin,
            ),
            (position.dy + d.delta.dy).clamp(
              safe.top + _margin,
              screen.height - safe.bottom - _size - _margin,
            ),
          );
        }),
        onPanEnd: (_) => setState(() {
          final left = position.dx + _size / 2 < screen.width / 2;
          _position = Offset(
            left ? _margin : screen.width - _size - _margin,
            position.dy,
          );
        }),
        child: Semantics(
          button: true,
          label: context.planishStrings.debugButtonLabel,
          child: Material(
            color: colors.brand,
            elevation: 4,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              child: SizedBox.square(
                dimension: _size,
                child: Icon(Icons.bug_report_outlined, color: colors.onBrand),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
