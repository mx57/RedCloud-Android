import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('_verifyDnsIp UDP logic tests', () {
    late RawDatagramSocket serverSocket;

    setUp(() async {
      serverSocket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() {
      serverSocket.close();
    });

    List<int> buildDnsResponse({
      required int ancount,
      required List<int> ipOctets,
      int totalLength = 32,
    }) {
      final List<int> bytes = List<int>.filled(totalLength, 0);
      // DNS Transaction ID
      bytes[0] = 0x12;
      bytes[1] = 0x34;
      // Flags: Standard response, No error
      bytes[2] = 0x81;
      bytes[3] = 0x80;
      // QDCOUNT = 1
      bytes[4] = 0x00;
      bytes[5] = 0x01;
      // ANCOUNT
      bytes[6] = (ancount >> 8) & 0xFF;
      bytes[7] = ancount & 0xFF;

      // Put IP octets at the very end of the packet
      if (ipOctets.length == 4 && totalLength >= 4) {
        bytes[totalLength - 4] = ipOctets[0];
        bytes[totalLength - 3] = ipOctets[1];
        bytes[totalLength - 2] = ipOctets[2];
        bytes[totalLength - 1] = ipOctets[3];
      }
      return bytes;
    }

    test('Clean DNS response returns IP and latency map', () async {
      serverSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = serverSocket.receive();
          if (datagram != null) {
            final response = buildDnsResponse(
              ancount: 1,
              ipOctets: [8, 8, 8, 8],
              totalLength: 32,
            );
            serverSocket.send(response, datagram.address, datagram.port);
          }
        }
      });

      final result = await HomePageState.verifyDnsIp(
        '127.0.0.1',
        port: serverSocket.port,
        timeoutMs: 1000,
      );

      expect(result, isNotNull);
      expect(result!['ip'], equals('127.0.0.1'));
      expect(result['latency'], isA<int>());
    });

    test('Poisoned DNS response (10.10.34.x) returns null', () async {
      serverSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = serverSocket.receive();
          if (datagram != null) {
            final response = buildDnsResponse(
              ancount: 1,
              ipOctets: [10, 10, 34, 1],
            );
            serverSocket.send(response, datagram.address, datagram.port);
          }
        }
      });

      final result = await HomePageState.verifyDnsIp(
        '127.0.0.1',
        port: serverSocket.port,
        timeoutMs: 1000,
      );

      expect(result, isNull);
    });

    test('Poisoned DNS responses (private/loopback ranges) return null', () async {
      final poisonedIps = [
        [10, 0, 0, 1],
        [127, 0, 0, 1],
        [0, 1, 2, 3],
        [192, 168, 1, 1],
        [172, 16, 0, 1],
        [172, 31, 255, 255],
        [0, 0, 0, 0],
      ];

      for (final ipOctets in poisonedIps) {
        final server = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((event) {
          if (event == RawSocketEvent.read) {
            final dg = server.receive();
            if (dg != null) {
              final resp = buildDnsResponse(ancount: 1, ipOctets: ipOctets);
              server.send(resp, dg.address, dg.port);
            }
          }
        });

        final res = await HomePageState.verifyDnsIp(
          '127.0.0.1',
          port: server.port,
          timeoutMs: 500,
        );
        expect(res, isNull, reason: 'Failed for poisoned IP $ipOctets');
        server.close();
      }
    });

    test('Response with ANCOUNT = 0 returns null', () async {
      serverSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = serverSocket.receive();
          if (dg != null) {
            final resp = buildDnsResponse(
              ancount: 0,
              ipOctets: [8, 8, 8, 8],
            );
            serverSocket.send(resp, dg.address, dg.port);
          }
        }
      });

      final result = await HomePageState.verifyDnsIp(
        '127.0.0.1',
        port: serverSocket.port,
        timeoutMs: 500,
      );

      expect(result, isNull);
    });

    test('Response shorter than 32 bytes returns null', () async {
      serverSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = serverSocket.receive();
          if (dg != null) {
            final resp = buildDnsResponse(
              ancount: 1,
              ipOctets: [8, 8, 8, 8],
              totalLength: 20, // < 32 bytes
            );
            serverSocket.send(resp, dg.address, dg.port);
          }
        }
      });

      final result = await HomePageState.verifyDnsIp(
        '127.0.0.1',
        port: serverSocket.port,
        timeoutMs: 500,
      );

      expect(result, isNull);
    });

    test('Timeout when server does not respond returns null', () async {
      // Server does not reply
      final result = await HomePageState.verifyDnsIp(
        '127.0.0.1',
        port: serverSocket.port,
        timeoutMs: 100,
      );

      expect(result, isNull);
    });

    test('Invalid target IP address returns null', () async {
      final result = await HomePageState.verifyDnsIp(
        'not-a-valid-ip',
        port: 53,
        timeoutMs: 100,
      );

      expect(result, isNull);
    });
  });
}
