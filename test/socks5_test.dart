import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('SOCKS5 Error & Handshake Tests - HomePage.querySocks5Json', () {
    test('Connection failure on unopen port returns null', () async {
      // Find an unopen local port by binding temporarily and closing
      final tempServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final unopenPort = tempServer.port;
      await tempServer.close();

      final result = await HomePage.querySocks5Json(
        unopenPort,
        'ip-api.com',
        '/json/',
        timeoutMs: 500,
      );

      expect(result, isNull);
    });

    test('Successful SOCKS5 handshake and HTTP JSON query returns parsed Map with pingMs', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      late StreamSubscription serverSub;
      serverSub = server.listen((socket) {
        int stage = 0;
        socket.listen((data) {
          if (stage == 0) {
            // SOCKS5 greeting [0x05, 0x01, 0x00]
            if (data.length >= 3 && data[0] == 0x05) {
              stage = 1;
              socket.add([0x05, 0x00]); // SOCKS5 choice: No authentication required
              socket.flush();
            }
          } else if (stage == 1) {
            // SOCKS5 connect request [0x05, 0x01, 0x00, 0x03, len, ...]
            if (data.length >= 5 && data[0] == 0x05 && data[1] == 0x01) {
              stage = 2;
              // Reply SOCKS5 success: 10 bytes [0x05, 0x00, 0x00, 0x01, 0,0,0,0, 0,0]
              socket.add([0x05, 0x00, 0x00, 0x01, 127, 0, 0, 1, 0, 80]);
              socket.flush();
            }
          } else if (stage == 2) {
            // HTTP Request
            final reqStr = utf8.decode(data, allowMalformed: true);
            if (reqStr.contains('GET /json/ HTTP/1.1')) {
              final jsonResponseBody = '{"status":"success","country":"TestLand","query":"192.168.1.1"}';
              final httpResponse = 'HTTP/1.1 200 OK\r\n'
                  'Content-Type: application/json\r\n'
                  'Content-Length: ${jsonResponseBody.length}\r\n'
                  '\r\n'
                  '$jsonResponseBody';
              socket.add(utf8.encode(httpResponse));
              socket.flush();
            }
          }
        });
      });

      try {
        final result = await HomePage.querySocks5Json(
          port,
          'ip-api.com',
          '/json/',
          timeoutMs: 2000,
        );

        expect(result, isNotNull);
        expect(result!['status'], equals('success'));
        expect(result['country'], equals('TestLand'));
        expect(result['query'], equals('192.168.1.1'));
        expect(result['pingMs'], isA<int>());
        expect(result['pingMs'], greaterThanOrEqualTo(0));
      } finally {
        await serverSub.cancel();
        await server.close();
      }
    });

    test('SOCKS5 auth rejection returns null', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      late StreamSubscription serverSub;
      serverSub = server.listen((socket) {
        socket.listen((data) {
          // Send auth rejection (0xFF)
          socket.add([0x05, 0xFF]);
          socket.flush();
        });
      });

      try {
        final result = await HomePage.querySocks5Json(
          port,
          'ip-api.com',
          '/json/',
          timeoutMs: 1000,
        );

        expect(result, isNull);
      } finally {
        await serverSub.cancel();
        await server.close();
      }
    });

    test('SOCKS5 connect failure response returns null', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      late StreamSubscription serverSub;
      serverSub = server.listen((socket) {
        int stage = 0;
        socket.listen((data) {
          if (stage == 0) {
            stage = 1;
            socket.add([0x05, 0x00]); // Auth OK
            socket.flush();
          } else if (stage == 1) {
            // Send connect error (0x01: general SOCKS server failure)
            socket.add([0x05, 0x01, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
            socket.flush();
          }
        });
      });

      try {
        final result = await HomePage.querySocks5Json(
          port,
          'ip-api.com',
          '/json/',
          timeoutMs: 1000,
        );

        expect(result, isNull);
      } finally {
        await serverSub.cancel();
        await server.close();
      }
    });

    test('Timeout when server does not respond returns null', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      late StreamSubscription serverSub;
      serverSub = server.listen((socket) {
        // Accept connection but never respond
      });

      try {
        final result = await HomePage.querySocks5Json(
          port,
          'ip-api.com',
          '/json/',
          timeoutMs: 200,
        );

        expect(result, isNull);
      } finally {
        await serverSub.cancel();
        await server.close();
      }
    });

    test('Malformed HTTP response or invalid JSON returns null', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;

      late StreamSubscription serverSub;
      serverSub = server.listen((socket) {
        int stage = 0;
        socket.listen((data) {
          if (stage == 0) {
            stage = 1;
            socket.add([0x05, 0x00]);
            socket.flush();
          } else if (stage == 1) {
            stage = 2;
            socket.add([0x05, 0x00, 0x00, 0x01, 127, 0, 0, 1, 0, 80]);
            socket.flush();
          } else if (stage == 2) {
            // Reply with malformed JSON
            socket.add(utf8.encode('HTTP/1.1 200 OK\r\n\r\n{invalid_json:true}'));
            socket.flush();
          }
        });
      });

      try {
        final result = await HomePage.querySocks5Json(
          port,
          'ip-api.com',
          '/json/',
          timeoutMs: 200,
        );

        expect(result, isNull);
      } finally {
        await serverSub.cancel();
        await server.close();
      }
    });
  });
}
