import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  setUp(() {
    AppLogger.clear();
  });

  group('AppLogger.getAllLogsFormatted', () {
    test('returns empty string when no logs exist', () {
      expect(AppLogger.getAllLogsFormatted(), isEmpty);
    });

    test('returns single formatted log entry', () {
      AppLogger.log('TEST', 'Hello World');
      final result = AppLogger.getAllLogsFormatted();
      expect(result, contains('[TEST] Hello World'));
      expect(result.split('\n').length, equals(1));
    });

    test('joins multiple formatted log entries with newlines', () {
      AppLogger.log('TAG1', 'First message');
      AppLogger.log('TAG2', 'Second message');
      AppLogger.addNativeLog('Native log line');

      final result = AppLogger.getAllLogsFormatted();
      final lines = result.split('\n');

      expect(lines.length, equals(3));
      expect(lines[0], contains('[TAG1] First message'));
      expect(lines[1], contains('[TAG2] Second message'));
      expect(lines[2], contains('[NATIVE] Native log line'));
    });

    test('returns empty string after AppLogger.clear()', () {
      AppLogger.log('TAG', 'Message');
      expect(AppLogger.getAllLogsFormatted(), isNotEmpty);

      AppLogger.clear();
      expect(AppLogger.getAllLogsFormatted(), isEmpty);
    });
  });
}
