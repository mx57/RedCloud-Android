import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('Secure Password Generation Tests', () {
    test('generateSecureRandomPassword generates password of requested length',
        () {
      final pwd10 = LanShareScreen.generateSecureRandomPassword(10);
      expect(pwd10.length, equals(10));

      final pwd16 = LanShareScreen.generateSecureRandomPassword(16);
      expect(pwd16.length, equals(16));
    });

    test('generateSecureRandomPassword uses valid alphanumeric characters', () {
      final pwd = LanShareScreen.generateSecureRandomPassword(100);
      final validChars = RegExp(r'^[a-zA-Z0-9]+$');
      expect(validChars.hasMatch(pwd), isTrue);
    });

    test(
        'generateSecureRandomPassword generates non-deterministic unique values',
        () {
      final passwords = List.generate(
          50, (_) => LanShareScreen.generateSecureRandomPassword(10));
      final uniquePasswords = passwords.toSet();
      expect(uniquePasswords.length, equals(passwords.length));
    });
  });
}
