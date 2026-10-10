import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redcloud_android/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataLimitChecker - calculateTotalUsage', () {
    test('calculates total bytes correctly when used_bytes is a valid integer string', () {
      final account = {'used_bytes': '5000', 'worker': 'worker-1'};
      final totalUsage = DataLimitChecker.calculateTotalUsage(account, 2000);
      expect(totalUsage, 7000);
    });

    test('defaults previously used bytes to 0 when used_bytes key is missing', () {
      final account = {'worker': 'worker-1'};
      final totalUsage = DataLimitChecker.calculateTotalUsage(account, 3000);
      expect(totalUsage, 3000);
    });

    test('defaults previously used bytes to 0 when used_bytes is malformed or non-numeric', () {
      final account1 = {'used_bytes': 'invalid', 'worker': 'worker-1'};
      expect(DataLimitChecker.calculateTotalUsage(account1, 1500), 1500);

      final account2 = {'used_bytes': '', 'worker': 'worker-1'};
      expect(DataLimitChecker.calculateTotalUsage(account2, 1500), 1500);

      final account3 = {'used_bytes': '12.34', 'worker': 'worker-1'};
      expect(DataLimitChecker.calculateTotalUsage(account3, 1500), 1500);
    });

    test('handles null account map gracefully', () {
      final totalUsage = DataLimitChecker.calculateTotalUsage(null, 4000);
      expect(totalUsage, 4000);
    });

    test('handles large byte values without overflow or error', () {
      const fiveGb = 5 * 1024 * 1024 * 1024;
      final account = {'used_bytes': '$fiveGb'};
      final totalUsage = DataLimitChecker.calculateTotalUsage(account, 1024 * 1024);
      expect(totalUsage, fiveGb + (1024 * 1024));
    });
  });

  group('DataLimitChecker - isLimitExhausted', () {
    const defaultLimit = DataLimitChecker.defaultMaxDailyBytes; // 5 GB

    test('returns false when total usage is strictly below max daily limit', () {
      final account = {'used_bytes': '${defaultLimit - 2000}'};
      final isExhausted = DataLimitChecker.isLimitExhausted(account, 1000);
      expect(isExhausted, isFalse);
    });

    test('returns true when total usage is exactly equal to max daily limit', () {
      final account = {'used_bytes': '${defaultLimit - 1000}'};
      final isExhausted = DataLimitChecker.isLimitExhausted(account, 1000);
      expect(isExhausted, isTrue);
    });

    test('returns true when total usage exceeds max daily limit', () {
      final account = {'used_bytes': '$defaultLimit'};
      final isExhausted = DataLimitChecker.isLimitExhausted(account, 1);
      expect(isExhausted, isTrue);
    });

    test('supports custom maxDailyBytes limit parameter', () {
      const customLimit = 10000;
      final account = {'used_bytes': '8000'};

      expect(
        DataLimitChecker.isLimitExhausted(account, 1000, maxDailyBytes: customLimit),
        isFalse,
      );
      expect(
        DataLimitChecker.isLimitExhausted(account, 2000, maxDailyBytes: customLimit),
        isTrue,
      );
      expect(
        DataLimitChecker.isLimitExhausted(account, 3000, maxDailyBytes: customLimit),
        isTrue,
      );
    });

    test('returns false when total session bytes and used_bytes are 0', () {
      final account = {'used_bytes': '0'};
      expect(DataLimitChecker.isLimitExhausted(account, 0), isFalse);
    });
  });

  group('Widget & State Test for checkAndAutoSwitchLimit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('does not trigger exhaustion when usage is below limit', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ));
      await tester.pump(const Duration(seconds: 5));

      final homePageFinder = find.byType(HomePage);
      expect(homePageFinder, findsOneWidget);

      final state = tester.state(homePageFinder) as dynamic;
      final account = {
        'worker': 'active-worker.dev',
        'used_bytes': '100',
      };

      state.checkAndAutoSwitchLimit(account, 100);
      await tester.pump(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('exhausted_workers_data');
      expect(savedData, isNull);
    });

    testWidgets('triggers limit exhaustion handling and saves exhausted worker when limit is reached', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ));
      await tester.pump(const Duration(seconds: 5));

      final homePageFinder = find.byType(HomePage);
      expect(homePageFinder, findsOneWidget);

      final state = tester.state(homePageFinder) as dynamic;
      final account = {
        'worker': 'exhausted-worker.dev',
        'used_bytes': '${DataLimitChecker.defaultMaxDailyBytes}',
      };

      state.checkAndAutoSwitchLimit(account, 0);
      await tester.pump(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final savedDataStr = prefs.getString('exhausted_workers_data');
      expect(savedDataStr, isNotNull);

      final Map<String, dynamic> savedData = jsonDecode(savedDataStr!);
      final List<dynamic> workers = savedData['workers'] ?? [];
      expect(workers, contains('exhausted-worker.dev'));
    });
  });
}
