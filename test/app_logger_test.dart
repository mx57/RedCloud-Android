import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  setUp(() {
    AppLogger.clear();
  });

  group('AppLogger.addNativeLog', () {
    test('correctly identifies error keywords case-insensitively', () {
      const errorLines = [
        'An ERROR occurred in native process',
        'Connection FAILed unexpectedly',
        'Process crashed with exit code 1',
        'Operation ABORTED by user',
        'failed to bind socket',
        'fatal crash in native layer',
      ];

      for (final line in errorLines) {
        AppLogger.clear();
        AppLogger.addNativeLog(line);
        final entry = AppLogger.currentLogs.last;
        expect(entry.isError, isTrue, reason: 'Line "$line" should be flagged as error');
      }

      const nonErrorLines = [
        'Connected to SOCKS proxy on port 10808',
        'Tor circuit 100% bootstrapped',
        'Aether engine initialized successfully',
        'Listening on 127.0.0.1:1819',
      ];

      for (final line in nonErrorLines) {
        AppLogger.clear();
        AppLogger.addNativeLog(line);
        final entry = AppLogger.currentLogs.last;
        expect(entry.isError, isFalse, reason: 'Line "$line" should not be flagged as error');
      }
    });

    test('sets tag to NATIVE and preserves message and timestamp', () {
      final beforeTime = DateTime.now().subtract(const Duration(seconds: 1));
      const rawLine = 'Native log test line 123';

      AppLogger.addNativeLog(rawLine);

      final logs = AppLogger.currentLogs;
      expect(logs.length, equals(1));

      final entry = logs.first;
      expect(entry.tag, equals('NATIVE'));
      expect(entry.message, equals(rawLine));
      expect(entry.time.isAfter(beforeTime), isTrue);
      expect(entry.time.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });

    test('updates logCountNotifier value upon adding logs', () {
      expect(AppLogger.logCountNotifier.value, equals(0));

      int notifierCallCount = 0;
      void listener() {
        notifierCallCount++;
      }

      AppLogger.logCountNotifier.addListener(listener);

      AppLogger.addNativeLog('First log');
      expect(AppLogger.logCountNotifier.value, equals(1));

      AppLogger.addNativeLog('Second log');
      expect(AppLogger.logCountNotifier.value, equals(2));

      expect(notifierCallCount, equals(2));

      AppLogger.logCountNotifier.removeListener(listener);
    });

    test('enforces maxLogs limit by dropping oldest log when capacity is exceeded', () {
      for (int i = 0; i < AppLogger.maxLogs; i++) {
        AppLogger.addNativeLog('Native log #$i');
      }

      expect(AppLogger.currentLogs.length, equals(AppLogger.maxLogs));
      expect(AppLogger.currentLogs.first.message, equals('Native log #0'));
      expect(AppLogger.currentLogs.last.message, equals('Native log #${AppLogger.maxLogs - 1}'));

      // Add one more log to exceed maxLogs (500)
      AppLogger.addNativeLog('Native log #overflow');

      expect(AppLogger.currentLogs.length, equals(AppLogger.maxLogs));
      expect(AppLogger.currentLogs.first.message, equals('Native log #1'));
      expect(AppLogger.currentLogs.last.message, equals('Native log #overflow'));
      expect(AppLogger.logCountNotifier.value, equals(AppLogger.maxLogs));
    });
  });
}
