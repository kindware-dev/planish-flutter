import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/network/network_log.dart';
import 'package:planish/src/ui/debug/tool_page_scaffold.dart';

/// Lists [NetworkLog.calls]; tapping one opens its details.
class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = NetworkLog.onChange.listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final calls = NetworkLog.calls;
    return ToolPageScaffold(
      title: s.network,
      actions: [
        IconButton(
          tooltip: s.clear,
          icon: const Icon(Icons.delete_outline),
          onPressed: calls.isEmpty ? null : NetworkLog.clear,
        ),
      ],
      body: calls.isEmpty
          ? EmptyHint(s.noNetworkCalls)
          : ListView.separated(
              itemCount: calls.length,
              separatorBuilder: (BuildContext _, int _) =>
                  const Divider(height: 1),
              itemBuilder: (BuildContext context, int i) => _CallTile(calls[i]),
            ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile(this.call);

  final NetworkCall call;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = call.isFailure
        ? colors.error
        : call.isSuccess
        ? colors.primary
        : colors.onSurfaceVariant;
    return ListTile(
      leading: SizedBox(
        width: 56,
        child: Text(
          call.statusCode?.toString() ?? (call.error == null ? '-' : 'ERR'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: statusColor),
        ),
      ),
      title: Text(
        '${call.method} ${Uri.tryParse(call.url)?.path ?? call.url}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${Uri.tryParse(call.url)?.host ?? ''} · ${call.duration.inMilliseconds} ms',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => _CallDetailsPage(call)),
      ),
    );
  }
}

class _CallDetailsPage extends StatelessWidget {
  const _CallDetailsPage(this.call);

  final NetworkCall call;

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    return ToolPageScaffold(
      title: '${call.method} ${call.statusCode ?? ''}'.trim(),
      actions: [
        IconButton(
          tooltip: s.copy,
          icon: const Icon(Icons.copy_outlined),
          onPressed: () => copyToClipboard(context, _asText()),
        ),
      ],
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(call.url, style: monoStyle(context)),
            const SizedBox(height: 4),
            Text(
              '${call.startedAt.toIso8601String()} · ${call.duration.inMilliseconds} ms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (call.error != null) ...[
              _Section(s.error, call.error!, isError: true),
            ],
            _Section(
              '${s.request} · ${s.headers}',
              _headers(call.requestHeaders),
            ),
            if (call.requestBody?.isNotEmpty ?? false)
              _Section('${s.request} · ${s.body}', call.requestBody!),
            _Section(
              '${s.response} · ${s.headers}',
              _headers(call.responseHeaders),
            ),
            if (call.responseBody?.isNotEmpty ?? false)
              _Section('${s.response} · ${s.body}', call.responseBody!),
          ],
        ),
      ),
    );
  }

  String _headers(Map<String, String> h) => h.isEmpty
      ? '-'
      : h.entries
            .map((MapEntry<String, String> e) => '${e.key}: ${e.value}')
            .join('\n');

  String _asText() => <String>[
    call.summary,
    'Request headers:\n${_headers(call.requestHeaders)}',
    if (call.requestBody?.isNotEmpty ?? false)
      'Request body:\n${call.requestBody}',
    'Response headers:\n${_headers(call.responseHeaders)}',
    if (call.responseBody?.isNotEmpty ?? false)
      'Response body:\n${call.responseBody}',
    if (call.error != null) 'Error:\n${call.error}',
  ].join('\n\n');
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.content, {this.isError = false});

  final String title;
  final String content;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isError
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: monoStyle(
                context,
                color: isError ? theme.colorScheme.onErrorContainer : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
