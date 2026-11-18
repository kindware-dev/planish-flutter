import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:planish/src/config.dart';
import 'package:planish/src/debug/debug_tools_controller.dart';
import 'package:planish/src/env.dart';
import 'package:planish/src/host/gestures/gesture_detectors.dart';
import 'package:planish/src/host/modal_layer.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/log/log.dart';
import 'package:planish/src/planish.dart';
import 'package:planish/src/ui/debug/console_page.dart';
import 'package:planish/src/ui/debug/debug_button.dart';
import 'package:planish/src/ui/debug/debug_menu_page.dart';
import 'package:planish/src/ui/debug/debug_theme.dart';
import 'package:planish/src/ui/debug/floating_console.dart';
import 'package:planish/src/ui/tutorial/tutorial_page.dart';

/// Inserted by `Planish.builder()` above the app's navigator.
///
/// Owns the screenshot boundary, the gesture detectors, the floating debug
/// button and the stack of modals (feedback form, debug pages).
class PlanishHost extends StatefulWidget {
  const PlanishHost({
    super.key,
    required this.config,
    required this.debugTools,
    required this.child,
  });

  final PlanishConfig config;

  final DebugToolsController debugTools;

  final Widget child;

  @override
  State<PlanishHost> createState() => PlanishHostState();
}

/// State of [PlanishHost]. `Planish` talks to [current].
class PlanishHostState extends State<PlanishHost> {
  static PlanishHostState? current;

  /// Lets a test that runs under `runAsync` exercise the capture.
  @visibleForTesting
  static bool captureInTests = false;

  final GlobalKey _boundaryKey = GlobalKey();
  final List<ModalEntry> _modals = <ModalEntry>[];
  String Function(PlanishLocalizations)? _toast;
  Widget? _card;
  bool _consoleVisible = false;
  Timer? _toastTimer;

  /// Whether a modal is open.
  bool get hasOpenModal => _modals.isNotEmpty;

  @override
  void initState() {
    super.initState();
    current = this;
    widget.debugTools.addListener(_onDebugToolsChanged);
    if (widget.config.tutorial.showOnFirstLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
    }
  }

  Future<void> _maybeShowTutorial() async {
    if (await TutorialState.isDone() || !mounted || hasOpenModal) {
      return;
    }
    await showModal<bool>((context) {
      final theme = Planish.config.theme;
      return theme == null
          ? const TutorialPage()
          : Theme(data: theme(context), child: const TutorialPage());
    }, dismissible: Planish.config.tutorial.canSkip);
  }

  /// Shows or hides the floating console.
  void setConsoleVisible({required bool visible}) {
    if (_consoleVisible != visible) {
      setState(() => _consoleVisible = visible);
    }
  }

  void _openFullConsole() {
    setConsoleVisible(visible: false);
    unawaited(
      showModal<void>((_) => const DebugToolsTheme(child: ConsolePage())),
    );
  }

  // Gestures and overlays depend on whether the tools are available, which
  // can change at run time.
  void _onDebugToolsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      if (!widget.debugTools.isAvailable) {
        _consoleVisible = false;
      }
    });
  }

  void _onGesture(TriggerGesture gesture) {
    final c = widget.config;
    if (widget.debugTools.isAvailable &&
        c.debugTools.gestures.contains(gesture)) {
      widget.debugTools.toggle();
    } else if (c.reportGestures.contains(gesture)) {
      unawaited(Planish.prompt());
    }
  }

  @override
  void dispose() {
    widget.debugTools.removeListener(_onDebugToolsChanged);
    _toastTimer?.cancel();
    if (current == this) {
      current = null;
    }
    super.dispose();
  }

  /// Confirms a successful send at the bottom of the screen for a few seconds.
  /// Shows a package string at the bottom for three seconds. The string is
  /// picked inside the toast, below the package's localizations.
  void showToast(String Function(PlanishLocalizations) message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _toast = null);
      }
    });
  }

  /// Shows [card] over the app, above the toast; null removes it.
  void showCard(Widget? card) {
    if (mounted) {
      setState(() => _card = card);
    }
  }

  /// Renders the app (modals excluded) to a PNG no wider than [maxWidth]
  /// logical pixels at device resolution. Returns null when capture fails.
  Future<Uint8List?> captureScreenshot({double maxWidth = 1280}) async {
    // Image encoding runs on the engine, outside flutter_test's fake clock;
    // it would never complete and the form would never open.
    if (isFlutterTest && !captureInTests) {
      return null;
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    try {
      // Let any pending frame paint first; toImage() asserts otherwise.
      await SchedulerBinding.instance.endOfFrame;
      final render = _boundaryKey.currentContext?.findRenderObject();
      if (render is! RenderRepaintBoundary || render.debugNeedsPaint) {
        return null;
      }
      final double ratio = math.min(
        dpr,
        maxWidth / math.max(1, render.size.width),
      );
      final image = await render.toImage(pixelRatio: ratio);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } on Object catch (e, s) {
      Log.warning(
        'Screenshot capture failed',
        error: e,
        stackTrace: s,
        tag: 'feedback',
      );
      return null;
    }
  }

  /// Shows [builder] in a new modal layer and completes with its result.
  Future<T?> showModal<T>(
    WidgetBuilder builder, {
    bool opaque = true,
    bool dismissible = true,
  }) {
    final entry = ModalEntry(
      builder: builder,
      opaque: opaque,
      dismissible: dismissible,
    );
    setState(() => _modals.add(entry));
    return entry.completer.future.then((Object? r) => r as T?);
  }

  /// Back button: pops a page inside the top modal, or closes it.
  /// Returns false when no modal is open.
  bool handleBack() {
    if (_modals.isEmpty) {
      return false;
    }
    final top = _modals.last;
    final nav = top.navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else if (top.dismissible) {
      unawaited(top.layerKey.currentState?.close(null));
    }
    return true;
  }

  void _remove(ModalEntry entry, Object? result) {
    if (!mounted) {
      return;
    }
    setState(() => _modals.remove(entry));
    if (!entry.completer.isCompleted) {
      entry.completer.complete(result);
    }
  }

  void _openDebugMenu() {
    if (hasOpenModal) {
      return;
    }
    unawaited(showModal<void>((_) => const DebugMenuPage(), opaque: false));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final tools = c.debugTools;
    final active = <TriggerGesture>{
      ...c.reportGestures,
      if (widget.debugTools.isAvailable) ...tools.gestures,
    };
    Widget app = RepaintBoundary(key: _boundaryKey, child: widget.child);

    if (active.contains(TriggerGesture.multiFingerTap)) {
      app = MultiFingerTapDetector(
        config: c.gestures.multiFingerTap,
        onTrigger: () => _onGesture(TriggerGesture.multiFingerTap),
        child: app,
      );
    }
    if (active.contains(TriggerGesture.edgeSwipe)) {
      app = EdgeSwipeDetector(
        config: c.gestures.edgeSwipe,
        onSwipe: () => _onGesture(TriggerGesture.edgeSwipe),
        child: app,
      );
    }
    if (active.contains(TriggerGesture.shake)) {
      app = ShakeDetector(
        config: c.gestures.shake,
        onShake: () => _onGesture(TriggerGesture.shake),
        child: app,
      );
    }

    return withPackageLocalizations(
      context,
      Stack(
        children: [
          app,
          if (widget.debugTools.isAvailable)
            ListenableBuilder(
              listenable: widget.debugTools,
              builder: (BuildContext _, Widget? _) =>
                  widget.debugTools.isVisible && !hasOpenModal
                  ? DebugToolsTheme(
                      child: DebugButton(onPressed: _openDebugMenu),
                    )
                  : const SizedBox.shrink(),
            ),
          if (widget.debugTools.isAvailable && _consoleVisible)
            // Own overlay: tooltips and menus inside the panel need one, and
            // the app's navigator is below us.
            Positioned.fill(
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (BuildContext _) => Stack(
                      children: [
                        FloatingConsole(
                          onClose: () => setConsoleVisible(visible: false),
                          onExpand: _openFullConsole,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_toast != null) _Toast(_toast!),
          if (_card != null && !hasOpenModal)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: _card!,
            ),
          for (final ModalEntry entry in _modals)
            Positioned.fill(
              child: ModalLayer(
                key: entry.layerKey,
                entry: entry,
                onClose: (Object? result) => _remove(entry, result),
              ),
            ),
        ],
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast(this.pick);

  final String Function(PlanishLocalizations) pick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message = pick(context.planishStrings);
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 16,
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: colors.inverseSurface,
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                message,
                style: TextStyle(color: colors.onInverseSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
