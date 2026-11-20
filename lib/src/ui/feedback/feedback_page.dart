import 'dart:async';
import 'dart:typed_data';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:planish/src/config.dart';
import 'package:planish/src/host/modal_layer.dart';
import 'package:planish/src/l10n/l10n.dart';
import 'package:planish/src/log/log.dart';
import 'package:planish/src/planish.dart';
import 'package:planish/src/report/drafts.dart';
import 'package:planish/src/report/feedback_report.dart';
import 'package:planish/src/ui/feedback/annotate_page.dart';
import 'package:planish/src/ui/feedback/review_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The feedback form: category, message, attachments (screenshot, logs,
/// review), optional email, pinned send button.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({
    super.key,
    this.screenshot,
    this.error,
    this.stackTrace,
    this.initialCategory,
    this.frozen,
    this.draft,
  });

  final Uint8List? screenshot;

  final Object? error;

  final StackTrace? stackTrace;

  /// Preselected category, e.g. from the quick report sheet.
  final FeedbackCategory? initialCategory;

  /// The context taken when the form opened; a draft keeps it.
  final Future<FrozenContext>? frozen;

  /// Opens on this draft (an automatic one, from the error card).
  final FeedbackDraft? draft;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const String _emailKey = 'planish.user_email';

  final TextEditingController _message = TextEditingController();
  final TextEditingController _email = TextEditingController();
  Uint8List? _screenshot;
  FeedbackCategory? _category;
  bool _includeLogs = true;
  bool _sending = false;
  String? _failure;

  // The report in the form: a new one, or a draft being continued.
  String _id = FeedbackReport.newId();
  DateTime _createdAt = DateTime.now();
  Future<FrozenContext>? _frozen;
  int? _frozenLogs;
  DraftSource _source = DraftSource.manual;
  String? _relatedTo;
  bool _stored = false;
  bool _annotated = false;
  bool _userAnnotated = false;
  String? _draftError;
  // Sent or discarded: closing must not keep it.
  bool _settled = false;
  List<FeedbackDraft> _drafts = const <FeedbackDraft>[];
  FeedbackDraft? _offer;

  PlanishConfig get _config => Planish.config;

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
    _screenshot = widget.screenshot;
    _category = widget.initialCategory;
    _frozen = widget.frozen;
    _frozen?.then((FrozenContext f) {
      if (mounted) {
        setState(() => _frozenLogs = f.logs.length);
      }
    }).ignore();
    final draft = widget.draft;
    if (draft == null) {
      _loadDrafts(offer: true).ignore();
    } else {
      _continue(draft).then((_) => _loadDrafts()).ignore();
    }
    if (_category == null && _config.categories.length == 1) {
      _category = _config.categories.first;
    }
    if (_config.askEmail) {
      SharedPreferences.getInstance()
          .then((p) => _email.text = p.getString(_emailKey) ?? '')
          .ignore();
    }
  }

  Future<void> _loadDrafts({bool offer = false}) async {
    final all = await activeDraftStore?.list() ?? const <FeedbackDraft>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _drafts = all.where((FeedbackDraft d) => d.id != _id).toList();
      if (offer && _drafts.isNotEmpty) {
        _offer = _drafts.first;
      }
    });
  }

  /// Keeps the form as a draft when it has content; an emptied stored draft
  /// is removed.
  void _keepDraft() {
    final store = activeDraftStore;
    if (store == null || _settled) {
      return;
    }
    final message = _message.text;
    if (message.trim().isEmpty && !_annotated) {
      if (_stored) {
        store.discard(_id).ignore();
      }
      return;
    }
    final email = _email.text.trim();
    final id = _id;
    final source = _source;
    final relatedTo = _relatedTo;
    final createdAt = _createdAt;
    final category = _category?.id;
    final screenshot = _screenshot;
    final touched =
        source != DraftSource.automatic ||
        message.trim().isNotEmpty ||
        _userAnnotated;
    final frozen =
        _frozen ?? Future<FrozenContext>.value(const FrozenContext());
    frozen
        .then(
          (FrozenContext f) => store.save(
            FeedbackDraft(
              id: id,
              source: source,
              touched: touched,
              createdAt: createdAt,
              updatedAt: DateTime.now(),
              message: message,
              categoryId: category,
              email: email.isEmpty ? null : email,
              frozen: f,
              relatedTo: relatedTo,
            ),
            screenshot: screenshot,
            removeScreenshot: screenshot == null,
          ),
        )
        .ignore();
  }

  Future<void> _continue(FeedbackDraft d) async {
    final shot = d.hasScreenshot
        ? await activeDraftStore?.screenshot(d.id)
        : null;
    if (!mounted) {
      return;
    }
    setState(() {
      _id = d.id;
      _createdAt = d.createdAt;
      _frozen = Future<FrozenContext>.value(d.frozen);
      _frozenLogs = d.frozen.logs.length;
      _source = d.source;
      _relatedTo = d.relatedTo;
      _draftError = d.frozen.error;
      _stored = true;
      _annotated = d.message.trim().isEmpty;
      _message.text = d.message;
      if (d.email != null) {
        _email.text = d.email!;
      }
      for (final c in _config.categories) {
        if (c.id == d.categoryId) {
          _category = c;
        }
      }
      _screenshot = shot;
      _offer = null;
      _drafts = _drafts.where((FeedbackDraft x) => x.id != d.id).toList();
    });
  }

  Future<void> _discard() async {
    _settled = true;
    await activeDraftStore?.discard(_id);
    if (mounted) {
      PlanishModal.of(context).close(null);
    }
  }

  Future<void> _showDrafts() async {
    final picked = await showModalBottomSheet<FeedbackDraft>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) => _inFormTheme(
        SafeArea(
          top: false,
          child: _DraftsSheet(
            drafts: _drafts,
            categories: _config.categories,
            onDelete: (FeedbackDraft d) async {
              await activeDraftStore?.discard(d.id);
              await _loadDrafts();
              if (mounted && _offer?.id == d.id) {
                setState(() => _offer = null);
              }
              return _drafts;
            },
          ),
        ),
      ),
    );
    if (picked != null) {
      await _continue(picked);
    }
  }

  @override
  void dispose() {
    _keepDraft();
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _hasError => widget.error != null || _draftError != null;

  bool get _canSend =>
      !_sending &&
      (_message.text.trim().isNotEmpty || _hasError) &&
      !(_config.categoryRequired &&
          _config.categories.isNotEmpty &&
          _category == null);

  // Routes are built under the navigator, above the form's theme: pass it on.
  Widget _inFormTheme(Widget page) =>
      Theme(data: Theme.of(context), child: page);

  Future<void> _annotate() async {
    final edited = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        fullscreenDialog: true,
        builder: (_) => _inFormTheme(AnnotatePage(image: _screenshot!)),
      ),
    );
    if (edited != null && mounted) {
      setState(() {
        _screenshot = edited;
        _annotated = true;
        _userAnnotated = true;
      });
    }
  }

  Future<void> _review() async {
    final report = await _buildReport();
    if (mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _inFormTheme(ReviewPage(report: report)),
        ),
      );
    }
  }

  Future<FeedbackReport> _buildReport() async => Planish.buildReport(
    message: _message.text.trim(),
    category: _category,
    screenshot: _screenshot,
    error: widget.error,
    stackTrace: widget.stackTrace,
    includeLogs: _includeLogs,
    email: _config.askEmail && _email.text.trim().isNotEmpty
        ? _email.text.trim()
        : null,
    frozen: await _frozen,
    id: _id,
    source: ReportSource.values.byName(_source.name),
    relatedTo: _relatedTo,
  );

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _failure = null;
    });
    final result = await Planish.send(await _buildReport());
    if (_config.askEmail) {
      SharedPreferences.getInstance()
          .then((p) => p.setString(_emailKey, _email.text.trim()))
          .ignore();
    }
    if (!mounted) {
      return;
    }
    final s = context.planishStrings;
    switch (result) {
      case FeedbackSent() || FeedbackHandedOff():
        _settled = true;
        activeDraftStore?.discard(_id).ignore();
        PlanishModal.of(context).close(result);
      case FeedbackCancelled():
        setState(() {
          _sending = false;
          _failure = s.sendCancelled;
        });
      case FeedbackFailed(:final String message):
        setState(() {
          _sending = false;
          _failure = s.sendFailed(message);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final privacy = _config.privacy;
    final isError = _hasError;

    final hasAttachments =
        _screenshot != null || privacy.includeLogs || privacy.letUserReviewData;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop && !_sending) {
          PlanishModal.of(context).close(null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            isError ? s.reportProblemTitle : s.sendFeedbackTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            tooltip: s.cancel,
            icon: const Icon(Icons.close),
            onPressed: _sending
                ? null
                : () => PlanishModal.of(context).close(null),
          ),
          actions: [
            if (_drafts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ActionChip(
                  label: Text(s.drafts),
                  avatar: _CountBadge(_drafts.length),
                  onPressed: _sending ? null : _showDrafts,
                ),
              ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: FocusManager.instance.primaryFocus?.unfocus,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _sending ? 0.6 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        if (_offer != null) ...[
                          _DraftOffer(
                            draft: _offer!,
                            onContinue: () => _continue(_offer!),
                            onDismiss: () => setState(() => _offer = null),
                          ),
                          const SizedBox(height: 22),
                        ],
                        if (isError) ...[
                          _ErrorBanner(text: s.errorBanner),
                          const SizedBox(height: 22),
                        ],
                        if (_config.categories.isNotEmpty) ...[
                          _SectionLabel(
                            s.category,
                            required: _config.categoryRequired,
                          ),
                          _CategorySelector(
                            categories: _config.categories,
                            selected: _category,
                            onChanged: _sending
                                ? null
                                : (c) => setState(() => _category = c),
                          ),
                          const SizedBox(height: 22),
                        ],
                        TextField(
                          controller: _message,
                          enabled: !_sending,
                          minLines: 5,
                          maxLines: 8,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText:
                                _category?.hintBuilder?.call(context) ??
                                s.messageHint,
                            filled: true,
                            fillColor: colors.surfaceContainerLowest,
                            border: fieldBorder,
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (hasAttachments) ...[
                          const SizedBox(height: 22),
                          _SectionLabel(s.attachments),
                          _AttachmentsCard(
                            children: [
                              if (_screenshot != null)
                                _ScreenshotTile(
                                  bytes: _screenshot!,
                                  onAnnotate: _sending ? null : _annotate,
                                  onRemove: _sending
                                      ? null
                                      : () =>
                                            setState(() => _screenshot = null),
                                ),
                              if (privacy.includeLogs)
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: const _TileIcon(Icons.terminal),
                                  title: Text(s.includeLogs),
                                  subtitle: Text(
                                    '${s.logsCount(_frozenLogs ?? Log.entries.length)} · ${s.frozenHint}',
                                  ),
                                  trailing: Switch(
                                    value: _includeLogs,
                                    onChanged: _sending
                                        ? null
                                        : (bool v) =>
                                              setState(() => _includeLogs = v),
                                  ),
                                  onTap: _sending
                                      ? null
                                      : () => setState(
                                          () => _includeLogs = !_includeLogs,
                                        ),
                                ),
                              if (privacy.letUserReviewData)
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: SizedBox(
                                    width: 44,
                                    child: Icon(
                                      Icons.visibility_outlined,
                                      color: colors.primary,
                                    ),
                                  ),
                                  title: Text(
                                    s.reviewData,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _sending ? null : _review,
                                ),
                            ],
                          ),
                        ],
                        if (_config.askEmail) ...[
                          const SizedBox(height: 22),
                          TextField(
                            controller: _email,
                            enabled: !_sending,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: s.yourEmail,
                              filled: true,
                              fillColor: colors.surfaceContainerLowest,
                              border: fieldBorder,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant, width: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_failure != null) ...[
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: colors.error),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _failure!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: _canSend ? _send : null,
                            icon: _sending
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _failure != null
                                        ? Icons.refresh
                                        : Icons.send_outlined,
                                  ),
                            label: Text(_failure != null ? s.retry : s.send),
                          ),
                        ),
                        if (_stored)
                          TextButton(
                            onPressed: _sending ? null : _discard,
                            child: Text(s.discardDraft),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],
        ),
        style: style,
      ),
    );
  }
}

/// Single-row segmented control: icon above label. Tapping the selected
/// segment clears the selection (same behavior as the former ChoiceChips).
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<FeedbackCategory> categories;
  final FeedbackCategory? selected;
  final ValueChanged<FeedbackCategory?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final FeedbackCategory c in categories)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _Segment(
                  category: c,
                  selected: selected == c,
                  onTap: onChanged == null
                      ? null
                      : () => onChanged!(selected == c ? null : c),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.category, required this.selected, this.onTap});

  final FeedbackCategory category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fg = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.surfaceContainerLowest : Colors.transparent,
        elevation: selected ? 1 : 0,
        animationDuration: Duration.zero,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (category.icon != null)
                  Icon(category.icon, size: 20, color: fg),
                const SizedBox(height: 3),
                Text(
                  category.displayLabel(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  const _AttachmentsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: colors.onSurfaceVariant),
    );
  }
}

class _ScreenshotTile extends StatelessWidget {
  const _ScreenshotTile({required this.bytes, this.onAnnotate, this.onRemove});

  final Uint8List bytes;
  final VoidCallback? onAnnotate;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          Semantics(
            label: s.screenshot,
            image: true,
            child: InkWell(
              onTap: onAnnotate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(s.screenshot, style: theme.textTheme.titleSmall),
          ),
          IconButton(
            tooltip: s.annotate,
            color: colors.primary,
            icon: const Icon(Icons.draw_outlined),
            onPressed: onAnnotate,
          ),
          IconButton(
            tooltip: s.removeScreenshot,
            color: colors.onSurfaceVariant,
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "Unsent draft": offered when the form opens and a draft exists.
class _DraftOffer extends StatelessWidget {
  const _DraftOffer({
    required this.draft,
    required this.onContinue,
    required this.onDismiss,
  });

  final FeedbackDraft draft;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final faint = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final where = [_ago(context, draft.updatedAt), ?draft.screen].join(' · ');
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.unsentDraft, style: faint)),
                Text(where, style: faint),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _firstLine(draft),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton(
                  onPressed: onContinue,
                  child: Text(s.continueDraft),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: onDismiss, child: Text(s.notNow)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The drafts kept on the device: continue one (pops it) or delete it.
class _DraftsSheet extends StatefulWidget {
  const _DraftsSheet({
    required this.drafts,
    required this.categories,
    required this.onDelete,
  });

  final List<FeedbackDraft> drafts;
  final List<FeedbackCategory> categories;
  final Future<List<FeedbackDraft>> Function(FeedbackDraft) onDelete;

  @override
  State<_DraftsSheet> createState() => _DraftsSheetState();
}

class _DraftsSheetState extends State<_DraftsSheet> {
  late List<FeedbackDraft> _drafts = widget.drafts;

  @override
  Widget build(BuildContext context) {
    final s = context.planishStrings;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final faint = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(s.drafts, style: theme.textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(s.draftsNote, style: faint),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final d in _drafts)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              if (_label(context, d).isNotEmpty) ...[
                                Text(
                                  _label(context, d),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: d.source == DraftSource.automatic
                                        ? colors.primary
                                        : colors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  _firstLine(d),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_ago(context, d.updatedAt), style: faint),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  [
                                    ?d.screen,
                                    if (d.hasScreenshot) s.withScreenshot,
                                    if (d.source == DraftSource.automatic)
                                      s.afterAnError,
                                  ].join(' · '),
                                  style: faint,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(d),
                                child: Text(s.continueAction),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final left = await widget.onDelete(d);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (left.isEmpty) {
                                    Navigator.of(context).pop();
                                  } else {
                                    setState(() => _drafts = left);
                                  }
                                },
                                child: Text(s.deleteAction),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context, FeedbackDraft d) {
    if (d.source == DraftSource.automatic) {
      return context.planishStrings.automaticDraft;
    }
    for (final c in widget.categories) {
      if (c.id == d.categoryId) {
        return c.displayLabel(context);
      }
    }
    return d.categoryId ?? '';
  }
}

String _firstLine(FeedbackDraft d) {
  final text = d.message.trim().isEmpty ? (d.frozen.error ?? '') : d.message;
  return text.trim().split('\n').first;
}

/// The time today, else the date: localized without plural strings.
String _ago(BuildContext context, DateTime t) {
  final m = MaterialLocalizations.of(context);
  final now = DateTime.now();
  final today = t.year == now.year && t.month == now.month && t.day == now.day;
  return today
      ? m.formatTimeOfDay(TimeOfDay.fromDateTime(t))
      : m.formatShortMonthDay(t);
}
