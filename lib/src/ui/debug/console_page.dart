// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/host/modal_layer.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/planish.dart';
import 'package:planish/src/ui/debug/console_view.dart';
import 'package:planish/src/ui/debug/tool_page_scaffold.dart';

/// Full-screen console with level filters.
class ConsolePage extends StatefulWidget {
  const ConsolePage({super.key});

  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  final GlobalKey<ConsoleViewState> _view = GlobalKey<ConsoleViewState>();

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    return ToolPageScaffold(
      title: s.console,
      actions: [
        IconButton(
          tooltip: s.openFloating,
          icon: const Icon(Icons.fullscreen_exit),
          onPressed: () {
            PlanishModal.of(context).close(null);
            Planish.showConsole();
          },
        ),
        IconButton(
          tooltip: s.copy,
          icon: const Icon(Icons.copy_outlined),
          onPressed: () =>
              copyToClipboard(context, _view.currentState?.visibleText ?? ''),
        ),
        IconButton(
          tooltip: s.clear,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _view.currentState?.clear(),
        ),
      ],
      body: ConsoleView(key: _view),
    );
  }
}
