import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';
import 'package:planish/src/report/drafts.dart';

final DateTime now = DateTime(2026, 11, 5, 12);

FeedbackDraft draft(
  String id,
  int minutesAgo, {
  DraftSource source = DraftSource.manual,
  bool touched = true,
  FrozenContext frozen = const FrozenContext(),
}) {
  final at = now.subtract(Duration(minutes: minutesAgo));
  return FeedbackDraft(
    id: id,
    createdAt: at,
    updatedAt: at,
    source: source,
    touched: touched,
    message: 'Draft $id',
    frozen: frozen,
  );
}

void main() {
  late Directory dir;
  late DraftStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('drafts');
    store = (await DraftStore.open(directory: dir, now: () => now))!;
  });

  tearDown(() => dir.delete(recursive: true));

  test(
    'lists the newest change first and reads back the frozen context',
    () async {
      final frozen = FrozenContext(
        context: const {'screen': '/cart'},
        logs: [
          LogEntry(
            level: LogLevel.warning,
            message: 'GET /cart 500',
            tag: 'http',
            time: now,
          ),
        ],
        requests: [
          BackendRequest(
            at: now,
            method: 'POST',
            url: 'https://api.test/pay',
            status: 500,
            ms: 80,
            ids: const CallIds(requestId: 'req_1', state: IdsState.found),
          ),
        ],
        error: 'StateError: boom',
      );
      await store.save(draft('a', 30));
      await store.save(draft('b', 5, frozen: frozen));
      final all = await store.list();
      expect(all.map((d) => d.id), ['b', 'a']);
      expect(all.first.screen, '/cart');
      expect(all.first.frozen.logs.single.message, 'GET /cart 500');
      expect(
        all.first.frozen.requests.single.toJson(),
        frozen.requests.single.toJson(),
      );
      expect(all.first.frozen.error, 'StateError: boom');
    },
  );

  test('keeps the screenshot next to the draft', () async {
    final png = Uint8List.fromList([1, 2, 3]);
    final saved = await store.save(draft('a', 0), screenshot: png);
    expect(saved.hasScreenshot, isTrue);
    expect(await store.screenshot('a'), png);
    await store.save(
      draft('a', 0).copyWith(hasScreenshot: true),
      removeScreenshot: true,
    );
    expect(await store.screenshot('a'), isNull);
  });

  test(
    'an eleventh draft removes the oldest change, never the open one',
    () async {
      for (var i = 0; i < DraftStore.maxDrafts; i++) {
        await store.save(draft('d$i', 100 - i));
      }
      await store.save(draft('new', 0), openId: 'd0');
      final ids = (await store.list()).map((d) => d.id).toList();
      expect(ids, hasLength(DraftStore.maxDrafts));
      expect(ids, contains('d0'));
      expect(ids, isNot(contains('d1')));
    },
  );

  test('untouched automatic drafts are evicted before written ones', () async {
    for (var i = 0; i < DraftStore.maxDrafts - 1; i++) {
      await store.save(draft('w$i', 200 - i));
    }
    await store.save(
      draft('auto', 5, source: DraftSource.automatic, touched: false),
    );
    await store.save(draft('new', 0));
    final ids = (await store.list()).map((d) => d.id);
    expect(ids, isNot(contains('auto')));
    expect(ids, contains('w0'));
  });

  test(
    'a draft last changed more than 30 days ago is deleted with its screenshot',
    () async {
      await store.save(draft('old', (31 * 24) * 60), screenshot: Uint8List(4));
      await store.save(draft('fresh', 10));
      expect((await store.list()).map((d) => d.id), ['fresh']);
      expect(File('${dir.path}/planish/drafts/old.png').existsSync(), isFalse);
    },
  );

  test('saving the same id updates it', () async {
    await store.save(draft('a', 10));
    await store.save(draft('a', 0).copyWith(message: 'Edited'));
    final all = await store.list();
    expect(all, hasLength(1));
    expect(all.single.message, 'Edited');
  });

  test(
    'a screenshot that cannot be written is dropped and the draft says so',
    () async {
      await Directory('${dir.path}/planish/drafts/a.png').create();
      final saved = await store.save(draft('a', 0), screenshot: Uint8List(4));
      expect(saved.screenshotLost, isTrue);
      expect((await store.list()).single.screenshotLost, isTrue);
    },
  );

  test('discard deletes the draft and its screenshot', () async {
    await store.save(draft('a', 0), screenshot: Uint8List(4));
    await store.discard('a');
    expect(await store.list(), isEmpty);
    expect(await store.screenshot('a'), isNull);
  });

  test('keepDrafts follows persistLogs unless set', () {
    final sender = CallbackFeedbackSender((_) async {});
    expect(PlanishConfig(sender: sender).draftsEnabled, isTrue);
    expect(
      PlanishConfig(sender: sender, persistLogs: false).draftsEnabled,
      isFalse,
    );
    expect(
      PlanishConfig(
        sender: sender,
        persistLogs: false,
        keepDrafts: true,
      ).draftsEnabled,
      isTrue,
    );
  });
}
