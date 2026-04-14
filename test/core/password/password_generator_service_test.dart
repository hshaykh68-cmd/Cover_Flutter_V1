import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/password/password_generator_service.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/domain/repository/remote_config_repository.dart';

class MockRemoteConfigRepository implements RemoteConfigRepository {
  @override
  bool getBool(String key, bool defaultValue) => defaultValue;

  @override
  int getInt(String key, int defaultValue) => defaultValue;

  @override
  String getString(String key, String defaultValue) => defaultValue;

  @override
  double getDouble(String key, double defaultValue) => defaultValue;
}

void main() {
  late PasswordGeneratorService passwordGeneratorService;
  late AppConfig appConfig;

  setUp(() {
    final mockRemoteConfig = MockRemoteConfigRepository();
    appConfig = AppConfig(mockRemoteConfig);
    passwordGeneratorService = PasswordGeneratorServiceImpl(appConfig);
  });

  group('PasswordGeneratorService', () {
    test('should generate password with default length', () {
      final password = passwordGeneratorService.generatePassword();
      expect(password.length, appConfig.passwordGeneratorMin);
    });

    test('should generate password with custom length', () {
      final password = passwordGeneratorService.generatePassword(length: 20);
      expect(password.length, 20);
    });

    test('should include uppercase letters when enabled', () {
      final password = passwordGeneratorService.generatePassword(
        includeUppercase: true,
        includeLowercase: false,
        includeNumbers: false,
        includeSpecialChars: false,
      );
      expect(password, contains(RegExp(r'[A-Z]')));
    });

    test('should include lowercase letters when enabled', () {
      final password = passwordGeneratorService.generatePassword(
        includeUppercase: false,
        includeLowercase: true,
        includeNumbers: false,
        includeSpecialChars: false,
      );
      expect(password, contains(RegExp(r'[a-z]')));
    });

    test('should include numbers when enabled', () {
      final password = passwordGeneratorService.generatePassword(
        includeUppercase: false,
        includeLowercase: false,
        includeNumbers: true,
        includeSpecialChars: false,
      );
      expect(password, contains(RegExp(r'[0-9]')));
    });

    test('should include special characters when enabled', () {
      final password = passwordGeneratorService.generatePassword(
        includeUppercase: false,
        includeLowercase: false,
        includeNumbers: false,
        includeSpecialChars: true,
      );
      expect(password, contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]')));
    });

    test('should exclude ambiguous characters when requested', () {
      final password = passwordGeneratorService.generatePassword(
        excludeAmbiguous: true,
      );
      expect(password, isNot(contains(RegExp(r'[0O1lI]'))));
    });

    test('should throw error when no character types are selected', () {
      expect(
        () => passwordGeneratorService.generatePassword(
          includeUppercase: false,
          includeLowercase: false,
          includeNumbers: false,
          includeSpecialChars: false,
        ),
        throwsArgumentError,
      );
    });

    test('should generate passphrase with default word count', () {
      final passphrase = passwordGeneratorService.generatePassphrase();
      final words = passphrase.split('-');
      expect(words.length, 4);
    });

    test('should generate passphrase with custom word count', () {
      final passphrase = passwordGeneratorService.generatePassphrase(wordCount: 6);
      final words = passphrase.split('-');
      expect(words.length, 6);
    });

    test('should capitalize words when requested', () {
      final passphrase = passwordGeneratorService.generatePassphrase(capitalize: true);
      final words = passphrase.split('-');
      for (final word in words) {
        expect(word[0], equals(word[0].toUpperCase()));
      }
    });

    test('should not capitalize words when not requested', () {
      final passphrase = passwordGeneratorService.generatePassphrase(capitalize: false);
      final words = passphrase.split('-');
      for (final word in words) {
        expect(word[0], equals(word[0].toLowerCase()));
      }
    });

    test('should use custom separator', () {
      final passphrase = passwordGeneratorService.generatePassphrase(separator: '_');
      expect(passphrase, contains('_'));
      expect(passphrase, isNot(contains('-')));
    });

    test('should throw error for passphrase with less than 2 words', () {
      expect(
        () => passwordGeneratorService.generatePassphrase(wordCount: 1),
        throwsArgumentError,
      );
    });

    test('should estimate strength for weak password', () {
      final strength = passwordGeneratorService.estimateStrength('abc123');
      expect(strength, lessThan(40));
    });

    test('should estimate strength for medium password', () {
      final strength = passwordGeneratorService.estimateStrength('Abc123!@');
      expect(strength, greaterThanOrEqualTo(40));
      expect(strength, lessThan(70));
    });

    test('should estimate strength for strong password', () {
      final strength = passwordGeneratorService.estimateStrength('Abc123!@#Xyz789');
      expect(strength, greaterThanOrEqualTo(70));
    });

    test('should return 0 strength for empty password', () {
      final strength = passwordGeneratorService.estimateStrength('');
      expect(strength, 0);
    });

    test('should penalize repeated characters', () {
      final password1 = passwordGeneratorService.estimateStrength('Aa1!Aa1!Aa1!');
      final password2 = passwordGeneratorService.estimateStrength('Aa1!Bb2@Cc3#');
      expect(password1, lessThan(password2));
    });

    test('should check if password meets requirements', () {
      final password = passwordGeneratorService.generatePassword();
      expect(passwordGeneratorService.meetsRequirements(password), isTrue);
    });

    test('should reject password that is too short', () {
      final password = 'Aa1!';
      expect(passwordGeneratorService.meetsRequirements(password), isFalse);
    });

    test('should reject password that lacks variety', () {
      final password = 'aaaaaaaaaaaa';
      expect(passwordGeneratorService.meetsRequirements(password), isFalse);
    });

    test('should generate different passwords on multiple calls', () {
      final passwords = <String>{};
      for (int i = 0; i < 10; i++) {
        passwords.add(passwordGeneratorService.generatePassword());
      }
      expect(passwords.length, greaterThan(1));
    });

    test('should generate different passphrases on multiple calls', () {
      final passphrases = <String>{};
      for (int i = 0; i < 10; i++) {
        passphrases.add(passwordGeneratorService.generatePassphrase());
      }
      expect(passphrases.length, greaterThan(1));
    });
  });
}
