import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/debug/debug_plugin.dart';
import 'package:planish/src/host/modal_layer.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/planish.dart';
import 'package:planish/src/ui/debug/debug_theme.dart';

/// Bottom sheet listing the debug tools. Shown in a transparent modal so the
/// app stays visible behind the barrier. Tap the barrier, tap the handle or
/// swipe down to close.
class DebugMenuPage extends StatefulWidget {
  const DebugMenuPage({super.key});

  @override
  State<DebugMenuPage> createState() => _DebugMenuPageState();
}

class _DebugMenuPageState extends State<DebugMenuPage> {
  double _drag = 0;

  void _dragEnd(DragEndDetails d, PlanishModal modal) {
    if (_drag > 80 || (d.primaryVelocity ?? 0) > 500) {
      modal.close(null);
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final modal = PlanishModal.of(context);

    return DebugToolsTheme(
      // Builder: the palette must be read inside the tools theme.
      child: Builder(
        builder: (BuildContext context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => modal.close(null),
                child: Semantics(
                  button: true,
                  label: s.close,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, _drag),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Material(
                    color: DebugPalette.of(context).surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      side: BorderSide(color: DebugPalette.of(context).border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: (DragUpdateDetails d) =>
                                setState(
                                  () => _drag = (_drag + d.delta.dy).clamp(
                                    0,
                                    400,
                                  ),
                                ),
                            onVerticalDragEnd: (DragEndDetails d) =>
                                _dragEnd(d, modal),
                            child: Column(
                              children: [
                                _DragHandle(onTap: () => modal.close(null)),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    4,
                                    24,
                                    16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.bug_report_outlined,
                                        color: DebugPalette.of(context).accent,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        s.debugTools,
                                        style: TextStyle(
                                          color: DebugPalette.of(context).text,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(bottom: 8),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      modal.close(null);
                                      unawaited(Planish.show());
                                    },
                                    icon: const Icon(Icons.feedback_outlined),
                                    label: Text(s.sendFeedback),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final DebugPlugin plugin
                                    in Planish.debugPlugins)
                                  ListTile(
                                    leading: Icon(plugin.icon),
                                    title: Text(plugin.title(context)),
                                    trailing: plugin is DebugPagePlugin
                                        ? const Icon(Icons.chevron_right)
                                        : null,
                                    onTap: () =>
                                        unawaited(plugin.open(context)),
                                  ),
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.school_outlined),
                                  title: Text(s.tutorial),
                                  onTap: () {
                                    modal.close(null);
                                    unawaited(Planish.showTutorial());
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.visibility_off_outlined,
                                  ),
                                  title: Text(s.hideDebugButton),
                                  onTap: () {
                                    Planish.debugTools.hide();
                                    modal.close(null);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.planishStrings.close,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 28,
        width: double.infinity,
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: DebugPalette.of(context).muted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    ),
  );
}
