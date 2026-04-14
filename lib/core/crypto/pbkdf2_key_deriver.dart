import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:cover/core/utils/logger.dart';

/// PBKDF2 (Password-Based Key Derivation Function 2)
/// 
/// Derives cryptographic keys from passwords using HMAC-SHA256
/// with configurable iterations for security.
class Pbkdf2KeyDeriver {
  final int iterations;
  final int keyLength;
  final int saltLength;

  Pbkdf2KeyDeriver({
    this.iterations = 100000,
    this.keyLength = 32, // 256 bits for AES-256
    this.saltLength = 16, // 128 bits salt
  });

  /// Derives a cryptographic key from a password
  /// 
  /// Parameters:
  /// - [password]: The password string (PIN in our case)
  /// - [salt]: Optional salt bytes. If not provided, a random salt will be generated.
  ///   The same salt must be used for key derivation verification.
  /// 
  /// Returns a [DerivedKeyResult] containing the derived key and the salt used
  Future<DerivedKeyResult> deriveKey(
    String password, {
    Uint8List? salt,
  }) async {
    try {
      // Generate random salt if not provided
      final actualSalt = salt ?? _generateSalt();

      // Convert password to bytes
      final passwordBytes = utf8.encode(password);

      // Use the cryptography package's PBKDF2 implementation
      final algorithm = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: keyLength * 8,
      );

      final secretKey = await algorithm.deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: actualSalt,
      );

      final keyBytes = await secretKey.extractBytes();

      return DerivedKeyResult(
        key: keyBytes,
        salt: actualSalt,
      );
    } catch (e, stackTrace) {
      AppLogger.error('PBKDF2 key derivation failed', e, stackTrace);
      rethrow;
    }
  }

  /// Derives a key from a password using a specific salt
  /// 
  /// This is used when you already have a stored salt and want to
  /// derive the same key (e.g., for verification)
  Future<Uint8List> deriveKeyWithSalt(
    String password,
    Uint8List salt,
  ) async {
    final result = await deriveKey(password, salt: salt);
    return result.key;
  }

  /// Generates a cryptographically secure random salt
  Uint8List _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Validates that the provided parameters are secure
  /// 
  /// Returns true if parameters meet security recommendations
  bool isSecure() {
    // NIST recommends at least 10,000 iterations as of 2017
    // OWASP recommends 100,000+ for SHA-256 as of 2024
    if (iterations < 10000) {
      return false;
    }

    // Key length should be at least 128 bits (16 bytes) for AES
    if (keyLength < 16) {
      return false;
    }

    // Salt should be at least 128 bits (16 bytes)
    if (saltLength < 16) {
      return false;
    }

    return true;
  }
}

/// Result of key derivation operation
class DerivedKeyResult {
  final Uint8List key;
  final Uint8List salt;

  DerivedKeyResult({
    required this.key,
    required this.salt,
  });

  /// Converts to a single byte array for storage
  /// Format: [salt (16 bytes)] [key (32 bytes)]
  Uint8List toBytes() {
    final buffer = BytesBuilder();
    buffer.add(salt);
    buffer.add(key);
    return buffer.toBytes();
  }

  /// Creates DerivedKeyResult from a byte array
  /// Format: [salt (16 bytes)] [key (32 bytes)]
  static DerivedKeyResult fromBytes(Uint8List bytes, int saltLength, int keyLength) {
    if (bytes.length != saltLength + keyLength) {
      throw ArgumentError(
        'Byte array length must be ${saltLength + keyLength}, got ${bytes.length}',
      );
    }

    final salt = bytes.sublist(0, saltLength);
    final key = bytes.sublist(saltLength);

    return DerivedKeyResult(
      salt: salt,
      key: key,
    );
  }

  /// Converts to base64 string for storage
  String toBase64() {
    return toBytes().buffer.asUint8List().base64Encode();
  }

  /// Creates DerivedKeyResult from base64 string
  static DerivedKeyResult fromBase64(String base64, int saltLength, int keyLength) {
    final bytes = base64Decode(base64);
    return fromBytes(bytes, saltLength, keyLength);
  }
}
