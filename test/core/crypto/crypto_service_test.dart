import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/crypto/crypto_service_impl.dart';
import 'package:cover/test/core/crypto/crypto_test_vectors.dart';

void main() {
  group('CryptoService', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoServiceImpl();
    });

    group('Key Generation', () {
      test('should generate random key of correct length', () {
        final key = cryptoService.generateRandomKey(length: 32);
        expect(key, hasLength(32));
      });

      test('should generate different keys on each call', () {
        final key1 = cryptoService.generateRandomKey(length: 32);
        final key2 = cryptoService.generateRandomKey(length: 32);
        expect(key1, isNot(equals(key2)));
      });

      test('should generate random salt of correct length', () {
        final salt = cryptoService.generateRandomSalt(length: 16);
        expect(salt, hasLength(16));
      });

      test('should generate random nonce of correct length', () {
        final nonce = cryptoService.generateRandomNonce(length: 12);
        expect(nonce, hasLength(12));
      });
    });

    group('String Encryption/Decryption', () {
      test('should encrypt and decrypt string correctly', () async {
        final key = cryptoService.generateRandomKey(length: 32);
        final plaintext = 'Hello, World!';
        
        final encrypted = await cryptoService.encryptString(
          plaintext,
          key,
        );

        final decrypted = await cryptoService.decryptString(encrypted, key);

        expect(decrypted, equals(plaintext));
      });

      test('should encrypt and decrypt empty string', () async {
        final key = cryptoService.generateRandomKey(length: 32);
        final plaintext = '';
        
        final encrypted = await cryptoService.encryptString(
          plaintext,
          key,
        );

        final decrypted = await cryptoService.decryptString(encrypted, key);

        expect(decrypted, equals(plaintext));
      });

      test('should encrypt and decrypt unicode string', () async {
        final key = cryptoService.generateRandomKey(length: 32);
        final plaintext = '密码🔐🔒';
        
        final encrypted = await cryptoService.encryptString(
          plaintext,
          key,
        );

        final decrypted = await cryptoService.decryptString(encrypted, key);

        expect(decrypted, equals(plaintext));
      });

      test('should encrypt and decrypt long string', () async {
        final key = cryptoService.generateRandomKey(length: 32);
        final plaintext = 'A' * 10000;
        
        final encrypted = await cryptoService.encryptString(
          plaintext,
          key,
        );

        final decrypted = await cryptoService.decryptString(encrypted, key);

        expect(decrypted, equals(plaintext));
      });
    });

    group('SHA-256 Hashing', () {
      test('should hash empty string correctly', () {
        final input = Uint8List(0);
        final hash = cryptoService.sha256Hash(input);
        
        final expected = AesGcmTestVectors.hexToBytes(
          Sha256TestVectors.testVector1['expected']!,
        );
        
        expect(hash, equals(expected));
      });

      test('should hash "abc" correctly', () {
        final input = 'abc'.codeUnits;
        final hash = cryptoService.sha256Hash(Uint8List.fromList(input));
        
        final expected = AesGcmTestVectors.hexToBytes(
          Sha256TestVectors.testVector2['expected']!,
        );
        
        expect(hash, equals(expected));
      });

      test('should hash long string correctly', () {
        final input = Sha256TestVectors.testVector3['input']!.codeUnits;
        final hash = cryptoService.sha256Hash(Uint8List.fromList(input));
        
        final expected = AesGcmTestVectors.hexToBytes(
          Sha256TestVectors.testVector3['expected']!,
        );
        
        expect(hash, equals(expected));
      });

      test('should produce same hash for same input', () {
        final input = 'test'.codeUnits;
        final hash1 = cryptoService.sha256Hash(Uint8List.fromList(input));
        final hash2 = cryptoService.sha256Hash(Uint8List.fromList(input));
        
        expect(hash1, equals(hash2));
      });

      test('should produce different hash for different input', () {
        final input1 = 'test1'.codeUnits;
        final input2 = 'test2'.codeUnits;
        final hash1 = cryptoService.sha256Hash(Uint8List.fromList(input1));
        final hash2 = cryptoService.sha256Hash(Uint8List.fromList(input2));
        
        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('Constant-Time Comparison', () {
      test('should return true for equal byte arrays', () {
        final bytes1 = Uint8List.fromList([1, 2, 3, 4]);
        final bytes2 = Uint8List.fromList([1, 2, 3, 4]);
        
        expect(cryptoService.constantTimeCompare(bytes1, bytes2), isTrue);
      });

      test('should return false for different byte arrays', () {
        final bytes1 = Uint8List.fromList([1, 2, 3, 4]);
        final bytes2 = Uint8List.fromList([1, 2, 3, 5]);
        
        expect(cryptoService.constantTimeCompare(bytes1, bytes2), isFalse);
      });

      test('should return false for different length arrays', () {
        final bytes1 = Uint8List.fromList([1, 2, 3, 4]);
        final bytes2 = Uint8List.fromList([1, 2, 3]);
        
        expect(cryptoService.constantTimeCompare(bytes1, bytes2), isFalse);
      });

      test('should handle empty arrays', () {
        final bytes1 = Uint8List(0);
        final bytes2 = Uint8List(0);
        
        expect(cryptoService.constantTimeCompare(bytes1, bytes2), isTrue);
      });
    });

    group('End-to-End Crypto Flow', () {
      test('should complete full encryption/decryption flow with key derivation', () async {
        final password = 'my_secure_pin';
        
        // Derive key from password
        final keyResult = await cryptoService.deriveKey(password);
        
        // Encrypt data with derived key
        final plaintext = 'Secret message';
        final encrypted = await cryptoService.encryptString(
          plaintext,
          keyResult.key,
        );
        
        // Decrypt data with derived key
        final decrypted = await cryptoService.decryptString(
          encrypted,
          keyResult.key,
        );
        
        expect(decrypted, equals(plaintext));
      });

      test('should complete full flow with stored salt', () async {
        final password = 'my_secure_pin';
        
        // Derive key and store salt
        final keyResult1 = await cryptoService.deriveKey(password);
        final storedSalt = keyResult1.salt;
        
        // Derive same key using stored salt
        final key2 = await cryptoService.deriveKeyWithSalt(password, storedSalt);
        
        // Verify keys are the same
        expect(key2, equals(keyResult1.key));
        
        // Encrypt and decrypt with derived key
        final plaintext = 'Secret message';
        final encrypted = await cryptoService.encryptString(plaintext, key2);
        final decrypted = await cryptoService.decryptString(encrypted, key2);
        
        expect(decrypted, equals(plaintext));
      });
    });

    group('Custom Configuration', () {
      test('should accept custom PBKDF2 iterations', () {
        final customService = CryptoServiceImpl(pbkdf2Iterations: 50000);
        expect(customService, isA<CryptoService>());
      });

      test('should accept custom key length', () {
        final customService = CryptoServiceImpl(keyLength: 64);
        expect(customService, isA<CryptoService>());
      });

      test('should accept custom salt length', () {
        final customService = CryptoServiceImpl(saltLength: 32);
        expect(customService, isA<CryptoService>());
      });
    });
  });
}
