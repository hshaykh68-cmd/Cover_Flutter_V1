import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:cover/core/utils/logger.dart';

/// AES-GCM (Galois/Counter Mode) cipher for authenticated encryption
/// 
/// Provides confidentiality and integrity of data using AES-256-GCM
/// as specified in the PRD requirements.
class AesGcmCipher {
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _nonceLength = 12; // 96 bits nonce as recommended for GCM

  final SecretKey _secretKey;

  AesGcmCipher(this._secretKey);

  /// Creates a cipher from a raw key bytes
  factory AesGcmCipher.fromKeyBytes(Uint8List keyBytes) {
    if (keyBytes.length != _keyLength) {
      throw ArgumentError(
        'Key must be $_keyLength bytes (256 bits), got ${keyBytes.length}',
      );
    }
    return AesGcmCipher(SecretKey(keyBytes));
  }

  /// Encrypts plaintext using AES-256-GCM
  /// 
  /// Returns [EncryptedData] containing ciphertext and authentication tag
  /// 
  /// Parameters:
  /// - [plaintext]: The data to encrypt
  /// - [associatedData]: Optional additional authenticated data (AAD)
  ///   that is authenticated but not encrypted
  /// - [nonce]: Optional 12-byte nonce. If not provided, a random nonce
  ///   will be generated. The nonce must be unique for each encryption
  ///   with the same key.
  Future<EncryptedData> encrypt(
    Uint8List plaintext, {
    Uint8List? associatedData,
    Uint8List? nonce,
  }) async {
    try {
      // Generate random nonce if not provided
      final actualNonce = nonce ?? _generateNonce();

      // Use the cryptography package's AES-GCM implementation
      final algorithm = AesGcm.with256bits(nonceLength: _nonceLength);
      
      final secretBox = await algorithm.encrypt(
        plaintext,
        secretKey: _secretKey,
        nonce: actualNonce,
        aad: associatedData,
      );

      return EncryptedData(
        ciphertext: secretBox.cipherText,
        nonce: secretBox.nonce,
        mac: secretBox.mac.bytes,
      );
    } catch (e, stackTrace) {
      AppLogger.error('AES-GCM encryption failed', e, stackTrace);
      rethrow;
    }
  }

  /// Decrypts ciphertext using AES-256-GCM
  /// 
  /// Parameters:
  /// - [encryptedData]: The encrypted data containing ciphertext, nonce, and MAC
  /// - [associatedData]: Optional AAD that was used during encryption
  /// 
  /// Returns the decrypted plaintext
  /// 
  /// Throws [MacValidationException] if authentication fails (tampering detected)
  Future<Uint8List> decrypt(
    EncryptedData encryptedData, {
    Uint8List? associatedData,
  }) async {
    try {
      final algorithm = AesGcm.with256bits(nonceLength: _nonceLength);
      
      final secretBox = SecretBox(
        encryptedData.ciphertext,
        nonce: encryptedData.nonce,
        mac: Mac(encryptedData.mac),
      );

      final plaintext = await algorithm.decrypt(
        secretBox,
        secretKey: _secretKey,
        aad: associatedData,
      );

      return plaintext;
    } on MacValidationException catch (e, stackTrace) {
      AppLogger.error('AES-GCM decryption failed: MAC validation error', e, stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('AES-GCM decryption failed', e, stackTrace);
      rethrow;
    }
  }

  /// Generates a cryptographically secure random nonce
  static Uint8List _generateNonce() {
    return AesGcm.with256bits(nonceLength: _nonceLength).newNonce();
  }

  /// Returns the key length in bytes
  static int get keyLength => _keyLength;

  /// Returns the nonce length in bytes
  static int get nonceLength => _nonceLength;
}

/// Container for encrypted data
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  EncryptedData({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  /// Converts to a single byte array for storage/transmission
  /// Format: [nonce (12 bytes)] [mac (16 bytes)] [ciphertext]
  Uint8List toBytes() {
    final buffer = BytesBuilder();
    buffer.add(nonce);
    buffer.add(mac);
    buffer.add(ciphertext);
    return buffer.toBytes();
  }

  /// Creates EncryptedData from a byte array
  /// Format: [nonce (12 bytes)] [mac (16 bytes)] [ciphertext]
  static EncryptedData fromBytes(Uint8List bytes) {
    if (bytes.length < AesGcmCipher.nonceLength + 16) {
      throw ArgumentError('Byte array too short to contain valid encrypted data');
    }

    final nonce = bytes.sublist(0, AesGcmCipher.nonceLength);
    final mac = bytes.sublist(AesGcmCipher.nonceLength, AesGcmCipher.nonceLength + 16);
    final ciphertext = bytes.sublist(AesGcmCipher.nonceLength + 16);

    return EncryptedData(
      nonce: nonce,
      mac: mac,
      ciphertext: ciphertext,
    );
  }

  /// Converts to base64 string for storage/transmission
  String toBase64() {
    return toBytes().buffer.asUint8List().base64Encode();
  }

  /// Creates EncryptedData from base64 string
  static EncryptedData fromBase64(String base64) {
    final bytes = base64Decode(base64);
    return fromBytes(bytes);
  }
}
