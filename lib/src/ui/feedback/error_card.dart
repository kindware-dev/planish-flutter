import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';

/// The card shown over the app after an uncaught error (`prompts: notify`),
/// or the one-time question about keeping these quiet.
class ErrorCard extends StatelessWidget {
  const ErrorCard({
    required this.askQuiet,
    this.pendingDrafts,
    required this.onPrimary,
    required this.onSecondary,
    super.key,
  });

  /// Shows "Keep these quiet?" instead of the error card.
  final bool askQuiet;

  /// Set for the launch reminder: how many drafts wait to be sent.
  final int? pendingDrafts;

  /// "Add details", or "Keep quiet".
  final VoidCallback onPrimary;

  /// "Later", or "Keep showing".
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final drafts = pendingDrafts;
    final title = drafts != null
        ? s.draftsReminderTitle(drafts)
        : (askQuiet ? s.quietTitle : s.errorCardTitle);
    final body = drafts != null
        ? s.draftsReminderBody
        : (askQuiet ? s.quietBody : s.errorCardBody);
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.surfaceContainerLowest,
        elevation: 8,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: drafts != null
                          ? colors.primaryContainer
                          : colors.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      drafts != null
                          ? Icons.edit_note_outlined
                          : Icons.error_outline,
                      size: 20,
                      color: drafts != null ? colors.primary : colors.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(askQuiet ? s.keepShowing : s.later),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onPrimary,
                    child: Text(
                      drafts != null
                          ? s.openDraft
                          : (askQuiet ? s.keepQuiet : s.addDetails),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
