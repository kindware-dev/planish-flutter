import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planish/src/log/log.dart';
import 'package:planish/src/network/trace_ids.dart';

/// The store `Planish.init` opened, or null when drafts are off.
DraftStore? activeDraftStore;

/// Who started a draft.
enum DraftSource {
  /// The person, in the form.
  manual,

  /// The package, after an uncaught error.
  automatic,

  /// An AI agent.
  agent,
}

/// What the app was doing when a draft was started. Sending it later uses
/// this, never a fresh copy.
@immutable
class FrozenContext {
  /// Creates a snapshot.
  const FrozenContext({
    this.context = const <String, String>{},
    this.logs = const <LogEntry>[],
    this.requests = const <BackendRequest>[],
    this.error,
    this.stackTrace,
  });

  /// Inverse of [toJson].
  factory FrozenContext.fromJson(Map<String, Object?> json) => FrozenContext(
    context: (json['context'] as Map?)?.cast<String, String>() ?? const {},
    logs: [
      for (final e in (json['logs'] as List?) ?? const <Object?>[])
        LogEntry.fromJson((e as Map).cast<String, Object?>()),
    ],
    requests: [
      for (final r in (json['requests'] as List?) ?? const <Object?>[])
        BackendRequest.fromJson((r as Map).cast<String, Object?>()),
    ],
    error: json['error'] as String?,
    stackTrace: json['stackTrace'] as String?,
  );

  final Map<String, String> context;

  final List<LogEntry> logs;

  final List<BackendRequest> requests;

  /// Redacted error text.
  final String? error;

  /// Redacted stack trace.
  final String? stackTrace;

  Map<String, Object?> toJson() => <String, Object?>{
    'context': context,
    'logs': logs.map((LogEntry e) => e.toJson()).toList(),
    'requests': requests.map((BackendRequest r) => r.toJson()).toList(),
    if (error != null) 'error': error,
    if (stackTrace != null) 'stackTrace': stackTrace,
  };
}

/// A report kept on the device until it is sent.
@immutable
class FeedbackDraft {
  /// Creates a draft.
  const FeedbackDraft({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.frozen,
    this.source = DraftSource.manual,
    this.touched = true,
    this.message = '',
    this.categoryId,
    this.email,
    this.hasScreenshot = false,
    this.screenshotLost = false,
    this.relatedTo,
  });

  /// Inverse of [toJson].
  factory FeedbackDraft.fromJson(Map<String, Object?> json) => FeedbackDraft(
    id: json['id']! as String,
    source: DraftSource.values.firstWhere(
      (DraftSource s) => s.name == json['source'],
      orElse: () => DraftSource.manual,
    ),
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
    touched: json['touched'] as bool? ?? true,
    message: json['message'] as String? ?? '',
    categoryId: json['category'] as String?,
    email: json['email'] as String?,
    hasScreenshot: json['hasScreenshot'] as bool? ?? false,
    screenshotLost: json['screenshotLost'] as bool? ?? false,
    relatedTo: json['relatedTo'] as String?,
    frozen: FrozenContext.fromJson(
      (json['frozen'] as Map? ?? const {}).cast<String, Object?>(),
    ),
  );

  /// The id the report gets when sent, so a retried send stays one report.
  final String id;

  final DraftSource source;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// False for an automatic draft nobody has changed yet; those are evicted
  /// first.
  final bool touched;

  final String message;

  final String? categoryId;

  final String? email;

  /// A screenshot is stored with it; read it with [DraftStore.screenshot].
  final bool hasScreenshot;

  /// The screenshot could not be stored; the draft was kept without it.
  final bool screenshotLost;

  final FrozenContext frozen;

  /// Id of the report already sent automatically for this error
  /// (`autoSendErrors`); the report sent from this draft points to it.
  final String? relatedTo;

  /// The screen the draft was started on, if known.
  String? get screen => frozen.context['screen'];

  /// Made after an uncaught error and never opened by the user.
  bool get isCaughtError => source == DraftSource.automatic && !touched;

  /// The build the draft was made in, or null when unknown.
  String? get build {
    final version = frozen.context['app.version'];
    return version == null
        ? null
        : '$version ${frozen.context['build.commit'] ?? ''}'.trim();
  }

  FeedbackDraft copyWith({
    DateTime? updatedAt,
    bool? touched,
    String? message,
    String? categoryId,
    String? email,
    bool? hasScreenshot,
    bool? screenshotLost,
  }) => FeedbackDraft(
    id: id,
    source: source,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    touched: touched ?? this.touched,
    message: message ?? this.message,
    categoryId: categoryId ?? this.categoryId,
    email: email ?? this.email,
    hasScreenshot: hasScreenshot ?? this.hasScreenshot,
    screenshotLost: screenshotLost ?? this.screenshotLost,
    frozen: frozen,
    relatedTo: relatedTo,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'source': source.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'touched': touched,
    'message': message,
    if (categoryId != null) 'category': categoryId,
    if (email != null) 'email': email,
    'hasScreenshot': hasScreenshot,
    if (screenshotLost) 'screenshotLost': true,
    if (relatedTo != null) 'relatedTo': relatedTo,
    'frozen': frozen.toJson(),
  };
}

/// Drafts on disk: one JSON file per draft plus its PNG, under the app
/// support directory. Rules: at most [maxDrafts], untouched automatic drafts
/// evicted first, [maxAge] after the last change.
/// Number of drafts waiting on this device, kept current by [DraftStore].
final ValueNotifier<int> pendingDrafts = ValueNotifier<int>(0);

class DraftStore {
  DraftStore._(this._dir, this._now);

  /// The store, or null where files are unavailable (web) or the directory
  /// cannot be created.
  static Future<DraftStore?> open({
    Directory? directory,
    DateTime Function() now = DateTime.now,
  }) async {
    if (kIsWeb) {
      return null;
    }
    try {
      final base = directory ?? await getApplicationSupportDirectory();
      final dir = await Directory(
        '${base.path}/planish/drafts',
      ).create(recursive: true);
      final store = DraftStore._(dir, now);
      await store.list();
      return store;
    } on Object catch (e) {
      Log.warning('Drafts unavailable', error: e, tag: 'feedback');
      return null;
    }
  }

  static const int maxDrafts = 10;
  static const Duration maxAge = Duration(days: 30);

  final Directory _dir;
  final DateTime Function() _now;

  /// This app's build, as [FeedbackDraft.build] gives it: caught errors from
  /// another build are dropped.
  String? currentBuild;

  File _json(String id) => File('${_dir.path}/$id.json');
  File _png(String id) => File('${_dir.path}/$id.png');

  /// Newest change first; expired drafts are deleted on the way.
  Future<List<FeedbackDraft>> list() async {
    final drafts = <FeedbackDraft>[];
    final limit = _now().subtract(maxAge);
    await for (final f in _dir.list()) {
      if (f is! File || !f.path.endsWith('.json')) {
        continue;
      }
      try {
        final draft = FeedbackDraft.fromJson(
          (jsonDecode(await f.readAsString()) as Map).cast<String, Object?>(),
        );
        final otherBuild =
            draft.isCaughtError &&
            currentBuild != null &&
            draft.build != null &&
            draft.build != currentBuild;
        if (draft.updatedAt.isBefore(limit) || otherBuild) {
          await _remove(draft.id);
        } else {
          drafts.add(draft);
        }
      } on Object {
        await f.delete();
      }
    }
    pendingDrafts.value = drafts
        .where((FeedbackDraft d) => !d.isCaughtError)
        .length;
    return drafts..sort(
      (FeedbackDraft a, FeedbackDraft b) => b.updatedAt.compareTo(a.updatedAt),
    );
  }

  Future<FeedbackDraft?> get(String id) async {
    for (final d in await list()) {
      if (d.id == id) {
        return d;
      }
    }
    return null;
  }

  /// The stored screenshot of [id], or null.
  Future<Uint8List?> screenshot(String id) async {
    final f = _png(id);
    return await f.exists() ? f.readAsBytes() : null;
  }

  /// Saves [draft] with [screenshot] (null keeps the stored one; pass
  /// [removeScreenshot] to drop it), then evicts down to the limit, never
  /// [openId]. A screenshot that cannot be written is dropped and the draft
  /// says so.
  Future<FeedbackDraft> save(
    FeedbackDraft draft, {
    Uint8List? screenshot,
    bool removeScreenshot = false,
    String? openId,
  }) async {
    var saved = draft;
    if (removeScreenshot) {
      await _deleteIfExists(_png(draft.id));
      saved = saved.copyWith(hasScreenshot: false);
    } else if (screenshot != null) {
      try {
        await _png(draft.id).writeAsBytes(screenshot, flush: true);
        saved = saved.copyWith(hasScreenshot: true, screenshotLost: false);
      } on Object {
        await _deleteIfExists(_png(draft.id));
        saved = saved.copyWith(hasScreenshot: false, screenshotLost: true);
      }
    }
    await _json(
      draft.id,
    ).writeAsString(jsonEncode(saved.toJson()), flush: true);
    for (final victim in evictions(await list(), openId ?? draft.id)) {
      await discard(victim.id);
    }
    return saved;
  }

  /// Deletes a draft and its screenshot.
  Future<void> discard(String id) async {
    await _remove(id);
    await list();
  }

  Future<void> _remove(String id) async {
    await _deleteIfExists(_json(id));
    await _deleteIfExists(_png(id));
  }

  static Future<void> _deleteIfExists(File f) async {
    if (await f.exists()) {
      await f.delete();
    }
  }
}

/// Over the limit: untouched automatic drafts go first, then the oldest
/// change. [drafts] is newest first.
List<FeedbackDraft> evictions(List<FeedbackDraft> drafts, String openId) {
  final extra = drafts.length - DraftStore.maxDrafts;
  if (extra <= 0) {
    return const <FeedbackDraft>[];
  }
  final oldestFirst = drafts.where((FeedbackDraft d) => d.id != openId).toList()
    ..sort(
      (FeedbackDraft a, FeedbackDraft b) => a.updatedAt.compareTo(b.updatedAt),
    );
  final untouched = oldestFirst.where(
    (FeedbackDraft d) => d.source == DraftSource.automatic && !d.touched,
  );
  return <FeedbackDraft>[
    ...untouched,
    ...oldestFirst.where((FeedbackDraft d) => !untouched.contains(d)),
  ].take(extra).toList();
}
