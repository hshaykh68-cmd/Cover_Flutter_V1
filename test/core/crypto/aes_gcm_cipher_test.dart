import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/crypto/aes_gcm_cipher.dart';
import 'package:cover/core/crypto/crypto_service_impl.dart';
import 'package:cover/test/core/crypto/crypto_test_vectors.dart';

void main() {
  group('AesGcmCipher', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoServiceImpl();
    });

    test('should encrypt and decrypt data correctly', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = 'Hello, World!'.codeUnits;
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      final decrypted = await cryptoService.decrypt(encrypted, key);

      expect(decrypted, equals(plaintext));
    });

    test('should encrypt and decrypt empty data', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = <int>[];
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      final decrypted = await cryptoService.decrypt(encrypted, key);

      expect(decrypted, isEmpty);
    });

    test('should encrypt and decrypt large data', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = List.generate(10000, (i) => i % 256);
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      final decrypted = await cryptoService.decrypt(encrypted, key);

      expect(decrypted, equals(plaintext));
    });

    test('should produce different ciphertext with same key but different nonce', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = 'Hello, World!'.codeUnits;
      
      final encrypted1 = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      final encrypted2 = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      // Different nonces should produce different ciphertext
      expect(encrypted1.ciphertext, isNot(equals(encrypted2.ciphertext)));
      expect(encrypted1.nonce, isNot(equals(encrypted2.nonce)));
    });

    test('should produce same ciphertext with same key and nonce', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final nonce = cryptoService.generateRandomNonce(length: 12);
      final plaintext = 'Hello, World!'.codeUnits;
      
      final encrypted1 = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
        nonce: nonce,
      );

      final encrypted2 = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
        nonce: nonce,
      );

      // Same nonce should produce same ciphertext
      expect(encrypted1.ciphertext, equals(encrypted2.ciphertext));
      expect(encrypted1.nonce, equals(encrypted2.nonce));
      expect(encrypted1.mac, equals(encrypted2.mac));
    });

    test('should fail to decrypt with wrong key', () async {
      final key1 = cryptoService.generateRandomKey(length: 32);
      final key2 = cryptoService.generateRandomKey(length: 32);
      final plaintext = 'Hello, World!'.codeUnits;
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key1,
      );

      expect(
        () async => await cryptoService.decrypt(encrypted, key2),
        throwsA(isA<Exception>()),
      );
    });

    test('should fail to decrypt with tampered ciphertext', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = 'Hello, World!'.codeUnits;
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      // Tamper with ciphertext
      final tamperedCiphertext = Uint8List.fromList(encrypted.ciphertext);
      tamperedCiphertext[0] = (tamperedCiphertext[0] + 1) % 256;

      final tamperedEncrypted = EncryptedData(
        ciphertext: tamperedCiphertext,
        nonce: encrypted.nonce,
        mac: encrypted.mac,
      );

      expect(
        () async => await cryptoService.decrypt(tamperedEncrypted, key),
        throwsA(isA<Exception>()),
      );
    });

    test('should fail to decrypt with tampered MAC', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = 'Hello, World!'.codeUnits;
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      // Tamper with MAC
      final tamperedMac = Uint8List.fromList(encrypted.mac);
      tamperedMac[0] = (tamperedMac[0] + 1) % 256;

      final tamperedEncrypted = EncryptedData(
        ciphertext: encrypted.ciphertext,
        nonce: encrypted.nonce,
        mac: tamperedMac,
      );

      expect(
        () async => await cryptoService.decrypt(tamperedEncrypted, key),
        throwsA(isA<Exception>()),
      );
    });

    test('should support associated data (AAD)', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = 'Hello, World!'.codeUnits;
      final aad = 'metadata'.codeUnits;
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
        associatedData: Uint8List.fromList(aad),
      );

      // Decrypt with correct AAD
      final decrypted = await cryptoService.decrypt(
        encrypted,
        key,
        associatedData: Uint8List.fromList(aad),
      );

      expect(decrypted, equals(plaintext));

      // Decrypt with wrong AAD should fail
      expect(
        () async => await cryptoService.decrypt(
          encrypted,
          key,
          associatedData: Uint8List.fromList('wrong'.codeUnits),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should convert to and from bytes correctly', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = 'Hello, World!'.codeUnits;
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      final bytes = encrypted.toBytes();
      final restored = EncryptedData.fromBytes(bytes);

      expect(restored.ciphertext, equals(encrypted.ciphertext));
      expect(restored.nonce, equals(encrypted.nonce));
      expect(restored.mac, equals(encrypted.mac));
    });

    test('should convert to and from base64 correctly', () async {
      final key = cryptoService.generateRandomKey(length: 32);
      final plaintext = 'Hello, World!'.codeUnits;
      
      final encrypted = await cryptoService.encrypt(
        Uint8List.fromList(plaintext),
        key,
      );

      final base64 = encrypted.toBase64();
      final restored = EncryptedData.fromBase64(base64);

      expect(restored.ciphertext, equals(encrypted.ciphertext));
      expect(restored.nonce, equals(encrypted.nonce));
      expect(restored.mac, equals(encrypted.mac));
    });

    test('should throw on invalid key length', () {
      expect(
        () => AesGcmCipher.fromKeyBytes(Uint8List(16)),
        throwsArgumentError,
      );
    });

    test('should throw on invalid byte array length during fromBytes', () {
      expect(
        () => EncryptedData.fromBytes(Uint8List(10)),
        throwsArgumentError,
      );
    });
  });

  group('EncryptedData', () {
    test('should handle empty ciphertext', () {
      final nonce = Uint8List(12);
      final mac = Uint8List(16);
      
      final encrypted = EncryptedData(
        ciphertext: Uint8List(0),
        nonce: nonce,
        mac: mac,
      );

      final bytes = encrypted.toBytes();
      final restored = EncryptedData.fromBytes(bytes);

      expect(restored.ciphertext, isEmpty);
    });
  });
}
