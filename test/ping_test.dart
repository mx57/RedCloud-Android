import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('pingAddress unit tests', () {
    late ServerSocket serverSocket;
    late int serverPort;

    setUpAll(() async {
      // Start a local ServerSocket on loopback port
      serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      serverPort = serverSocket.port;

      // Handle incoming connections and close them
      serverSocket.listen((clientSocket) {
        clientSocket.destroy();
      });
    });

    tearDownAll(() async {
      await serverSocket.close();
    });

    test('returns non-negative elapsed time when host and port are reachable', () async {
      final ping = await pingAddress('127.0.0.1', serverPort, timeout: const Duration(milliseconds: 1000));
      expect(ping, greaterThanOrEqualTo(0));
    });

    test('returns -1 when connection fails due to closed port', () async {
      // Bind a temporary server socket to get an unassigned port, then close it immediately
      final tempSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final closedPort = tempSocket.port;
      await tempSocket.close();

      final ping = await pingAddress('127.0.0.1', closedPort, timeout: const Duration(milliseconds: 500));
      expect(ping, equals(-1));
    });

    test('returns -1 when connection times out', () async {
      // 10.255.255.1 is in a private network range that usually drops or times out connection attempts
      final ping = await pingAddress('10.255.255.1', 81, timeout: const Duration(milliseconds: 100));
      expect(ping, equals(-1));
    });

    test('returns -1 for invalid or unreachable hostname', () async {
      final ping = await pingAddress('invalid.domain.that.does.not.exist.local', 80, timeout: const Duration(milliseconds: 500));
      expect(ping, equals(-1));
    });
  });
}
