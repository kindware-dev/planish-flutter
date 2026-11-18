import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planish/src/host/modal_layer.dart';
import 'package:planish/src/l10n/l10n.dart';

/// Common chrome for debug pages: app bar with back button and actions.
class ToolPageScaffold extends StatelessWidget {
  const ToolPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottom,
  });

  final String title;

  final Widget body;

  final List<Widget> actions;

  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    // First page of a modal: nothing to pop, so offer a close button instead.
    final root = !Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: root
            ? IconButton(
                tooltip: context.planishStrings.close,
                icon: const Icon(Icons.close),
                onPressed: () => PlanishModal.of(context).close(null),
              )
            : null,
        actions: actions,
        bottom: bottom,
      ),
      // Edge to edge (Android 15): keep content above the navigation bar.
      body: SafeArea(top: false, child: body),
    );
  }
}

/// Copies [text] and confirms with a snack bar.
Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.planishStrings.copied)));
  }
}

/// Centered hint for empty lists.
class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

/// Monospace style used for logs and bodies.
TextStyle monoStyle(BuildContext context, {Color? color}) =>
    Theme.of(context).textTheme.bodySmall!.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const <String>['Menlo', 'Courier New', 'monospace'],
      color: color,
    );
