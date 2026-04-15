import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:cover/core/crypto/aes_gcm_cipher.dart';
import 'package:cover/core/crypto/pbkdf2_key_deriver.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/constants/app_constants.dart';
import 'package:cover/core/utils/logger.dart';

/// Implementation of CryptoService
/// 
/// Provides cryptographic operations using:
/// - AES-256-GCM for encryption/decryption
/// - PBKDF2-SHA256 for key derivation
/// - SHA-256 for hashing
class CryptoServiceImpl implements CryptoService {
  final Pbkdf2KeyDeriver _keyDeriver;

  CryptoServiceImpl({
    int? pbkdf2Iterations,
    int? keyLength,
    int? saltLength,
  }) : _keyDeriver = Pbkdf2KeyDeriver(
          iterations: pbkdf2Iterations ?? AppConstants.defaultKeyDerivationIterations,
          keyLength: keyLength ?? 32,
          saltLength: saltLength ?? 16,
        ) {
    if (!_keyDeriver.isSecure()) {
      AppLogger.warning('PBKDF2 parameters do not meet security recommendations');
    }
  }

  @override
  Future<DerivedKeyResult> deriveKey(String password, {Uint8List? salt}) async {
    return await _keyDeriver.deriveKey(password, salt: salt);
  }

  @override
  Future<Uint8List> deriveKeyWithSalt(String password, Uint8List salt) async {
    return await _keyDeriver.deriveKeyWithSalt(password, salt);
  }

  @override
  Future<EncryptedData> encrypt(
    Uint8List plaintext,
    Uint8List key, {
    Uint8List? associatedData,
    Uint8List? nonce,
  }) async {
    final cipher = AesGcmCipher.fromKeyBytes(key);
    return await cipher.encrypt(
      plaintext,
      associatedData: associatedData,
      nonce: nonce,
    );
  }

  @override
  Future<Uint8List> decrypt(
    EncryptedData encryptedData,
    Uint8List key, {
    Uint8List? associatedData,
  }) async {
    final cipher = AesGcmCipher.fromKeyBytes(key);
    return await cipher.decrypt(
      encryptedData,
      associatedData: associatedData,
    );
  }

  @override
  Future<EncryptedData> encryptString(
    String plaintext,
    Uint8List key, {
    Uint8List? associatedData,
    Uint8List? nonce,
  }) async {
    final plaintextBytes = utf8.encode(plaintext);
    return await encrypt(
      Uint8List.fromList(plaintextBytes),
      key,
      associatedData: associatedData,
      nonce: nonce,
    );
  }

  @override
  Future<String> decryptString(
    EncryptedData encryptedData,
    Uint8List key, {
    Uint8List? associatedData,
  }) async {
    final decryptedBytes = await decrypt(
      encryptedData,
      key,
      associatedData: associatedData,
    );
    return utf8.decode(decryptedBytes);
  }

  @override
  Uint8List generateRandomKey({int length = 32}) {
    return _generateSecureRandom(length);
  }

  @override
  Uint8List generateRandomSalt({int length = 16}) {
    return _generateSecureRandom(length);
  }

  @override
  Uint8List generateRandomNonce({int length = 12}) {
    return _generateSecureRandom(length);
  }

  @override
  Future<Uint8List> sha256Hash(Uint8List data) async {
    try {
      final algorithm = Sha256();
      final hash = await algorithm.hash(data);
      return Uint8List.fromList(hash.bytes);
    } catch (e, stackTrace) {
      AppLogger.error('SHA-256 hashing failed', e, stackTrace);
      rethrow;
    }
  }

  @override
  bool constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }

  @override
  String bytesToBase64(Uint8List data) {
    return base64Encode(data);
  }

  @override
  Uint8List base64ToBytes(String base64) {
    return base64Decode(base64);
  }

  /// Generates cryptographically secure random bytes
  Uint8List _generateSecureRandom(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  @override
  Future<String> hashPin(String pin, Uint8List salt) async {
    final pinBytes = utf8.encode(pin);
    final derivedKey = await _keyDeriver.deriveKeyWithSalt(pin, salt);
    return base64Encode(derivedKey);
  }

  @override
  Future<EncryptedData> encryptBytes(Uint8List plaintext, Uint8List key, {
    Uint8List? associatedData,
    Uint8List? nonce,
  }) async {
    return await encrypt(plaintext, key, associatedData: associatedData, nonce: nonce);
  }

  @override
  Future<Uint8List> decryptBytes(EncryptedData encryptedData, Uint8List key, {
    Uint8List? associatedData,
  }) async {
    return await decrypt(encryptedData, key, associatedData: associatedData);
  }
}
