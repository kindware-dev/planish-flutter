import 'dart:async';

import 'package:flutter/material.dart';
import 'package:planish/src/config.dart';
import 'package:planish/src/host/modal_layer.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/planish.dart';
import 'package:planish/src/report/feedback_report.dart';

/// The small "Share feedback" sheet shown by a feedback gesture, in the
/// style of Google or Instagram apps. Picking an action opens the full form
/// with that category preselected.
class QuickReportSheet extends StatefulWidget {
  const QuickReportSheet({super.key});

  /// Actions shown when the config does not provide its own.
  static List<QuickReportAction> defaultActions(BuildContext context) {
    final s = context.planishStrings;
    return [
      QuickReportAction(
        icon: Icons.bug_report_outlined,
        label: s.quickReportProblem,
        category: FeedbackCategory.bug,
      ),
      QuickReportAction(
        icon: Icons.lightbulb_outline,
        label: s.quickShareIdea,
        category: FeedbackCategory.idea,
      ),
      QuickReportAction(
        icon: Icons.help_outline,
        label: s.quickAskQuestion,
        category: FeedbackCategory.question,
      ),
    ];
  }

  @override
  State<QuickReportSheet> createState() => _QuickReportSheetState();
}

class _QuickReportSheetState extends State<QuickReportSheet> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final theme = Theme.of(context);
    final modal = PlanishModal.of(context);
    final actions =
        Planish.config.quickReport.actions?.call(context) ??
        QuickReportSheet.defaultActions(context);
    final quick = Planish.config.quickReport;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => modal.close(null),
            child: Semantics(
              button: true,
              label: s.cancel,
              child: ColoredBox(
                color: theme.colorScheme.scrim.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(0, _drag),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (d) =>
                  setState(() => _drag = (_drag + d.delta.dy).clamp(0, 400)),
              onVerticalDragEnd: (d) {
                if (_drag > 60 || (d.primaryVelocity ?? 0) > 500) {
                  modal.close(null);
                } else {
                  setState(() => _drag = 0);
                }
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Material(
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            button: true,
                            label: s.cancel,
                            child: InkWell(
                              onTap: () => modal.close(null),
                              child: Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            quick.title?.call(context) ?? s.quickTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quick.subtitle?.call(context) ?? s.quickSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final action in actions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: FilledButton.tonalIcon(
                                onPressed: () {
                                  modal.close(null);
                                  unawaited(
                                    action.onTap?.call(context) ??
                                        Planish.show(category: action.category),
                                  );
                                },
                                icon: Icon(action.icon),
                                label: Text(action.label),
                                style: FilledButton.styleFrom(
                                  alignment: AlignmentDirectional.centerStart,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          TextButton(
                            onPressed: () => modal.close(null),
                            child: Text(s.cancel),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
