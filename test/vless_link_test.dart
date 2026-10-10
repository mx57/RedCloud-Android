import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('buildVlessLink tests', () {
    test('buildVlessLink with empty map uses default values', () {
      final map = <String, dynamic>{};
      final link = ServersManagementScreen.buildVlessLink(map);

      expect(
        link,
        equals(
          'vless://@:443?encryption=none&security=tls&sni=&fp=chrome&alpn=http%2F1.1&type=ws&host=&path=%2F#RedCloud_Server',
        ),
      );
    });

    test('buildVlessLink with full custom map generates expected VLESS URI', () {
      final map = <String, dynamic>{
        'uuid': '12345678-abcd-efgh-ijkl-1234567890ab',
        'address': 'example.com',
        'port': 8443,
        'security': 'reality',
        'sni': 'sni.example.com',
        'fingerprint': 'firefox',
        'alpn': 'h2,http/1.1',
        'transport': 'grpc',
        'wsHost': 'host.example.com',
        'wsPath': '/custom-path?ed=2048',
        'name': 'My Custom Server',
      };

      final link = ServersManagementScreen.buildVlessLink(map);

      final expectedAlpn = Uri.encodeComponent('h2,http/1.1');
      final expectedWsPath = Uri.encodeComponent('/custom-path?ed=2048');
      final expectedName = Uri.encodeComponent('My Custom Server');

      expect(
        link,
        equals(
          'vless://12345678-abcd-efgh-ijkl-1234567890ab@example.com:8443?encryption=none&security=reality&sni=sni.example.com&fp=firefox&alpn=$expectedAlpn&type=grpc&host=host.example.com&path=$expectedWsPath#$expectedName',
        ),
      );
    });

    test('buildVlessLink handles missing sni and wsHost by falling back to address', () {
      final map = <String, dynamic>{
        'uuid': 'test-uuid',
        'address': '1.2.3.4',
        'port': 443,
      };

      final link = ServersManagementScreen.buildVlessLink(map);

      expect(
        link,
        contains('&sni=1.2.3.4&'),
      );
      expect(
        link,
        contains('&host=1.2.3.4&'),
      );
    });

    test('buildVlessLink encodes special characters in alpn, wsPath, and name', () {
      final map = <String, dynamic>{
        'uuid': 'uuid-123',
        'address': 'test.org',
        'alpn': 'h2/h3',
        'wsPath': '/vless path with spaces&symbols',
        'name': 'سرور تست / Test Server',
      };

      final link = ServersManagementScreen.buildVlessLink(map);

      expect(link, contains('alpn=${Uri.encodeComponent('h2/h3')}'));
      expect(link, contains('path=${Uri.encodeComponent('/vless path with spaces&symbols')}'));
      expect(link, endsWith('#${Uri.encodeComponent('سرور تست / Test Server')}'));
    });
  });
}
