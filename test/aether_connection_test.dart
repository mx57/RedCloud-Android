import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel aetherChannel = MethodChannel('com.redcloud.vpn/aether_channel');
  const MethodChannel torChannel = MethodChannel('com.redcloud.vpn/tor_channel');
  const MethodChannel v2rayChannel = MethodChannel('flutter_v2ray_client');

  List<String> methodCalls = [];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    methodCalls.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      aetherChannel,
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      torChannel,
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      v2rayChannel,
      null,
    );
  });

  void setupMockChannels({
    bool startAetherResult = true,
    bool checkSocksReadyResult = true,
    bool requestPermissionResult = true,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      aetherChannel,
      (MethodCall methodCall) async {
        methodCalls.add("aether:${methodCall.method}");
        if (methodCall.method == 'getAtcAccountInfo') {
          return {'accountName': 'TestATC', 'remainingDays': 30};
        }
        if (methodCall.method == 'stopAether') {
          return true;
        }
        if (methodCall.method == 'startAether') {
          return startAetherResult;
        }
        if (methodCall.method == 'checkSocksReady') {
          return checkSocksReadyResult;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      torChannel,
      (MethodCall methodCall) async {
        methodCalls.add("tor:${methodCall.method}");
        if (methodCall.method == 'killAllCores') {
          return true;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      v2rayChannel,
      (MethodCall methodCall) async {
        methodCalls.add("v2ray:${methodCall.method}");
        if (methodCall.method == 'stopV2Ray') {
          return true;
        }
        if (methodCall.method == 'requestPermission') {
          return requestPermissionResult;
        }
        if (methodCall.method == 'startV2Ray') {
          return null;
        }
        return null;
      },
    );
  }

  Future<void> navigateToAetherAndTapConnect(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(
      initialLang: 'en',
      initialDarkMode: true,
      isFirstRun: false,
    ));
    await tester.pumpAndSettle();

    // Switch to Aether tab
    final aetherTabFinder = find.byIcon(Icons.bolt_rounded);
    expect(aetherTabFinder, findsOneWidget);
    await tester.tap(aetherTabFinder);
    await tester.pumpAndSettle();

    // Tap circular connect button
    final boltIcons = find.byIcon(Icons.bolt_rounded);
    final connectBtnGestureDetector = find.ancestor(
      of: boltIcons.first,
      matching: find.byType(GestureDetector),
    );
    await tester.tap(connectBtnGestureDetector);
  }

  testWidgets('Aether successful connection flow', (WidgetTester tester) async {
    setupMockChannels(
      startAetherResult: true,
      checkSocksReadyResult: true,
      requestPermissionResult: true,
    );

    await navigateToAetherAndTapConnect(tester);

    // Pump to run up to startAether and the Future.delayed in the socks ready loop
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // _resetAllEngines delay
    await tester.pump(); // startAether completes

    // Advance 500ms for Future.delayed in checkSocksReady loop
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(); // checkSocksReady completes and setState occurs

    // Verify method channel invocations
    expect(methodCalls, contains('aether:startAether'));
    expect(methodCalls, contains('aether:checkSocksReady'));
    expect(methodCalls, contains('v2ray:requestPermission'));
    expect(methodCalls, contains('v2ray:startV2Ray'));

    // Verify banner snackbar appears
    expect(find.byType(SnackBar), findsWidgets);

    // Pump timer to clear 4-second delayed timer created during initApp
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Aether connection failure - startAether binary launch fails', (WidgetTester tester) async {
    setupMockChannels(
      startAetherResult: false,
      checkSocksReadyResult: true,
      requestPermissionResult: true,
    );

    await navigateToAetherAndTapConnect(tester);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // _resetAllEngines delay
    await tester.pump(); // startAether returns false -> exception thrown -> resets engines (adds 300ms delay)
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(methodCalls, contains('aether:startAether'));
    expect(methodCalls, isNot(contains('aether:checkSocksReady')));

    // SnackBar should be displayed for error
    expect(find.byType(SnackBar), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Aether connection failure - SOCKS5 ready timeout', (WidgetTester tester) async {
    setupMockChannels(
      startAetherResult: true,
      checkSocksReadyResult: false,
      requestPermissionResult: true,
    );

    await navigateToAetherAndTapConnect(tester);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // _resetAllEngines delay
    await tester.pump(); // startAether completes

    // Advance through the 70 retries (each has 500ms delay)
    for (int i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(); // timeout exception thrown -> catch block calls _resetAllEngines (300ms delay)
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(methodCalls, contains('aether:startAether'));
    expect(methodCalls, contains('aether:checkSocksReady'));
    expect(methodCalls, isNot(contains('v2ray:requestPermission')));

    // SnackBar should be displayed for error
    expect(find.byType(SnackBar), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Aether connection failure - OS permission denied', (WidgetTester tester) async {
    setupMockChannels(
      startAetherResult: true,
      checkSocksReadyResult: true,
      requestPermissionResult: false,
    );

    await navigateToAetherAndTapConnect(tester);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // _resetAllEngines delay
    await tester.pump(); // startAether completes

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(); // checkSocksReady completes -> permission check fails -> _resetAllEngines (300ms delay)
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(methodCalls, contains('aether:startAether'));
    expect(methodCalls, contains('aether:checkSocksReady'));
    expect(methodCalls, contains('v2ray:requestPermission'));
    expect(methodCalls, isNot(contains('v2ray:startV2Ray')));

    // SnackBar should be displayed for os_perm_err
    expect(find.byType(SnackBar), findsWidgets);

    await tester.pump(const Duration(seconds: 5));
  });
}
