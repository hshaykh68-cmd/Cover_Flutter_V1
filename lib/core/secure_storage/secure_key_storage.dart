import 'dart:typed_data';
import 'package:cover/core/utils/logger.dart';

/// Secure key storage interface for platform-specific secure storage
/// 
/// This interface provides methods to securely store and retrieve cryptographic keys
/// using platform-specific secure storage mechanisms:
/// - Android: Keystore
/// - iOS: Keychain
/// 
/// Keys stored here are protected by the operating system's security features
/// and are only accessible to this app.
abstract class SecureKeyStorage {
  /// Stores a key securely
  /// 
  /// Parameters:
  /// - [key]: The key identifier
  /// - [value]: The key data to store
  /// - [options]: Optional storage options (e.g., accessibility level on iOS)
  Future<void> storeKey(String key, Uint8List value, {SecureStorageOptions? options});

  /// Retrieves a key securely
  /// 
  /// Parameters:
  /// - [key]: The key identifier
  /// 
  /// Returns the key data, or null if not found
  Future<Uint8List?> retrieveKey(String key);

  /// Deletes a key from secure storage
  /// 
  /// Parameters:
  /// - [key]: The key identifier
  Future<void> deleteKey(String key);

  /// Checks if a key exists in secure storage
  /// 
  /// Parameters:
  /// - [key]: The key identifier
  /// 
  /// Returns true if the key exists
  Future<bool> containsKey(String key);

  /// Clears all keys from secure storage
  /// 
  /// WARNING: This is a destructive operation that cannot be undone
  Future<void> clearAll();

  /// Lists all keys in secure storage
  /// 
  /// Returns a list of key identifiers
  Future<List<String>> listKeys();
}

/// Storage options for secure key storage
class SecureStorageOptions {
  /// Accessibility level on iOS (whenUnlocked, whenUnlockedThisDeviceOnly, etc.)
  final String? iosAccessibility;
  
  /// Whether to use Android Keystore (true) or fallback to encrypted preferences
  final bool? useAndroidKeystore;
  
  /// Whether to use biometric authentication to access the key
  final bool requireBiometric;

  const SecureStorageOptions({
    this.iosAccessibility,
    this.useAndroidKeystore,
    this.requireBiometric = false,
  });

  /// Default options for master key storage
  static const masterKey = SecureStorageOptions(
    iosAccessibility: 'whenUnlockedThisDeviceOnly',
    useAndroidKeystore: true,
    requireBiometric: false,
  );

  /// Default options for derived keys
  static const derivedKey = SecureStorageOptions(
    iosAccessibility: 'whenUnlocked',
    useAndroidKeystore: true,
    requireBiometric: false,
  );
}

/// Key rotation strategy for secure key storage
/// 
/// This class defines the strategy for rotating cryptographic keys
/// to enhance security over time.
class KeyRotationStrategy {
  /// Maximum age of a key before rotation is required (in days)
  final int maxKeyAgeDays;
  
  /// Whether to rotate keys on app version change
  final bool rotateOnVersionChange;
  
  /// Whether to rotate keys if security compromise is suspected
  final bool rotateOnCompromise;

  const KeyRotationStrategy({
    this.maxKeyAgeDays = 365,
    this.rotateOnVersionChange = true,
    this.rotateOnCompromise = true,
  });

  /// Default rotation strategy
  static const defaultStrategy = KeyRotationStrategy(
    maxKeyAgeDays: 365,
    rotateOnVersionChange: true,
    rotateOnCompromise: true,
  });

  /// High-security rotation strategy (for sensitive data)
  static const highSecurityStrategy = KeyRotationStrategy(
    maxKeyAgeDays: 90,
    rotateOnVersionChange: true,
    rotateOnCompromise: true,
  );
}
