import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redcloud_android/main.dart';

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  MockHttpClientResponse({required this.statusCode, required this.body});

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  final Uri uri;
  final Future<MockHttpClientResponse> Function(Uri uri) onRequest;

  MockHttpClientRequest(this.uri, this.onRequest);

  @override
  Future<HttpClientResponse> close() async {
    return onRequest(uri);
  }
}

class MockHttpClient extends Fake implements HttpClient {
  final Future<MockHttpClientResponse> Function(Uri uri) onRequest;
  @override
  Duration? connectionTimeout;

  MockHttpClient(this.onRequest);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(url, onRequest);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('_fetchSubscription Tests', () {
    Finder findDialogTextField() {
      return find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
    }

    Future<void> waitForSecondSnackBar(WidgetTester tester) async {
      await tester.pump();
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }

    testWidgets('fetches and decodes base64-encoded subscription configs', (WidgetTester tester) async {
      final vlessLink = "vless://user1@example.com:443?type=ws&security=tls#VLESS_Sub";
      final trojanLink = "trojan://pass1@example.com:443?type=ws&security=tls#Trojan_Sub";
      final rawSubBody = "$vlessLink\n$trojanLink";
      final base64SubBody = base64.encode(utf8.encode(rawSubBody));

      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ServersManagementScreen(
                currentLang: 'en',
                currentServers: [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open "Add New Subscription" dialog
        final addSubBtn = find.text("+ Add New Subscription");
        expect(addSubBtn, findsOneWidget);
        await tester.tap(addSubBtn);
        await tester.pumpAndSettle();

        // Enter subscription URL and tap "Add & Update"
        final textField = findDialogTextField();
        expect(textField, findsOneWidget);
        await tester.enterText(textField, "https://sub.example.com/v2ray");
        await tester.pumpAndSettle();

        final submitBtn = find.text("Add & Update");
        expect(submitBtn, findsOneWidget);
        await tester.tap(submitBtn);

        await waitForSecondSnackBar(tester);

        // Verify servers are added to UI and SnackBar message is shown
        expect(find.text("VLESS_Sub"), findsOneWidget);
        expect(find.text("Trojan_Sub"), findsOneWidget);
        expect(find.text("Successfully added 2 servers."), findsOneWidget);
      }, createHttpClient: (context) {
        return MockHttpClient((uri) async {
          return MockHttpClientResponse(statusCode: 200, body: base64SubBody);
        });
      });
    });

    testWidgets('fetches and parses plaintext (unencoded) subscription configs', (WidgetTester tester) async {
      final vlessLink = "vless://user2@example.com:443?type=ws&security=tls#Plain_VLESS";
      final rawSubBody = vlessLink;

      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ServersManagementScreen(
                currentLang: 'en',
                currentServers: [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text("+ Add New Subscription"));
        await tester.pumpAndSettle();

        await tester.enterText(findDialogTextField(), "https://sub.example.com/plain");
        await tester.pumpAndSettle();

        await tester.tap(find.text("Add & Update"));
        await waitForSecondSnackBar(tester);

        expect(find.text("Plain_VLESS"), findsOneWidget);
        expect(find.text("Successfully added 1 servers."), findsOneWidget);
      }, createHttpClient: (context) {
        return MockHttpClient((uri) async {
          return MockHttpClientResponse(statusCode: 200, body: rawSubBody);
        });
      });
    });

    testWidgets('fetches mixed protocol links including VMess, VLESS, and Trojan', (WidgetTester tester) async {
      final vmessJson = jsonEncode({
        "v": "2",
        "ps": "VMess_Sub",
        "add": "vmess.example.com",
        "port": "443",
        "id": "11111111-1111-1111-1111-111111111111",
        "net": "ws",
        "path": "/",
        "host": "vmess.example.com",
        "tls": "tls"
      });
      final vmessLink = "vmess://${base64.encode(utf8.encode(vmessJson))}";
      final vlessLink = "vless://user3@example.com:443?type=ws&security=tls#VLESS_Mixed";
      final trojanLink = "trojan://pass3@example.com:443?type=ws&security=tls#Trojan_Mixed";
      final invalidLine = "http://not-a-v2ray-link.com";

      final rawSubBody = "$vmessLink\n$invalidLine\n$vlessLink\n$trojanLink";

      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ServersManagementScreen(
                currentLang: 'en',
                currentServers: [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text("+ Add New Subscription"));
        await tester.pumpAndSettle();

        await tester.enterText(findDialogTextField(), "https://sub.example.com/mixed");
        await tester.pumpAndSettle();

        await tester.tap(find.text("Add & Update"));
        await waitForSecondSnackBar(tester);

        expect(find.text("VMess_Sub"), findsOneWidget);
        expect(find.text("VLESS_Mixed"), findsOneWidget);
        expect(find.text("Trojan_Mixed"), findsOneWidget);
        expect(find.text("Successfully added 3 servers."), findsOneWidget);
      }, createHttpClient: (context) {
        return MockHttpClient((uri) async {
          return MockHttpClientResponse(statusCode: 200, body: rawSubBody);
        });
      });
    });

    testWidgets('handles network errors gracefully during subscription fetch', (WidgetTester tester) async {
      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ServersManagementScreen(
                currentLang: 'en',
                currentServers: [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text("+ Add New Subscription"));
        await tester.pumpAndSettle();

        await tester.enterText(findDialogTextField(), "https://invalid.example.com/sub");
        await tester.pumpAndSettle();

        await tester.tap(find.text("Add & Update"));
        await waitForSecondSnackBar(tester);

        expect(find.textContaining("Failed to fetch subscription"), findsOneWidget);
      }, createHttpClient: (context) {
        return MockHttpClient((uri) async {
          throw const SocketException("Connection failed");
        });
      });
    });

    testWidgets('handles non-200 HTTP status response gracefully', (WidgetTester tester) async {
      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ServersManagementScreen(
                currentLang: 'en',
                currentServers: [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text("+ Add New Subscription"));
        await tester.pumpAndSettle();

        await tester.enterText(findDialogTextField(), "https://404.example.com/sub");
        await tester.pumpAndSettle();

        await tester.tap(find.text("Add & Update"));
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));

        // When status is non-200, no second SnackBar is queued, no servers are added.
        expect(find.byType(AlertDialog), findsNothing);
      }, createHttpClient: (context) {
        return MockHttpClient((uri) async {
          return MockHttpClientResponse(statusCode: 404, body: "Not Found");
        });
      });
    });

    testWidgets('handles empty or non-V2Ray payload response', (WidgetTester tester) async {
      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ServersManagementScreen(
                currentLang: 'en',
                currentServers: [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text("+ Add New Subscription"));
        await tester.pumpAndSettle();

        await tester.enterText(findDialogTextField(), "https://empty.example.com/sub");
        await tester.pumpAndSettle();

        await tester.tap(find.text("Add & Update"));
        await waitForSecondSnackBar(tester);

        expect(find.text("Successfully added 0 servers."), findsOneWidget);
      }, createHttpClient: (context) {
        return MockHttpClient((uri) async {
          return MockHttpClientResponse(statusCode: 200, body: "invalid content string");
        });
      });
    });
  });
}
