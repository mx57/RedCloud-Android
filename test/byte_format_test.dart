import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('Byte formatting tests', () {
    test('Zero or negative bytes format correctly', () {
      expect(HomePage.formatBytes(0), equals('0 B'));
      expect(HomePage.formatBytes(-10), equals('0 B'));
      expect(HomePage.formatBytes(0, isSpeed: true), equals('0 B/s'));
      expect(HomePage.formatBytes(-100, isSpeed: true), equals('0 B/s'));
    });

    test('Bytes formatting without speed suffix', () {
      expect(HomePage.formatBytes(500), equals('500.0 B'));
      expect(HomePage.formatBytes(1023), equals('1023.0 B'));
      expect(HomePage.formatBytes(1024), equals('1.0 KB'));
      expect(HomePage.formatBytes(1536), equals('1.5 KB'));
      expect(HomePage.formatBytes(1048576), equals('1.0 MB'));
      expect(HomePage.formatBytes(1572864), equals('1.5 MB'));
      expect(HomePage.formatBytes(1073741824), equals('1.0 GB'));
      expect(HomePage.formatBytes(1610612736), equals('1.5 GB'));
      expect(HomePage.formatBytes(1099511627776), equals('1.0 TB'));
      expect(HomePage.formatBytes(5497558138880), equals('5.0 TB'));
    });

    test('Bytes formatting with speed suffix', () {
      expect(HomePage.formatBytes(500, isSpeed: true), equals('500.0 B/s'));
      expect(HomePage.formatBytes(1024, isSpeed: true), equals('1.0 KB/s'));
      expect(HomePage.formatBytes(1572864, isSpeed: true), equals('1.5 MB/s'));
      expect(HomePage.formatBytes(1073741824, isSpeed: true), equals('1.0 GB/s'));
      expect(HomePage.formatBytes(1099511627776, isSpeed: true), equals('1.0 TB/s'));
    });
  });
}
