import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('LogEntry format unit tests', () {
    test('formats time with double digits correctly', () {
      final time = DateTime(2025, 1, 1, 14, 25, 36, 123);
      final logEntry = LogEntry(
        time: time,
        tag: 'TEST',
        message: 'Test message',
      );

      expect(logEntry.format(), equals('[14:25:36.123] [TEST] Test message'));
    });

    test('pads single-digit time components with zero', () {
      final time = DateTime(2025, 1, 1, 5, 4, 3, 2);
      final logEntry = LogEntry(
        time: time,
        tag: 'TAG',
        message: 'Padded time message',
      );

      expect(logEntry.format(), equals('[05:04:03.002] [TAG] Padded time message'));
    });

    test('formats midnight edge case correctly', () {
      final time = DateTime(2025, 1, 1, 0, 0, 0, 0);
      final logEntry = LogEntry(
        time: time,
        tag: 'MIDNIGHT',
        message: 'Start of day',
      );

      expect(logEntry.format(), equals('[00:00:00.000] [MIDNIGHT] Start of day'));
    });

    test('formats late time edge case correctly', () {
      final time = DateTime(2025, 1, 1, 23, 59, 59, 999);
      final logEntry = LogEntry(
        time: time,
        tag: 'END',
        message: 'End of day',
        isError: true,
      );

      expect(logEntry.format(), equals('[23:59:59.999] [END] End of day'));
    });
  });
}
