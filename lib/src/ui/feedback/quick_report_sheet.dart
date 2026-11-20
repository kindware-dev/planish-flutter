import 'dart:async';

// ignore: deprecated_member_use
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
        hint: s.quickProblemHint,
        category: FeedbackCategory.bug,
      ),
      QuickReportAction(
        icon: Icons.lightbulb_outline,
        label: s.quickShareIdea,
        hint: s.quickIdeaHint,
        category: FeedbackCategory.idea,
      ),
      QuickReportAction(
        icon: Icons.help_outline,
        label: s.quickAskQuestion,
        hint: s.quickQuestionHint,
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
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quick.subtitle?.call(context) ?? s.quickSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ActionList(
                            actions: actions,
                            onPick: (action) {
                              modal.close(null);
                              unawaited(
                                action.onTap?.call(context) ??
                                    Planish.show(category: action.category),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
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

/// The actions as rows of one card: tinted icon, label, optional hint.
class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions, required this.onPick});

  final List<QuickReportAction> actions;
  final ValueChanged<QuickReportAction> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, action) in actions.indexed) ...[
            if (i > 0) Divider(height: 1, color: colors.outlineVariant),
            InkWell(
              onTap: () => onPick(action),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action.icon, color: colors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (action.hint != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                action.hint!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.outline),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
