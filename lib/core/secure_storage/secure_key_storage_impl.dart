import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/utils/logger.dart';

/// Implementation of SecureKeyStorage using flutter_secure_storage
/// 
/// This implementation uses:
/// - Android: Keystore (via flutter_secure_storage)
/// - iOS: Keychain (via flutter_secure_storage)
/// 
/// The storage is encrypted and protected by the operating system's
/// security features.
class SecureKeyStorageImpl implements SecureKeyStorage {
  final FlutterSecureStorage _secureStorage;
  final SecureStorageOptions _defaultOptions;

  SecureKeyStorageImpl({
    FlutterSecureStorage? secureStorage,
    SecureStorageOptions defaultOptions = SecureStorageOptions.masterKey,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.whenUnlockedThisDeviceOnly,
              ),
            ),
        _defaultOptions = defaultOptions;

  @override
  Future<void> storeKey(
    String key,
    Uint8List value, {
    SecureStorageOptions? options,
  }) async {
    try {
      final opts = options ?? _defaultOptions;
      
      // Convert bytes to base64 for storage
      final base64Value = value.buffer.asUint8List().base64Encode();
      
      // Store with optional iOS accessibility
      final iosOptions = opts.iosAccessibility != null
          ? IOSOptions(
              accessibility: _parseAccessibility(opts.iosAccessibility!),
            )
          : null;

      final androidOptions = opts.useAndroidKeystore != null
          ? AndroidOptions(
              encryptedSharedPreferences: opts.useAndroidKeystore!,
            )
          : null;

      if (iosOptions != null || androidOptions != null) {
        await _secureStorage.write(
          key: key,
          value: base64Value,
          iOptions: iosOptions,
          aOptions: androidOptions,
        );
      } else {
        await _secureStorage.write(key: key, value: base64Value);
      }
      
      AppLogger.debug('Stored key securely: $key');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store key: $key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Uint8List?> retrieveKey(String key) async {
    try {
      final base64Value = await _secureStorage.read(key: key);
      
      if (base64Value == null) {
        AppLogger.debug('Key not found: $key');
        return null;
      }
      
      // Convert base64 back to bytes
      final value = base64Decode(base64Value);
      
      AppLogger.debug('Retrieved key securely: $key');
      return value;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve key: $key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteKey(String key) async {
    try {
      await _secureStorage.delete(key: key);
      AppLogger.debug('Deleted key: $key');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete key: $key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final contains = await _secureStorage.containsKey(key: key);
      AppLogger.debug('Key exists check: $key = $contains');
      return contains;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check key existence: $key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      AppLogger.warning('Cleared all keys from secure storage');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear all keys', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<String>> listKeys() async {
    try {
      final keys = await _secureStorage.readAll();
      AppLogger.debug('Listed ${keys.length} keys from secure storage');
      return keys.keys.toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list keys', e, stackTrace);
      rethrow;
    }
  }

  KeychainAccessibility _parseAccessibility(String accessibility) {
    switch (accessibility.toLowerCase()) {
      case 'whenunlocked':
        return KeychainAccessibility.whenUnlocked;
      case 'whenunlockedthisdeviceonly':
        return KeychainAccessibility.whenUnlockedThisDeviceOnly;
      case 'whenfirstunlock':
        return KeychainAccessibility.whenFirstUnlock;
      case 'whenfirstunlockthisdeviceonly':
        return KeychainAccessibility.whenFirstUnlockThisDeviceOnly;
      case 'always':
        return KeychainAccessibility.always;
      case 'alwayswithdevicepasscode':
        return KeychainAccessibility.alwaysWithDevicePasscode;
      case 'afterfirstunlock':
        return KeychainAccessibility.afterFirstUnlock;
      case 'afterfirstunlockthisdeviceonly':
        return KeychainAccessibility.afterFirstUnlockThisDeviceOnly;
      default:
        return KeychainAccessibility.whenUnlockedThisDeviceOnly;
    }
  }
}
