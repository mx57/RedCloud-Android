import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  setUp(() {
    AppLogger.clear();
  });

  group('AppLogger.clear', () {
    test('clearing when already empty keeps log state empty and count at 0', () {
      expect(AppLogger.currentLogs, isEmpty);
      expect(AppLogger.logCountNotifier.value, equals(0));
      expect(AppLogger.getAllLogsFormatted(), isEmpty);

      AppLogger.clear();

      expect(AppLogger.currentLogs, isEmpty);
      expect(AppLogger.logCountNotifier.value, equals(0));
      expect(AppLogger.getAllLogsFormatted(), isEmpty);
    });

    test('clears logs added via log and addNativeLog, resets notifier and formatted output', () {
      AppLogger.log('TEST_TAG', 'Test log message 1');
      AppLogger.addNativeLog('Native log message 2');

      expect(AppLogger.currentLogs.length, equals(2));
      expect(AppLogger.logCountNotifier.value, equals(2));
      expect(AppLogger.getAllLogsFormatted(), contains('Test log message 1'));
      expect(AppLogger.getAllLogsFormatted(), contains('Native log message 2'));

      AppLogger.clear();

      expect(AppLogger.currentLogs, isEmpty);
      expect(AppLogger.logCountNotifier.value, equals(0));
      expect(AppLogger.getAllLogsFormatted(), isEmpty);
    });

    test('can add new logs after clearing', () {
      AppLogger.log('TAG1', 'Old log message');
      expect(AppLogger.currentLogs.length, equals(1));

      AppLogger.clear();

      expect(AppLogger.currentLogs, isEmpty);
      expect(AppLogger.logCountNotifier.value, equals(0));

      AppLogger.log('TAG2', 'New log message');

      expect(AppLogger.currentLogs.length, equals(1));
      expect(AppLogger.logCountNotifier.value, equals(1));
      expect(AppLogger.currentLogs.first.tag, equals('TAG2'));
      expect(AppLogger.currentLogs.first.message, equals('New log message'));
      expect(AppLogger.getAllLogsFormatted(), contains('New log message'));
    });
  });
}
