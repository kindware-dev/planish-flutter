import 'package:flutter_test/flutter_test.dart';
import 'package:planish/developer.dart';

void main() {
  setUp(Log.reset);

  test('log() keeps the dart:developer signature and feeds Log', () {
    log('[http] request uri: /users?token=abc', name: 'http');
    log(
      'boom',
      level: 1000,
      error: StateError('x'),
      stackTrace: StackTrace.empty,
    );

    expect(Log.entries, hasLength(2));
    expect(Log.entries[0].tag, 'http');
    expect(Log.entries[0].level, LogLevel.debug);
    expect(Log.entries[1].level, LogLevel.error);
    expect(Log.entries[1].error, isA<StateError>());
  });
}
