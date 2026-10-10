import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('HomePageState.querySocks5Json tests', () {
    late HomePageState homePageState;

    setUp(() {
      homePageState = HomePageState();
    });

    test('querySocks5Json returns null on connection failure (unopen port)', () async {
      // Find an unused port by binding a ServerSocket on port 0 and closing it immediately.
      final serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final unopenPort = serverSocket.port;
      await serverSocket.close();

      final result = await homePageState.querySocks5Json(
        unopenPort,
        'example.com',
        '/',
        timeoutMs: 1000,
      );

      expect(result, isNull);
    });

    test('querySocks5Json returns null on connection timeout', () async {
      // Start a local server socket that accepts connection but never responds
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => await server.close());

      final result = await homePageState.querySocks5Json(
        server.port,
        'example.com',
        '/',
        timeoutMs: 300,
      );

      expect(result, isNull);
    });

    test('querySocks5Json returns null on malformed SOCKS5 handshake', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => await server.close());

      server.listen((socket) {
        // Send invalid SOCKS5 auth method response (0x05, 0xFF = no acceptable methods)
        socket.add([0x05, 0xFF]);
      });

      final result = await homePageState.querySocks5Json(
        server.port,
        'example.com',
        '/',
        timeoutMs: 1000,
      );

      expect(result, isNull);
    });

    test('querySocks5Json returns parsed Map on successful SOCKS5 handshake and HTTP response', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => await server.close());

      server.listen((socket) {
        int stage = 0;
        socket.listen((data) {
          if (stage == 0) {
            // Received greeting [0x05, 0x01, 0x00]
            if (data.length >= 3 && data[0] == 0x05) {
              stage = 1;
              socket.add([0x05, 0x00]); // Auth choice: no auth
            }
          } else if (stage == 1) {
            // Received connect request [0x05, 0x01, 0x00, 0x03, ...]
            if (data.length >= 5 && data[0] == 0x05 && data[1] == 0x01) {
              stage = 2;
              // Response: succeed
              socket.add([
                0x05, 0x00, 0x00, 0x01,
                127, 0, 0, 1,
                0x00, 0x50,
              ]);
            }
          } else if (stage == 2) {
            // Received HTTP request
            final httpResponse =
                "HTTP/1.1 200 OK\r\n"
                "Content-Type: application/json\r\n"
                "\r\n"
                '{"status":"success","query":"1.2.3.4","country":"United States","countryCode":"US"}';
            socket.add(utf8.encode(httpResponse));
          }
        });
      });

      final result = await homePageState.querySocks5Json(
        server.port,
        'ip-api.com',
        '/json/',
        timeoutMs: 2000,
      );

      expect(result, isNotNull);
      expect(result!['status'], equals('success'));
      expect(result['query'], equals('1.2.3.4'));
      expect(result['countryCode'], equals('US'));
      expect(result['pingMs'], isA<int>());
    });
  });
}
