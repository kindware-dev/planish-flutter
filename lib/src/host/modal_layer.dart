import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// Gives pages shown by the host a way to close themselves with a result.
class PlanishModal extends InheritedWidget {
  const PlanishModal({super.key, required this.close, required super.child});

  final void Function(Object? result) close;

  static PlanishModal of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlanishModal>();
    assert(scope != null, 'No PlanishModal above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(PlanishModal oldWidget) => close != oldWidget.close;
}

/// Bookkeeping for one open modal.
class ModalEntry {
  ModalEntry({
    required this.builder,
    required this.opaque,
    this.dismissible = true,
  });

  final WidgetBuilder builder;

  final bool opaque;

  /// Whether the Android back button may close it.
  final bool dismissible;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final GlobalKey<ModalLayerState> layerKey = GlobalKey<ModalLayerState>();

  final Completer<Object?> completer = Completer<Object?>();
}

/// Animated container for a [ModalEntry]: slides and fades in, hosts its own
/// navigator and scaffold messenger so dialogs and snack bars stay inside.
class ModalLayer extends StatefulWidget {
  const ModalLayer({super.key, required this.entry, required this.onClose});

  final ModalEntry entry;

  final void Function(Object? result) onClose;

  @override
  State<ModalLayer> createState() => ModalLayerState();
}

/// State of [ModalLayer].
class ModalLayerState extends State<ModalLayer>
    with SingleTickerProviderStateMixin {
  final HeroController _heroController = HeroController();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
  }

  /// Plays the exit animation, then reports [result].
  Future<void> close(Object? result) async {
    if (_closing) {
      return;
    }
    _closing = true;
    await _controller.reverse();
    if (mounted) {
      widget.onClose(result);
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curve),
        child: PlanishModal(
          close: close,
          child: ScaffoldMessenger(
            child: HeroControllerScope(
              controller: _heroController,
              child: Navigator(
                key: widget.entry.navigatorKey,
                onGenerateRoute: (RouteSettings settings) =>
                    PageRouteBuilder<void>(
                      settings: settings,
                      opaque: widget.entry.opaque,
                      pageBuilder:
                          (
                            BuildContext c,
                            Animation<double> _,
                            Animation<double> _,
                          ) => widget.entry.builder(c),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
