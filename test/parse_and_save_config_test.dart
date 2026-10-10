import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('_parseAndSaveConfig Error Handling and Coverage Tests', () {
    testWidgets('Empty configuration string is ignored gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));
      final String initialConfig = state.fullConfigJson as String;

      AppLogger.clear();

      // Passing empty link
      state.parseAndSaveConfig('');

      expect(state.fullConfigJson, equals(initialConfig));
      expect(
        AppLogger.currentLogs.any((log) => log.tag == 'CONFIG-ERR'),
        isFalse,
      );
    });

    testWidgets('Invalid V2Ray URL handles exception gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));
      final String initialConfig = state.fullConfigJson as String;

      AppLogger.clear();

      // Passing invalid non-JSON string that fails V2ray.parseFromURL
      expect(() => state.parseAndSaveConfig('invalid_v2ray_protocol_string'), returnsNormally);

      expect(state.fullConfigJson, equals(initialConfig));
    });

    testWidgets('Invalid JSON string starting with { handles FormatException and logs CONFIG-ERR', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));
      final String initialConfig = state.fullConfigJson as String;

      AppLogger.clear();

      // Passing invalid JSON starting with {
      expect(() => state.parseAndSaveConfig('{ invalid json format'), returnsNormally);

      expect(state.fullConfigJson, equals(initialConfig));
      expect(
        AppLogger.currentLogs.any((log) => log.tag == 'CONFIG-ERR' && log.message.contains('Ошибка обработки конфигурации')),
        isTrue,
      );
    });

    testWidgets('Malformed JSON schema handles processing exception and logs CONFIG-ERR', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));
      final String initialConfig = state.fullConfigJson as String;

      AppLogger.clear();

      // Passing malformed schema (outbounds expected to be list or null, passed string causing type error if accessed as list or streamSettings)
      expect(() => state.parseAndSaveConfig('{"outbounds": "not_a_list"}'), returnsNormally);

      // Verify CONFIG-ERR was logged
      expect(
        AppLogger.currentLogs.any((log) => log.tag == 'CONFIG-ERR'),
        isTrue,
      );
    });

    testWidgets('Valid V2Ray URL string is parsed and saves config successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));

      AppLogger.clear();

      const validVless =
          'vless://88d613eb-d083-4a1d-a9db-97f289753c15@round-sea-8418.redcloudir.workers.dev:443?encryption=none&security=tls&sni=round-sea-8418.redcloudir.workers.dev&fp=chrome&alpn=http%2F1.1&type=ws&host=round-sea-8418.redcloudir.workers.dev&path=%2F%3Fed%3D2048#TestServer';

      state.parseAndSaveConfig(validVless);

      final String fullConfig = state.fullConfigJson as String;
      expect(fullConfig, isNotEmpty);
      expect(fullConfig.contains('round-sea-8418.redcloudir.workers.dev'), isTrue);
      expect(
        AppLogger.currentLogs.any((log) => log.tag == 'CONFIG' && log.message.contains('успешно создана')),
        isTrue,
      );
    });

    testWidgets('Valid JSON string starting with { is parsed and saves config successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));

      AppLogger.clear();

      const validJsonConfig = '{"inbounds":[],"outbounds":[{"tag":"proxy","protocol":"vless"}]}';

      state.parseAndSaveConfig(validJsonConfig);

      final String fullConfig = state.fullConfigJson as String;
      expect(fullConfig, isNotEmpty);
      expect(fullConfig.contains('socks-in'), isTrue);
      expect(
        AppLogger.currentLogs.any((log) => log.tag == 'CONFIG' && log.message.contains('успешно создана')),
        isTrue,
      );
    });
  });
}
