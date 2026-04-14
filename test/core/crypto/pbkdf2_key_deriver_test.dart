import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/crypto/pbkdf2_key_deriver.dart';
import 'package:cover/core/crypto/crypto_service_impl.dart';
import 'package:cover/test/core/crypto/crypto_test_vectors.dart';

void main() {
  group('Pbkdf2KeyDeriver', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoServiceImpl(
        pbkdf2Iterations: 1000, // Use lower iterations for faster tests
      );
    });

    test('should derive key from password', () async {
      final password = 'test_password';
      
      final result = await cryptoService.deriveKey(password);

      expect(result.key, hasLength(32));
      expect(result.salt, hasLength(16));
    });

    test('should derive same key with same password and salt', () async {
      final password = 'test_password';
      final salt = cryptoService.generateRandomSalt(length: 16);
      
      final result1 = await cryptoService.deriveKey(password, salt: salt);
      final result2 = await cryptoService.deriveKey(password, salt: salt);

      expect(result1.key, equals(result2.key));
      expect(result1.salt, equals(result2.salt));
    });

    test('should derive different keys with different passwords', () async {
      final salt = cryptoService.generateRandomSalt(length: 16);
      
      final result1 = await cryptoService.deriveKey('password1', salt: salt);
      final result2 = await cryptoService.deriveKey('password2', salt: salt);

      expect(result1.key, isNot(equals(result2.key)));
    });

    test('should derive different keys with different salts', () async {
      final password = 'test_password';
      
      final result1 = await cryptoService.deriveKey(password);
      final result2 = await cryptoService.deriveKey(password);

      expect(result1.key, isNot(equals(result2.key)));
      expect(result1.salt, isNot(equals(result2.salt)));
    });

    test('should handle empty password', () async {
      final password = '';
      
      final result = await cryptoService.deriveKey(password);

      expect(result.key, hasLength(32));
      expect(result.salt, hasLength(16));
    });

    test('should handle special characters in password', () async {
      final password = r'p@ssw0rd!#$%^&*()';
      
      final result = await cryptoService.deriveKey(password);

      expect(result.key, hasLength(32));
      expect(result.salt, hasLength(16));
    });

    test('should handle unicode characters in password', () async {
      final password = '密码🔐';
      
      final result = await cryptoService.deriveKey(password);

      expect(result.key, hasLength(32));
      expect(result.salt, hasLength(16));
    });

    test('should derive key with custom iterations', () async {
      final password = 'test_password';
      const iterations = 500;
      
      final deriver = Pbkdf2KeyDeriver(iterations: iterations);
      final result = await deriver.deriveKey(password);

      expect(result.key, hasLength(32));
      expect(result.salt, hasLength(16));
    });

    test('should derive key with custom key length', () async {
      final password = 'test_password';
      const keyLength = 64;
      
      final deriver = Pbkdf2KeyDeriver(keyLength: keyLength);
      final result = await deriver.deriveKey(password);

      expect(result.key, hasLength(keyLength));
    });

    test('should derive key with custom salt length', () async {
      final password = 'test_password';
      const saltLength = 32;
      
      final deriver = Pbkdf2KeyDeriver(saltLength: saltLength);
      final result = await deriver.deriveKey(password);

      expect(result.salt, hasLength(saltLength));
    });

    test('should validate security parameters', () {
      final secureDeriver = Pbkdf2KeyDeriver(
        iterations: 100000,
        keyLength: 32,
        saltLength: 16,
      );

      expect(secureDeriver.isSecure(), isTrue);

      final insecureDeriver = Pbkdf2KeyDeriver(
        iterations: 100,
        keyLength: 8,
        saltLength: 8,
      );

      expect(insecureDeriver.isSecure(), isFalse);
    });

    test('should convert to and from bytes correctly', () async {
      final password = 'test_password';
      
      final result = await cryptoService.deriveKey(password);

      final bytes = result.toBytes();
      final restored = DerivedKeyResult.fromBytes(bytes, 16, 32);

      expect(restored.key, equals(result.key));
      expect(restored.salt, equals(result.salt));
    });

    test('should convert to and from base64 correctly', () async {
      final password = 'test_password';
      
      final result = await cryptoService.deriveKey(password);

      final base64 = result.toBase64();
      final restored = DerivedKeyResult.fromBase64(base64, 16, 32);

      expect(restored.key, equals(result.key));
      expect(restored.salt, equals(result.salt));
    });

    test('should throw on invalid byte array length during fromBytes', () {
      expect(
        () => DerivedKeyResult.fromBytes(Uint8List(10), 16, 32),
        throwsArgumentError,
      );
    });

    test('deriveKeyWithSalt should work correctly', () async {
      final password = 'test_password';
      final salt = cryptoService.generateRandomSalt(length: 16);
      
      final key1 = await cryptoService.deriveKeyWithSalt(password, salt);
      final key2 = await cryptoService.deriveKeyWithSalt(password, salt);

      expect(key1, equals(key2));
      expect(key1, hasLength(32));
    });
  });

  group('DerivedKeyResult', () {
    test('should handle empty key and salt', () {
      final result = DerivedKeyResult(
        key: Uint8List(32),
        salt: Uint8List(16),
      );

      final bytes = result.toBytes();
      final restored = DerivedKeyResult.fromBytes(bytes, 16, 32);

      expect(restored.key, isEmpty);
      expect(restored.salt, isEmpty);
    });
  });
}
