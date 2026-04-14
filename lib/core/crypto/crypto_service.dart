import 'dart:typed_data';
import 'package:cover/core/crypto/aes_gcm_cipher.dart';
import 'package:cover/core/crypto/pbkdf2_key_deriver.dart';

/// Crypto service interface for all cryptographic operations
/// 
/// This service provides a unified interface for:
/// - Key derivation from passwords/PINs
/// - Encryption/decryption of data
/// - Secure random number generation
abstract class CryptoService {
  /// Derives a cryptographic key from a password/PIN
  /// 
  /// Returns a [DerivedKeyResult] containing the derived key and salt
  Future<DerivedKeyResult> deriveKey(String password, {Uint8List? salt});

  /// Derives a key using a specific salt (for verification)
  Future<Uint8List> deriveKeyWithSalt(String password, Uint8List salt);

  /// Encrypts data using AES-256-GCM
  /// 
  /// Parameters:
  /// - [plaintext]: Data to encrypt
  /// - [key]: 256-bit encryption key
  /// - [associatedData]: Optional AAD for authentication
  /// - [nonce]: Optional 12-byte nonce (random if not provided)
  Future<EncryptedData> encrypt(
    Uint8List plaintext,
    Uint8List key, {
    Uint8List? associatedData,
    Uint8List? nonce,
  });

  /// Decrypts data using AES-256-GCM
  /// 
  /// Parameters:
  /// - [encryptedData]: Encrypted data with nonce and MAC
  /// - [key]: 256-bit decryption key
  /// - [associatedData]: Optional AAD used during encryption
  Future<Uint8List> decrypt(
    EncryptedData encryptedData,
    Uint8List key, {
    Uint8List? associatedData,
  });

  /// Encrypts a string using AES-256-GCM
  Future<EncryptedData> encryptString(
    String plaintext,
    Uint8List key, {
    Uint8List? associatedData,
    Uint8List? nonce,
  });

  /// Decrypts to string using AES-256-GCM
  Future<String> decryptString(
    EncryptedData encryptedData,
    Uint8List key, {
    Uint8List? associatedData,
  });

  /// Generates a cryptographically secure random key
  Uint8List generateRandomKey({int length = 32});

  /// Generates a cryptographically secure random salt
  Uint8List generateRandomSalt({int length = 16});

  /// Generates a cryptographically secure random nonce
  Uint8List generateRandomNonce({int length = 12});

  /// Hashes data using SHA-256
  Uint8List sha256Hash(Uint8List data);

  /// Constant-time comparison to prevent timing attacks
  bool constantTimeCompare(Uint8List a, Uint8List b);

  /// Converts bytes to base64 string
  String bytesToBase64(Uint8List data);

  /// Converts base64 string to bytes
  Uint8List base64ToBytes(String base64);

  /// Hashes a PIN using PBKDF2 with the given salt
  /// 
  /// Returns the hashed PIN as base64 string
  Future<String> hashPin(String pin, Uint8List salt);
}
