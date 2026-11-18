import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planish/planish.dart';

void main() {
  late Directory dir;

  setUp(() async {
    await Log.reset();
    await PersistedLogs.reset();
    dir = await Directory.systemTemp.createTemp('planish_logs_');
  });

  tearDown(() async {
    await PersistedLogs.reset();
    await dir.delete(recursive: true);
  });

  File current() => File('${dir.path}/planish/current.ndjson');

  test('a corrupted marker leaves persistence on and is repaired', () async {
    final marker = File('${dir.path}/planish/session.json');
    await marker.parent.create(recursive: true);
    await marker.writeAsString('{"state":"resumed","at":"x"}}');

    await PersistedLogs.open(directory: dir);
    expect(PersistedLogs.previousExit, PreviousExit.unknown);
    Log.info('still persisted', tag: 't');
    await PersistedLogs.onLifecycle(AppLifecycleState.paused);
    expect(await current().readAsString(), contains('still persisted'));
    expect(
      jsonDecode(await marker.readAsString()),
      containsPair('state', 'paused'),
    );
  });

  test('a burst of lifecycle changes leaves a valid marker', () async {
    await PersistedLogs.open(directory: dir);
    await Future.wait(<Future<void>>[
      PersistedLogs.onLifecycle(AppLifecycleState.inactive),
      PersistedLogs.onLifecycle(AppLifecycleState.hidden),
      PersistedLogs.onLifecycle(AppLifecycleState.paused),
      PersistedLogs.onLifecycle(AppLifecycleState.resumed),
    ]);
    final marker = File('${dir.path}/planish/session.json');
    expect(
      jsonDecode(await marker.readAsString()),
      containsPair('state', 'resumed'),
    );
  });

  test('the file is cut to its newer half past maxBytes', () async {
    await PersistedLogs.open(directory: dir, maxBytes: 2000);
    for (var i = 0; i < 60; i++) {
      Log.info('entry number $i with some padding text', tag: 't');
    }
    await PersistedLogs.onLifecycle(AppLifecycleState.paused);

    final size = await current().length();
    expect(size, lessThan(2000));
    expect(await current().readAsString(), contains('entry number 59'));
    expect(await current().readAsString(), isNot(contains('entry number 0 ')));
  });

  test('a trimmed file still loads as the previous session', () async {
    await PersistedLogs.open(directory: dir, maxBytes: 2000);
    for (var i = 0; i < 60; i++) {
      Log.info('entry number $i with some padding text', tag: 't');
    }
    await PersistedLogs.onLifecycle(AppLifecycleState.paused);
    await PersistedLogs.reset();
    await Log.reset();

    await PersistedLogs.open(directory: dir);
    final messages = PersistedLogs.previousSession
        .map((LogEntry e) => e.message)
        .toList();
    expect(messages, isNotEmpty);
    expect(messages.last, 'entry number 59 with some padding text');
    // The cut may split a line; the half-line is dropped, the rest is kept.
    expect(messages.every((String m) => m.startsWith('entry number')), isTrue);
  });
}
