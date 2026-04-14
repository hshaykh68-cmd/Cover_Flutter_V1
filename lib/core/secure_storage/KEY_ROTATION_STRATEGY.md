# Key Rotation Strategy

## Overview

This document defines the key rotation strategy for the Cover app to ensure long-term security of encrypted data.

## Key Types

### 1. Master Encryption Key (MEK)
- **Purpose**: Encrypts the database key and other sensitive keys
- **Storage**: Platform secure storage (Android Keystore / iOS Keychain)
- **Rotation Frequency**: 365 days (configurable via Remote Config)
- **Rotation Trigger**: 
  - Time-based (maxKeyAgeDays)
  - App version change (rotateOnVersionChange)
  - Security compromise (rotateOnCompromise)

### 2. Database Encryption Key (DEK)
- **Purpose**: Encrypts the SQLite database via SQLCipher
- **Storage**: Encrypted with MEK and stored in secure storage
- **Rotation Frequency**: 90 days (high-security mode)
- **Rotation Strategy**: 
  - Generate new DEK
  - Re-encrypt entire database with new DEK
  - Update DEK in secure storage
  - Archive old DEK for recovery (time-limited)

### 3. PIN-Derived Keys
- **Purpose**: Unlock vaults (real and decoy)
- **Storage**: Not stored - derived from PIN each time
- **Rotation**: User-triggered (PIN change)
- **Strategy**: 
  - When user changes PIN, derive new keys
  - Re-encrypt all data with new keys
  - Delete old PIN-derived data

## Rotation Process

### Time-Based Rotation

1. **Check Key Age**: On app launch, check if any key has exceeded maxKeyAgeDays
2. **Schedule Rotation**: If rotation needed, schedule during idle time
3. **Generate New Key**: Create new cryptographic key
4. **Re-encrypt Data**: Decrypt all data with old key, encrypt with new key
5. **Update Storage**: Replace old key with new key in secure storage
6. **Archive Old Key**: Store old key temporarily for rollback (7 days)
7. **Delete Old Key**: After verification period, delete archived key

### Version-Based Rotation

1. **Detect Version Change**: Compare current version with stored version
2. **Trigger Rotation**: If version changed and rotateOnVersionChange is true
3. **Follow Time-Based Process**: Execute same rotation steps

### Compromise-Based Rotation

1. **Detect Compromise**: User reports potential compromise or suspicious activity
2. **Immediate Rotation**: Force rotation of all keys
3. **Follow Time-Based Process**: Execute same rotation steps
4. **Security Audit**: Log rotation event for security review

## Key Rotation Implementation

### Master Key Rotation

```dart
Future<void> rotateMasterKey() async {
  // 1. Generate new master key
  final newMasterKey = cryptoService.generateRandomKey(length: 32);
  
  // 2. Retrieve current master key
  final currentMasterKey = await secureStorage.retrieveKey('master_key');
  
  // 3. Re-encrypt database key with new master key
  final encryptedDbKey = await secureStorage.retrieveKey('encrypted_db_key');
  final dbKey = await cryptoService.decrypt(encryptedDbKey, currentMasterKey);
  final newEncryptedDbKey = await cryptoService.encrypt(dbKey, newMasterKey);
  
  // 4. Update stored keys
  await secureStorage.storeKey('master_key', newMasterKey);
  await secureStorage.storeKey('encrypted_db_key', newEncryptedDbKey);
  
  // 5. Archive old master key for rollback
  await secureStorage.storeKey('master_key_backup', currentMasterKey);
  
  // 6. Schedule deletion of backup
  await scheduleBackupDeletion(days: 7);
}
```

### Database Key Rotation

```dart
Future<void> rotateDatabaseKey() async {
  // 1. Generate new database key
  final newDbKey = cryptoService.generateRandomKey(length: 32);
  
  // 2. Open database with current key
  final currentDbKey = await getDatabaseKey();
  final database = await openDatabase(currentDbKey);
  
  // 3. Re-encrypt entire database
  await database.rekey(newDbKey);
  
  // 4. Update stored database key
  await updateDatabaseKey(newDbKey);
  
  // 5. Verify database integrity
  await verifyDatabaseIntegrity();
  
  // 6. Close database
  await database.close();
}
```

## Rollback Strategy

### Automatic Rollback

If rotation fails:
1. Restore from archived key
2. Log failure for investigation
3. Notify user (if applicable)
4. Schedule retry with exponential backoff

### Manual Rollback

If user reports issues:
1. Admin can trigger rollback via Remote Config
2. Restore from archived key
3. Investigate failure cause
4. Fix issue before retry

## Security Considerations

### Key Storage
- Keys never leave secure storage in plaintext
- Keys are encrypted at rest
- Keys are never logged or exposed

### Rotation Timing
- Rotate during app idle time to minimize user impact
- Show progress indicator for long rotations
- Allow user to defer rotation (with warning)

### Backup Keys
- Store backups with limited lifetime (7 days)
- Encrypt backups with separate key
- Delete backups after verification period

### Audit Trail
- Log all rotation events
- Include timestamp, key type, rotation reason
- Send to Firebase Analytics for security monitoring

## Remote Config Integration

Key rotation parameters are controlled via Firebase Remote Config:

```json
{
  "key_rotation_max_age_days": 365,
  "key_rotation_on_version_change": true,
  "key_rotation_on_compromise": true,
  "key_rotation_backup_days": 7,
  "key_rotation_enabled": true
}
```

## Testing

### Unit Tests
- Test key generation
- Test encryption/decryption during rotation
- Test rollback scenarios
- Test backup deletion scheduling

### Integration Tests
- Test full rotation process
- Test database rekey operation
- Test concurrent rotation requests
- Test rotation during database operations

### Security Tests
- Verify keys never exposed in logs
- Verify secure storage integration
- Verify backup key isolation
- Verify audit trail completeness

## Future Enhancements

- [ ] Hardware-backed key rotation (Android StrongBox, iOS Secure Enclave)
- [ ] Multi-key rotation (rotate multiple keys in single operation)
- [ ] Key versioning (track key versions for rollback)
- [ ] Automatic key health checks
- [ ] Key rotation scheduling (user-defined windows)
