import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget() {
    return const MaterialApp(
      home: MyApp(
        initialLang: 'en',
        initialDarkMode: true,
        isFirstRun: false,
      ),
    );
  }

  group('_parseAndSaveConfig testing via HomePageState', () {
    testWidgets('Empty link returns early without throwing errors or showing snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));

      // Call with empty string
      state.parseAndSaveConfigForTesting('');
      await tester.pumpAndSettle();

      // Ensure no error snackbar is shown
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Invalid non-JSON link triggers parse failure and shows error snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));

      // Call with invalid URL link (not starting with '{' and not valid v2ray/vless URL)
      state.parseAndSaveConfigForTesting('invalid_url_protocol://bad_data');
      await tester.pumpAndSettle();

      // Expect error snackbar to be presented
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Invalid JSON string starting with { catches jsonDecode error safely', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));

      // Call with malformed JSON starting with '{'
      state.parseAndSaveConfigForTesting('{ "inbounds": [ malformed json ');
      await tester.pumpAndSettle();

      // No unhandled exception should be thrown; method handles JSON decode error gracefully
    });

    testWidgets('Valid JSON string starting with { correctly parses configuration', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));

      const validJson = '{"outbounds": [{"tag": "proxy", "protocol": "vless"}]}';

      state.parseAndSaveConfigForTesting(validJson);
      await tester.pumpAndSettle();

      expect(state.fullConfigJsonForTesting, contains('"outbounds"'));
      expect(state.fullConfigJsonForTesting, contains('"inbounds"'));
      expect(state.fullConfigJsonForTesting, contains('"socks-in"'));
      expect(state.fullConfigJsonForTesting, contains('"routing"'));
    });

    testWidgets('Valid VLESS URL updates protocolType and serverName when updateUI is true', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(HomePage));

      const vlessUrl = "vless://a6123456-1234-1234-1234-123456789012@1.2.3.4:443?encryption=none&security=tls&type=ws&host=example.com&path=%2F#TestServer";

      state.parseAndSaveConfigForTesting(vlessUrl, updateUI: true);
      await tester.pumpAndSettle();

      expect(state.serverNameForTesting, equals("TestServer"));
      expect(state.protocolTypeForTesting, equals("VLESS"));
      expect(state.fullConfigJsonForTesting, contains('"outbounds"'));
    });
  });
}
