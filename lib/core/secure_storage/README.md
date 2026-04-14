# Secure Key Storage Module

## Overview

This module provides secure key storage using platform-specific secure storage mechanisms:
- **Android**: Keystore (via flutter_secure_storage)
- **iOS**: Keychain (via flutter_secure_storage)

## Components

### Secure Key Storage Interface (`secure_key_storage.dart`)

**Purpose**: Abstract interface for secure key storage operations

**Features**:
- Store and retrieve cryptographic keys
- Delete keys
- Check key existence
- List all keys
- Clear all keys
- Configurable storage options (accessibility level, biometric requirements)

**Security Properties**:
- Keys are encrypted at rest by the platform
- Keys are only accessible to this app
- Platform-specific security (Android Keystore / iOS Keychain)

### Secure Key Storage Implementation (`secure_key_storage_impl.dart`)

**Purpose**: Implementation using flutter_secure_storage

**Features**:
- Base64 encoding for binary data storage
- Platform-specific accessibility levels
- Optional biometric authentication
- Encrypted SharedPreferences on Android (when Keystore unavailable)

**Usage Example**:
```dart
final secureStorage = ref.watch(secureKeyStorageProvider);

// Store a key
final key = cryptoService.generateRandomKey(length: 32);
await secureStorage.storeKey('master_key', key);

// Retrieve a key
final retrieved = await secureStorage.retrieveKey('master_key');

// Delete a key
await secureStorage.deleteKey('master_key');

// Check existence
final exists = await secureStorage.containsKey('master_key');
```

### Key Rotation Strategy (`KEY_ROTATION_STRATEGY.md`)

**Purpose**: Defines strategy for rotating cryptographic keys

**Key Types**:
1. **Master Encryption Key (MEK)**: Encrypts database key and other sensitive keys
2. **Database Encryption Key (DEK)**: Encrypts SQLite database via SQLCipher
3. **PIN-Derived Keys**: Derived from PINs for vault access

**Rotation Triggers**:
- Time-based (maxKeyAgeDays: 365 default, 90 for high-security)
- App version change (rotateOnVersionChange: true)
- Security compromise (rotateOnCompromise: true)

**Rotation Process**:
1. Generate new key
2. Re-encrypt data with new key
3. Update storage
4. Archive old key for rollback (7 days)
5. Delete archived key after verification

## Security Considerations

### Key Storage
- Keys never leave secure storage in plaintext
- Keys are encrypted at rest by the platform
- Keys are never logged or exposed

### Platform Security
- **Android**: Uses Keystore with hardware-backed security (when available)
- **iOS**: Uses Keychain with device-specific encryption

### Backup Keys
- Stored with limited lifetime (7 days)
- Encrypted with separate key
- Deleted after verification period

### Audit Trail
- Log all rotation events
- Include timestamp, key type, rotation reason
- Send to Firebase Analytics for security monitoring

## Testing

Run the secure storage tests:
```bash
flutter test test/core/secure_storage/
```

Test coverage includes:
- ✅ Store and retrieve keys
- ✅ Empty and large key handling
- ✅ Key deletion
- ✅ Key existence checking
- ✅ Clear all keys
- ✅ List keys
- ✅ Custom storage options
- ✅ Key rotation strategy values

## Dependencies

- `flutter_secure_storage`: Platform-specific secure storage

## Future Enhancements

- [ ] Hardware-backed key integration (Android StrongBox, iOS Secure Enclave)
- [ ] Multi-key rotation (rotate multiple keys in single operation)
- [ ] Key versioning (track key versions for rollback)
- [ ] Automatic key health checks
- [ ] Key rotation scheduling (user-defined windows)
