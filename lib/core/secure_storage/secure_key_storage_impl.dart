import 'dart:convert';
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
                accessibility: IOSOptionsAccessibility.whenUnlockedThisDeviceOnly,
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
      final base64Value = base64Encode(value);
      
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
      return Uint8List.fromList(value);
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

  @override
  Future<void> storeString(String key, String value, {SecureStorageOptions? options}) async {
    try {
      final opts = options ?? _defaultOptions;
      
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
          value: value,
          iOptions: iosOptions,
          aOptions: androidOptions,
        );
      } else {
        await _secureStorage.write(key: key, value: value);
      }
      
      AppLogger.debug('Stored string securely: $key');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store string: $key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String?> retrieveString(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      
      if (value == null) {
        AppLogger.debug('String not found: $key');
        return null;
      }
      
      AppLogger.debug('Retrieved string securely: $key');
      return value;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve string: $key', e, stackTrace);
      rethrow;
    }
  }

  IOSOptionsAccessibility _parseAccessibility(String accessibility) {
    switch (accessibility.toLowerCase()) {
      case 'whenunlocked':
        return IOSOptionsAccessibility.whenUnlocked;
      case 'whenunlockedthisdeviceonly':
        return IOSOptionsAccessibility.whenUnlockedThisDeviceOnly;
      case 'whenfirstunlock':
        return IOSOptionsAccessibility.whenFirstUnlock;
      case 'whenfirstunlockthisdeviceonly':
        return IOSOptionsAccessibility.whenFirstUnlockThisDeviceOnly;
      case 'always':
        return IOSOptionsAccessibility.always;
      case 'alwayswithdevicepasscode':
        return IOSOptionsAccessibility.alwaysWithDevicePasscode;
      case 'afterfirstunlock':
        return IOSOptionsAccessibility.afterFirstUnlock;
      case 'afterfirstunlockthisdeviceonly':
        return IOSOptionsAccessibility.afterFirstUnlockThisDeviceOnly;
      default:
        return IOSOptionsAccessibility.whenUnlockedThisDeviceOnly;
    }
  }
}