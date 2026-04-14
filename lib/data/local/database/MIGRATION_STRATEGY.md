# Database Migration Strategy

## Overview

This document defines the migration strategy for the Cover app's encrypted database using Drift + SQLCipher.

## Migration Principles

1. **Backward Compatibility**: Ensure migrations are backward compatible where possible
2. **Data Integrity**: Never lose data during migration
3. **Rollback Support**: Maintain ability to rollback if migration fails
4. **Incremental Changes**: Each schema version should be a small, incremental change
5. **Testing**: All migrations must be tested before deployment

## Schema Versioning

### Version 1 (Initial)
- Tables: Users, Vaults, MediaItems, Notes, Passwords, Contacts, IntruderLogs
- Encryption: SQLCipher with 256-bit key
- Indexes: Basic indexes on foreign keys and frequently queried columns

### Future Versions
- Each version adds new features or modifies existing schema
- Migration path: v1 → v2 → v3 → ...

## Migration Process

### Automatic Migration

When the app starts, it checks the database version and applies migrations automatically:

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      for (int version = from; version < to; version++) {
        await _performMigration(m, version, version + 1);
      }
    },
  );
}
```

### Manual Migration

For testing or emergency scenarios, migrations can be triggered manually:

```dart
Future<void> manualMigration(int targetVersion) async {
  final currentVersion = await database.schemaVersion;
  
  if (targetVersion < currentVersion) {
    throw ArgumentError('Cannot migrate to older version');
  }
  
  for (int version = currentVersion; version < targetVersion; version++) {
    await _performMigration(migrator, version, version + 1);
  }
}
```

## Migration Types

### Adding a New Column

```dart
case 2:
  // Add new column to existing table
  await m.addColumn(users, users.biometricEnabled);
  break;
```

### Adding a New Table

```dart
case 3:
  // Create new table
  await m.createTable(Settings);
  break;
```

### Modifying a Column

```dart
case 4:
  // Modify column (requires creating new column, copying data, dropping old)
  await m.addColumn(users, users.newPinHash);
  await customStatement('UPDATE users SET new_pin_hash = pin_hash');
  await m.deleteColumn(users.pinHash);
  await m.renameColumn(users, users.newPinHash, users.pinHash);
  break;
```

### Adding an Index

```dart
case 5:
  // Create index for performance
  await m.createIndex(Index('idx_media_items_type', 
    const [Reference('media_items', 'type')]));
  break;
```

### Dropping a Column

```dart
case 6:
  // Drop column (ensure data is no longer needed)
  await m.deleteColumn(users.oldColumn);
  break;
```

### Dropping a Table

```dart
case 7:
  // Drop table (ensure data is backed up or migrated)
  await m.deleteTable(OldTable);
  break;
```

## Encryption Key Migration

When the database encryption key needs to be rotated:

```dart
Future<void> rotateDatabaseKey() async {
  // 1. Generate new key
  final newKey = cryptoService.generateRandomKey(length: 32);
  
  // 2. Rekey database
  await database.rekeyDatabase(newKey);
  
  // 3. Update stored key
  await secureStorage.storeKey('db_encryption_key', newKey);
  
  // 4. Archive old key for rollback
  await secureStorage.storeKey('db_encryption_key_backup', oldKey);
  
  // 5. Schedule deletion of backup
  await scheduleBackupDeletion(days: 7);
}
```

## Testing Migrations

### Unit Tests

Test each migration step in isolation:

```dart
test('migration v1 to v2 adds biometricEnabled column', () async {
  final db = AppDatabase.inMemory(cryptoService, secureStorage);
  
  // Create v1 schema
  await db.customStatement('CREATE TABLE users (id INTEGER PRIMARY KEY, vault_id TEXT, pin_hash TEXT, pin_salt TEXT)');
  
  // Run migration
  await db.migrator.migrate(1, 2);
  
  // Verify column exists
  final columns = await db.customStatement('PRAGMA table_info(users)');
  expect(columns, contains('biometricEnabled'));
});
```

### Integration Tests

Test full migration flow:

```dart
test('migration from v1 to latest version', () async {
  final db = AppDatabase.inMemory(cryptoService, secureStorage);
  
  // Insert test data in v1 schema
  await db.users.insert(UsersCompanion(...));
  
  // Run migrations
  await db.migrator.migrate(1, latestVersion);
  
  // Verify data integrity
  final user = await db.users.get().then((list) => list.first);
  expect(user.pinHash, equals('expected_hash'));
});
```

### Rollback Tests

Test rollback scenarios:

```dart
test('migration rollback on failure', () async {
  final db = AppDatabase.inMemory(cryptoService, secureStorage);
  
  // Simulate migration failure
  await expectLater(
    () async => await db.migrator.migrate(1, 2),
    throwsException,
  );
  
  // Verify database is still in v1 state
  final version = await db.schemaVersion;
  expect(version, equals(1));
});
```

## Migration Checklist

Before deploying a migration:

- [ ] Migration code is written and tested
- [ ] Data integrity is verified
- [ ] Rollback strategy is documented
- [ ] Performance impact is assessed
- [ ] Migration is tested on all target platforms (Android, iOS)
- [ ] Backup strategy is in place
- [ ] User notification is planned (if migration takes time)
- [ ] Migration is tested with large datasets
- [ ] Encryption key rotation is tested (if applicable)

## Rollback Strategy

### Automatic Rollback

If migration fails:
1. Restore from backup
2. Log failure for investigation
3. Notify user (if applicable)
4. Schedule retry with exponential backoff

### Manual Rollback

If user reports issues:
1. Admin can trigger rollback via Remote Config
2. Restore from backup
3. Investigate failure cause
4. Fix issue before retry

## Performance Considerations

### Large Dataset Migrations

For large datasets (>10,000 rows):
- Use batch operations
- Show progress indicator to user
- Allow user to defer migration
- Consider incremental migration

### Background Migration

For non-critical migrations:
- Perform in background
- Allow user to continue using app
- Show completion notification

## Security Considerations

### Encryption During Migration

- Database remains encrypted during migration
- Encryption key is never exposed
- Temporary files are securely deleted

### Access Control

- Migrations require app restart
- Migrations are logged for audit
- Migrations cannot be triggered from outside app

## Remote Config Integration

Migration behavior can be controlled via Firebase Remote Config:

```json
{
  "migration_enabled": true,
  "migration_timeout_seconds": 300,
  "migration_show_progress": true,
  "migration_allow_defer": true
}
```

## Future Enhancements

- [ ] Incremental migration for large datasets
- [ ] Migration progress reporting
- [ ] Migration conflict resolution
- [ ] Cross-platform migration testing automation
- [ ] Migration performance benchmarking
