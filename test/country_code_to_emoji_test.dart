import 'package:flutter_test/flutter_test.dart';
import 'package:redcloud_android/main.dart';

void main() {
  group('HomePage.countryCodeToEmoji', () {
    test('converts valid uppercase 2-letter country codes to flag emojis', () {
      expect(HomePage.countryCodeToEmoji('US'), '🇺🇸');
      expect(HomePage.countryCodeToEmoji('DE'), '🇩🇪');
      expect(HomePage.countryCodeToEmoji('FR'), '🇫🇷');
      expect(HomePage.countryCodeToEmoji('RU'), '🇷🇺');
      expect(HomePage.countryCodeToEmoji('IR'), '🇮🇷');
      expect(HomePage.countryCodeToEmoji('CA'), '🇨🇦');
      expect(HomePage.countryCodeToEmoji('GB'), '🇬🇧');
    });

    test('converts valid lowercase 2-letter country codes to flag emojis', () {
      expect(HomePage.countryCodeToEmoji('us'), '🇺🇸');
      expect(HomePage.countryCodeToEmoji('de'), '🇩🇪');
      expect(HomePage.countryCodeToEmoji('ir'), '🇮🇷');
      expect(HomePage.countryCodeToEmoji('ru'), '🇷🇺');
    });

    test('returns globe emoji for invalid length inputs', () {
      expect(HomePage.countryCodeToEmoji(''), '🌐');
      expect(HomePage.countryCodeToEmoji('U'), '🌐');
      expect(HomePage.countryCodeToEmoji('USA'), '🌐');
      expect(HomePage.countryCodeToEmoji('UNITED STATES'), '🌐');
    });

    test('returns globe emoji for non-alphabetic 2-character inputs', () {
      expect(HomePage.countryCodeToEmoji('12'), '🌐');
      expect(HomePage.countryCodeToEmoji('A1'), '🌐');
      expect(HomePage.countryCodeToEmoji('1A'), '🌐');
      expect(HomePage.countryCodeToEmoji('!@'), '🌐');
      expect(HomePage.countryCodeToEmoji('  '), '🌐');
    });
  });
}
