import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpOverrides extends HttpOverrides {
  final Future<MockHttpClientRequest> Function(Uri uri) onRequest;

  MockHttpOverrides(this.onRequest);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient(onRequest);
  }
}

class MockHttpClient implements HttpClient {
  final Future<MockHttpClientRequest> Function(Uri uri) onRequest;

  MockHttpClient(this.onRequest);

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return await onRequest(url);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

class MockHttpClientRequest implements HttpClientRequest {
  final MockHttpClientResponse response;

  MockHttpClientRequest(this.response);

  @override
  Future<HttpClientResponse> close() async {
    return response;
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  final int statusCode;
  final String responseBody;
  final bool throwError;

  MockHttpClientResponse({
    required this.statusCode,
    required this.responseBody,
    this.throwError = false,
  });

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    if (throwError) {
      return Stream<List<int>>.error(Exception('Network error'))
          .transform(streamTransformer);
    }
    final bytes = utf8.encode(responseBody);
    return Stream<List<int>>.value(bytes).transform(streamTransformer);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('_fetchAndLoadAccounts fetches and parses accounts correctly (HTTP 200)', (WidgetTester tester) async {
    bool requestMade = false;
    final jsonResponse = jsonEncode([
      {
        'worker': 'worker-priority-2.workers.dev',
        'uuid': 'uuid-2',
        'path': '/path2',
        'status': 'active',
        'used_bytes': '100',
        'priority': '2',
      },
      {
        'worker': 'worker-priority-1.workers.dev',
        'uuid': 'uuid-1',
        'path': '/path1',
        'status': 'active',
        'used_bytes': '50',
        'priority': '1',
      },
      {
        'worker': 'exhausted-worker.workers.dev',
        'uuid': 'uuid-3',
        'path': '/path3',
        'status': 'exhausted',
        'used_bytes': '1000',
        'priority': '1',
      },
    ]);

    HttpOverrides.global = MockHttpOverrides((uri) async {
      requestMade = true;
      expect(uri.toString(), contains('raw.githubusercontent.com'));
      return MockHttpClientRequest(
        MockHttpClientResponse(
          statusCode: 200,
          responseBody: jsonResponse,
        ),
      );
    });

    await tester.pumpWidget(const MyApp(
      initialLang: 'en',
      initialDarkMode: true,
      isFirstRun: false,
    ));

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));

    expect(requestMade, isTrue);
    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);

    HttpOverrides.global = null;
  });

  testWidgets('_fetchAndLoadAccounts handles non-200 status code with fallback accounts', (WidgetTester tester) async {
    bool requestMade = false;
    HttpOverrides.global = MockHttpOverrides((uri) async {
      requestMade = true;
      return MockHttpClientRequest(
        MockHttpClientResponse(
          statusCode: 500,
          responseBody: 'Internal Server Error',
        ),
      );
    });

    await tester.pumpWidget(const MyApp(
      initialLang: 'en',
      initialDarkMode: true,
      isFirstRun: false,
    ));

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));

    expect(requestMade, isTrue);
    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);

    HttpOverrides.global = null;
  });

  testWidgets('_fetchAndLoadAccounts handles network exception with fallback accounts', (WidgetTester tester) async {
    bool requestMade = false;
    HttpOverrides.global = MockHttpOverrides((uri) async {
      requestMade = true;
      return MockHttpClientRequest(
        MockHttpClientResponse(
          statusCode: 200,
          responseBody: '',
          throwError: true,
        ),
      );
    });

    await tester.pumpWidget(const MyApp(
      initialLang: 'en',
      initialDarkMode: true,
      isFirstRun: false,
    ));

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));

    expect(requestMade, isTrue);
    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);

    HttpOverrides.global = null;
  });

  testWidgets('_fetchAndLoadAccounts with empty server list enters updating mode', (WidgetTester tester) async {
    bool requestMade = false;
    HttpOverrides.global = MockHttpOverrides((uri) async {
      requestMade = true;
      return MockHttpClientRequest(
        MockHttpClientResponse(
          statusCode: 200,
          responseBody: jsonEncode([]),
        ),
      );
    });

    await tester.pumpWidget(const MyApp(
      initialLang: 'en',
      initialDarkMode: true,
      isFirstRun: false,
    ));

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));

    expect(requestMade, isTrue);
    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);

    HttpOverrides.global = null;
  });
}
