import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('compareServerPing', () {
    test('returns 0 when both pings are non-positive (0 or negative)', () {
      expect(compareServerPing({'ping': 0}, {'ping': 0}), equals(0));
      expect(compareServerPing({'ping': -1}, {'ping': -2}), equals(0));
      expect(compareServerPing({'ping': 0}, {'ping': -1}), equals(0));
      expect(compareServerPing({'ping': -2}, {'ping': 0}), equals(0));
    });

    test('returns 1 when first ping is non-positive and second is positive', () {
      expect(compareServerPing({'ping': 0}, {'ping': 100}), equals(1));
      expect(compareServerPing({'ping': -1}, {'ping': 50}), equals(1));
      expect(compareServerPing({'ping': -2}, {'ping': 200}), equals(1));
    });

    test('returns -1 when first ping is positive and second is non-positive', () {
      expect(compareServerPing({'ping': 100}, {'ping': 0}), equals(-1));
      expect(compareServerPing({'ping': 50}, {'ping': -1}), equals(-1));
      expect(compareServerPing({'ping': 200}, {'ping': -2}), equals(-1));
    });

    test('compares positive pings correctly using compareTo', () {
      expect(compareServerPing({'ping': 50}, {'ping': 100}), isNegative);
      expect(compareServerPing({'ping': 100}, {'ping': 50}), isPositive);
      expect(compareServerPing({'ping': 75}, {'ping': 75}), equals(0));
    });

    test('handles missing or null ping fields gracefully by defaulting to 0', () {
      expect(compareServerPing({}, {'ping': 100}), equals(1));
      expect(compareServerPing({'ping': 100}, {}), equals(-1));
      expect(compareServerPing({}, {}), equals(0));
      expect(compareServerPing({'ping': null}, {'ping': 50}), equals(1));
    });
  });

  group('Server ping sorting logic', () {
    test('sorts positive pings in ascending order', () {
      final servers = [
        {'name': 'Server C', 'ping': 300},
        {'name': 'Server A', 'ping': 50},
        {'name': 'Server B', 'ping': 150},
      ];

      servers.sort(compareServerPing);

      expect(servers, [
        {'name': 'Server A', 'ping': 50},
        {'name': 'Server B', 'ping': 150},
        {'name': 'Server C', 'ping': 300},
      ]);
    });

    test('places non-positive pings (0, -1, -2) at the end', () {
      final servers = [
        {'name': 'Timeout Server', 'ping': -1},
        {'name': 'Fast Server', 'ping': 45},
        {'name': 'In-Progress Server', 'ping': -2},
        {'name': 'Zero Ping Server', 'ping': 0},
        {'name': 'Medium Server', 'ping': 120},
      ];

      servers.sort(compareServerPing);

      // Positive pings must come first in ascending order
      expect(servers[0]['ping'], equals(45));
      expect(servers[1]['ping'], equals(120));

      // Remaining servers should have ping <= 0
      for (int i = 2; i < servers.length; i++) {
        expect(servers[i]['ping'] as int, lessThanOrEqualTo(0));
      }
    });

    test('handles empty list and single item list', () {
      final List<Map<String, dynamic>> emptyList = [];
      emptyList.sort(compareServerPing);
      expect(emptyList, isEmpty);

      final singleList = [
        {'name': 'Only Server', 'ping': 100}
      ];
      singleList.sort(compareServerPing);
      expect(singleList, [
        {'name': 'Only Server', 'ping': 100}
      ]);
    });

    test('handles list where all servers have non-positive pings', () {
      final servers = [
        {'name': 'S1', 'ping': 0},
        {'name': 'S2', 'ping': -1},
        {'name': 'S3', 'ping': -2},
      ];

      servers.sort(compareServerPing);

      for (final s in servers) {
        expect(s['ping'] as int, lessThanOrEqualTo(0));
      }
    });

    test('maintains order relative to positive pings when equal positive pings exist', () {
      final servers = [
        {'name': 'Server A', 'ping': 100},
        {'name': 'Server B', 'ping': 50},
        {'name': 'Server C', 'ping': 100},
      ];

      servers.sort(compareServerPing);

      expect(servers[0]['name'], equals('Server B'));
      expect(servers[0]['ping'], equals(50));
      expect(servers[1]['ping'], equals(100));
      expect(servers[2]['ping'], equals(100));
    });
  });
}
