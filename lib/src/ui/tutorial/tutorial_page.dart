import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/config.dart';
import 'package:planish/src/host/modal_layer.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/planish.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the tutorial was completed.
abstract final class TutorialState {
  static const String _key = 'planish.tutorial_done';

  /// Whether the user finished the tutorial once.
  static Future<bool> isDone() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } on Object {
      return true; // better to skip than to nag when storage is unavailable
    }
  }

  /// Marks the tutorial as finished (or not, to show it again).
  static Future<void> setDone({bool done = true}) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, done);
    } on Object {
      // Ignored: the tutorial will simply show again next time.
    }
  }
}

/// Four-step walkthrough: trigger, debug button, form, send.
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pages = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<_Step> _steps(PlanishLocalizations s) {
    final c = Planish.config;
    // When both use the shake, the debug tools win while they are enabled.
    final debugShake =
        Planish.debugTools.isAvailable &&
        c.debugTools.gestures.contains(TriggerGesture.shake);
    final reportShake = c.reportGestures.contains(TriggerGesture.shake);
    final (String body, _Illustration trigger) = debugShake
        ? (s.tutorialShakeBody, _Illustration.debugButton)
        : reportShake
        ? (
            c.quickReport.enabled
                ? s.tutorialShakeSheetBody
                : s.tutorialShakeFormBody,
            _Illustration.sheet,
          )
        : (s.tutorialOpenBody, _Illustration.menu);
    final shake = debugShake || reportShake;
    return <_Step>[
      _Step(
        icon: shake ? Icons.vibration : Icons.touch_app_outlined,
        title: shake ? s.tutorialShakeTitle : s.tutorialOpenTitle,
        body: body,
        illustration: _PhoneIllustration(trigger),
      ),
      _Step(
        icon: Icons.draw_outlined,
        title: s.tutorialAnnotateTitle,
        body: s.tutorialAnnotateBody,
        illustration: const _PhoneIllustration(_Illustration.annotate),
      ),
      _Step(
        icon: Icons.edit_note,
        title: s.tutorialDescribeTitle,
        body: s.tutorialDescribeBody,
        illustration: const _PhoneIllustration(_Illustration.describe),
      ),
      _Step(
        icon: Icons.send_outlined,
        title: s.tutorialSendTitle,
        body: s.tutorialSendBody,
        illustration: const _PhoneIllustration(_Illustration.send),
      ),
    ];
  }

  Future<void> _finish() => _close(finished: true);

  // Skipping counts as seen: the tutorial is shown once either way.
  Future<void> _skip() => _close(finished: false);

  Future<void> _close({required bool finished}) async {
    await TutorialState.setDone();
    if (mounted) {
      PlanishModal.of(context).close(finished);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final theme = Theme.of(context);
    final steps = _steps(s);
    final last = _step == steps.length - 1;
    final canSkip = Planish.config.tutorial.canSkip;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop && canSkip) {
          unawaited(_skip());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.tutorial),
          automaticallyImplyLeading: false,
          actions: [
            if (canSkip) TextButton(onPressed: _skip, child: Text(s.skip)),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: steps.length,
                  onPageChanged: (int i) => setState(() => _step = i),
                  itemBuilder: (BuildContext context, int i) =>
                      _StepView(step: steps[i], index: i),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    for (int i = 0; i < steps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _step ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: i == _step
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: last
                          ? _finish
                          : () => _pages.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                      child: Text(last ? s.done : s.next),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    required this.illustration,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget illustration;
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step, required this.index});

  final _Step step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      children: [
        Center(child: step.illustration),
        const SizedBox(height: 24),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(step.title, style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(step.body, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

enum _Illustration { debugButton, sheet, menu, annotate, describe, send }

/// A small phone frame with a schematic of the step.
class _PhoneIllustration extends StatefulWidget {
  const _PhoneIllustration(this.kind);

  final _Illustration kind;

  @override
  State<_PhoneIllustration> createState() => _PhoneIllustrationState();
}

class _PhoneIllustrationState extends State<_PhoneIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Widget phone = Container(
      width: 150,
      height: 260,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline, width: 3),
      ),
      padding: const EdgeInsets.all(12),
      child: _screen(colors),
    );
    if (widget.kind != _Illustration.debugButton &&
        widget.kind != _Illustration.sheet) {
      return phone;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) => Transform.rotate(
        angle: (_controller.value - 0.5) * 0.12,
        child: child,
      ),
      child: phone,
    );
  }

  Widget _screen(ColorScheme colors) {
    Widget line(double width, {bool spaced = true}) => Container(
      width: width,
      height: 8,
      margin: EdgeInsets.only(bottom: spaced ? 8 : 0),
      decoration: BoxDecoration(
        color: colors.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    switch (widget.kind) {
      case _Illustration.sheet:
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [line(80), line(110), line(60)],
            ),
            Positioned(
              left: -12,
              right: -12,
              bottom: -12,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    line(70),
                    const SizedBox(height: 8),
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.bug_report_outlined,
                        size: 14,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case _Illustration.menu:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line(60),
            const SizedBox(height: 14),
            for (final highlighted in const <bool>[false, true, false])
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: highlighted
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: highlighted
                      ? Border.all(color: colors.primary)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      highlighted
                          ? Icons.feedback_outlined
                          : Icons.circle_outlined,
                      size: 14,
                      color: highlighted ? colors.primary : colors.outline,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: line(highlighted ? 50 : 40)),
                  ],
                ),
              ),
          ],
        );
      case _Illustration.debugButton:
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [line(80), line(110), line(60)],
            ),
            Positioned(
              right: 0,
              top: 90,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colors.inverseSurface,
                child: Icon(
                  Icons.bug_report_outlined,
                  size: 18,
                  color: colors.onInverseSurface,
                ),
              ),
            ),
          ],
        );
      case _Illustration.annotate:
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(painter: _ScribblePainter(colors.error)),
        );
      case _Illustration.describe:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    size: 14,
                    color: colors.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: line(double.infinity, spaced: false)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip(colors, selected: true, icon: Icons.bug_report_outlined),
                const SizedBox(width: 6),
                _chip(colors, icon: Icons.lightbulb_outline),
                const SizedBox(width: 6),
                _chip(colors, icon: Icons.help_outline),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outline),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [line(80), line(100), line(56)],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _sendButton(colors),
          ],
        );
      case _Illustration.send:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.check_circle_rounded, size: 56, color: colors.primary),
            const SizedBox(height: 12),
            Center(child: line(72)),
            Center(child: line(48)),
            const Spacer(),
            _sendButton(colors, pressed: true),
          ],
        );
    }
  }

  Widget _sendButton(ColorScheme colors, {bool pressed = false}) => Container(
    height: 30,
    decoration: BoxDecoration(
      color: pressed ? colors.primaryContainer : colors.primary,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.send,
          size: 14,
          color: pressed ? colors.onPrimaryContainer : colors.onPrimary,
        ),
        const SizedBox(width: 6),
        Container(
          width: 28,
          height: 6,
          decoration: BoxDecoration(
            color: (pressed ? colors.onPrimaryContainer : colors.onPrimary)
                .withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    ),
  );

  Widget _chip(ColorScheme colors, {bool selected = false, IconData? icon}) =>
      Container(
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? colors.primary : colors.outline),
        ),
        child: icon == null
            ? null
            : Icon(
                icon,
                size: 12,
                color: selected ? colors.onPrimaryContainer : colors.outline,
              ),
      );
}

class _ScribblePainter extends CustomPainter {
  _ScribblePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.2, size.width * 0.7, 30),
      paint,
    );
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.55,
        size.width * 0.8,
        size.height * 0.7,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScribblePainter old) => old.color != color;
}
