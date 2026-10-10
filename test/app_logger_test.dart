import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  setUp(() {
    AppLogger.clear();
  });

  group('LogEntry', () {
    test('format formats time, tag, and message correctly', () {
      final time = DateTime(2025, 1, 15, 14, 5, 9, 123);
      final entry = LogEntry(
        time: time,
        tag: 'TEST_TAG',
        message: 'Test message',
      );

      expect(entry.format(), equals('[14:05:09.123] [TEST_TAG] Test message'));
    });

    test('isError defaults to false', () {
      final entry = LogEntry(
        time: DateTime.now(),
        tag: 'TAG',
        message: 'msg',
      );

      expect(entry.isError, isFalse);
    });
  });

  group('AppLogger', () {
    test('log adds entry and notifies logCountNotifier', () {
      expect(AppLogger.currentLogs.length, equals(0));
      expect(AppLogger.logCountNotifier.value, equals(0));

      AppLogger.log('TAG1', 'Message 1');

      expect(AppLogger.currentLogs.length, equals(1));
      expect(AppLogger.logCountNotifier.value, equals(1));

      final entry = AppLogger.currentLogs.first;
      expect(entry.tag, equals('TAG1'));
      expect(entry.message, equals('Message 1'));
      expect(entry.isError, isFalse);

      AppLogger.log('TAG2', 'Error Message', isError: true);

      expect(AppLogger.currentLogs.length, equals(2));
      expect(AppLogger.logCountNotifier.value, equals(2));
      expect(AppLogger.currentLogs.last.isError, isTrue);
    });

    test('addNativeLog tags as NATIVE and detects error keywords correctly', () {
      AppLogger.addNativeLog('Normal native output');
      AppLogger.addNativeLog('Fatal Error occurred');
      AppLogger.addNativeLog('Operation Failed');
      AppLogger.addNativeLog('App Crash detected');
      AppLogger.addNativeLog('Connection Aborted');

      expect(AppLogger.currentLogs.length, equals(5));

      final logs = AppLogger.currentLogs;
      expect(logs[0].tag, equals('NATIVE'));
      expect(logs[0].isError, isFalse);

      expect(logs[1].tag, equals('NATIVE'));
      expect(logs[1].isError, isTrue);

      expect(logs[2].tag, equals('NATIVE'));
      expect(logs[2].isError, isTrue);

      expect(logs[3].tag, equals('NATIVE'));
      expect(logs[3].isError, isTrue);

      expect(logs[4].tag, equals('NATIVE'));
      expect(logs[4].isError, isTrue);
    });

    test('log evicts oldest entry when maxLogs limit is reached', () {
      for (int i = 0; i < AppLogger.maxLogs; i++) {
        AppLogger.log('TAG', 'Log #$i');
      }

      expect(AppLogger.currentLogs.length, equals(AppLogger.maxLogs));
      expect(AppLogger.logCountNotifier.value, equals(AppLogger.maxLogs));
      expect(AppLogger.currentLogs.first.message, equals('Log #0'));

      // Add 501st log
      AppLogger.log('TAG', 'Log #500');

      expect(AppLogger.currentLogs.length, equals(AppLogger.maxLogs));
      expect(AppLogger.logCountNotifier.value, equals(AppLogger.maxLogs));
      expect(AppLogger.currentLogs.first.message, equals('Log #1'));
      expect(AppLogger.currentLogs.last.message, equals('Log #500'));
    });

    test('addNativeLog evicts oldest entry when maxLogs limit is reached', () {
      for (int i = 0; i < AppLogger.maxLogs; i++) {
        AppLogger.log('TAG', 'Log #$i');
      }

      AppLogger.addNativeLog('Native line #500');

      expect(AppLogger.currentLogs.length, equals(AppLogger.maxLogs));
      expect(AppLogger.logCountNotifier.value, equals(AppLogger.maxLogs));
      expect(AppLogger.currentLogs.first.message, equals('Log #1'));
      expect(AppLogger.currentLogs.last.message, equals('Native line #500'));
    });

    test('clear resets logs and logCountNotifier', () {
      AppLogger.log('TAG', 'Message');
      expect(AppLogger.currentLogs.length, equals(1));
      expect(AppLogger.logCountNotifier.value, equals(1));

      AppLogger.clear();

      expect(AppLogger.currentLogs.length, equals(0));
      expect(AppLogger.logCountNotifier.value, equals(0));
    });

    test('currentLogs returns unmodifiable list', () {
      AppLogger.log('TAG', 'Message');
      final logs = AppLogger.currentLogs;

      expect(() => (logs as List).clear(), throwsUnsupportedError);
    });

    test('getAllLogsFormatted formats all logs with newlines', () {
      final time1 = DateTime(2025, 1, 15, 10, 0, 0, 0);
      final time2 = DateTime(2025, 1, 15, 10, 0, 1, 0);

      final entry1 = LogEntry(time: time1, tag: 'TAG1', message: 'First');
      final entry2 = LogEntry(time: time2, tag: 'TAG2', message: 'Second');

      AppLogger.log('TAG1', 'First');
      AppLogger.log('TAG2', 'Second');

      final formatted = AppLogger.getAllLogsFormatted();
      expect(formatted, contains('[TAG1] First'));
      expect(formatted, contains('[TAG2] Second'));
      expect(formatted.split('\n').length, equals(2));
    });
  });
}
