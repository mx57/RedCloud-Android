import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('ServersManagementScreen.parseV2RayShareLink deserialization tests', () {
    test('vmess:// link parsing - valid json config', () {
      final vmessJson = {
        "v": "2",
        "ps": "VMess Test Server",
        "add": "vmess.example.com",
        "port": "8080",
        "id": "12345678-1234-1234-1234-123456789abc",
        "aid": "0",
        "scy": "zero",
        "net": "ws",
        "type": "none",
        "host": "host.example.com",
        "path": "/vmesspath",
        "tls": "tls",
        "sni": "sni.example.com",
        "alpn": ""
      };

      final b64 = base64.encode(utf8.encode(jsonEncode(vmessJson)));
      final rawLink = "vmess://$b64";

      final result = ServersManagementScreen.parseV2RayShareLink(rawLink);

      expect(result['protocol'], 'VMESS');
      expect(result['name'], 'VMess Test Server');
      expect(result['address'], 'vmess.example.com');
      expect(result['port'], 8080);
      expect(result['uuid'], '12345678-1234-1234-1234-123456789abc');
      expect(result['transport'], 'ws');
      expect(result['wsHost'], 'host.example.com');
      expect(result['wsPath'], '/vmesspath');
      expect(result['security'], 'tls');
      expect(result['sni'], 'sni.example.com');
      expect(result['fingerprint'], 'chrome');
      expect(result['alpn'], 'http/1.1');
      expect(result['rawLink'], rawLink);
    });

    test('vmess:// link parsing - non-tls security', () {
      final vmessJson = {
        "ps": "VMess Non TLS",
        "add": "1.2.3.4",
        "port": 80,
        "id": "uuid-123",
        "net": "tcp",
        "tls": "none"
      };

      final b64 = base64.encode(utf8.encode(jsonEncode(vmessJson)));
      final rawLink = "vmess://$b64";

      final result = ServersManagementScreen.parseV2RayShareLink(rawLink);

      expect(result['protocol'], 'VMESS');
      expect(result['name'], 'VMess Non TLS');
      expect(result['address'], '1.2.3.4');
      expect(result['port'], 80);
      expect(result['uuid'], 'uuid-123');
      expect(result['transport'], 'tcp');
      expect(result['security'], 'none');
      expect(result['wsHost'], '1.2.3.4');
      expect(result['sni'], '1.2.3.4');
    });

    test('vless:// link parsing - full parameters and URL encoding', () {
      const rawLink = "vless://user-uuid-1234@vless.example.com:8443?type=ws&security=tls&sni=sni.test.com&host=ws.test.com&path=%2Fvlesspath&fp=firefox&alpn=h2#VLESS%20Server%20Name";

      final result = ServersManagementScreen.parseV2RayShareLink(rawLink);

      expect(result['protocol'], 'VLESS');
      expect(result['name'], 'VLESS Server Name');
      expect(result['address'], 'vless.example.com');
      expect(result['port'], 8443);
      expect(result['uuid'], 'user-uuid-1234');
      expect(result['transport'], 'ws');
      expect(result['security'], 'tls');
      expect(result['sni'], 'sni.test.com');
      expect(result['wsHost'], 'ws.test.com');
      expect(result['wsPath'], '/vlesspath');
      expect(result['fingerprint'], 'firefox');
      expect(result['alpn'], 'h2');
    });

    test('trojan:// link parsing', () {
      const rawLink = "trojan://pass123@trojan.example.com:443?net=grpc&security=tls&peer=peer.example.com#Trojan%20Server";

      final result = ServersManagementScreen.parseV2RayShareLink(rawLink);

      expect(result['protocol'], 'TROJAN');
      expect(result['name'], 'Trojan Server');
      expect(result['address'], 'trojan.example.com');
      expect(result['port'], 443);
      expect(result['uuid'], 'pass123');
      expect(result['transport'], 'grpc');
      expect(result['security'], 'tls');
      expect(result['sni'], 'peer.example.com');
      expect(result['wsHost'], 'peer.example.com');
    });

    test('default values and defaultName when parameters missing or invalid', () {
      const rawLink = "vless://@fallback.com#";

      final result = ServersManagementScreen.parseV2RayShareLink(rawLink, defaultName: "Custom Default Name");

      expect(result['protocol'], 'VLESS');
      expect(result['name'], 'Custom Default Name');
      expect(result['address'], 'fallback.com');
      expect(result['port'], 443);
      expect(result['uuid'], '');
      expect(result['transport'], 'ws');
      expect(result['wsPath'], '/');
      expect(result['security'], 'tls');
      expect(result['fingerprint'], 'chrome');
      expect(result['alpn'], 'http/1.1');
    });

    test('malformed/invalid link gracefully handles exception and returns defaults', () {
      const rawLink = "vmess://not_valid_base64_json!!!";

      final result = ServersManagementScreen.parseV2RayShareLink(rawLink, defaultName: "Malformed Link Test");

      expect(result['name'], 'Malformed Link Test');
      expect(result['protocol'], 'VMESS');
      expect(result['address'], '');
      expect(result['port'], 443);
      expect(result['rawLink'], rawLink);
    });
  });
}
