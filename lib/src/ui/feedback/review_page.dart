// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/report/feedback_report.dart';
import 'package:planish/src/ui/debug/tool_page_scaffold.dart';

/// Shows the user exactly what a report contains before it is sent.
class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key, required this.report});

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final theme = Theme.of(context);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    return ToolPageScaffold(
      title: s.reviewTitle,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          header(s.message),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.category != null)
                  Text(
                    report.category!.displayLabel(context),
                    style: theme.textTheme.labelLarge,
                  ),
                SelectableText(
                  report.message.isEmpty ? s.emptyMessage : report.message,
                ),
                if (report.email != null)
                  Text(report.email!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (report.screenshot != null) ...[
            header(s.screenshot),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  report.screenshot!,
                  height: 160,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
          if (report.errorText != null) ...[
            header(s.error),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText(
                report.errorText!,
                style: monoStyle(context),
              ),
            ),
          ],
          header(s.deviceInfo),
          if (report.context.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(s.nothingCollected),
            )
          else ...[
            for (final MapEntry<String, String> e in report.context.entries)
              ListTile(
                dense: true,
                title: Text(e.key, style: theme.textTheme.labelMedium),
                subtitle: Text(e.value, style: monoStyle(context)),
              ),
          ],
          header(s.logsCount(report.logs.length)),
          if (report.logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(s.nothingCollected),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText(
                report.logs.reversed.take(50).map((e) => e.format()).join('\n'),
                style: monoStyle(context),
              ),
            ),
          if (report.attachments.isNotEmpty) ...[
            header(s.attachments),
            for (final FeedbackAttachment a in report.attachments)
              ListTile(
                dense: true,
                leading: const Icon(Icons.attach_file),
                title: Text(a.name),
              ),
          ],
        ],
      ),
    );
  }
}
