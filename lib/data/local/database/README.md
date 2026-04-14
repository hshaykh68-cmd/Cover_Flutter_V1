# Encrypted Database Module

## Overview

This module provides an encrypted SQLite database using Drift ORM and SQLCipher for secure, on-device data storage.

## Components

### Database Configuration (`app_database.dart`)

**Purpose**: Main database class with SQLCipher encryption

**Features**:
- Drift ORM for type-safe database operations
- SQLCipher encryption with 256-bit key
- Automatic schema migrations
- WAL mode for better performance
- Foreign key constraints
- Optimized indexes

**Security Properties**:
- Database encrypted at rest with SQLCipher
- Encryption key stored in secure storage
- Key rotation support via rekey operation
- No plaintext data in database files

### Database Tables (`tables.dart`)

**Purpose**: Define database schema and entities

**Tables**:
1. **Users**: User configuration and PIN settings
2. **Vaults**: Real and decoy vault information
3. **MediaItems**: Photos and videos (encrypted file paths)
4. **Notes**: Secure notes (encrypted content)
5. **Passwords**: Password entries (encrypted credentials)
6. **Contacts**: Private contacts (encrypted data)
7. **IntruderLogs**: Intruder detection events

**Encryption Strategy**:
- All sensitive data is encrypted before storage
- File paths are encrypted to prevent file system inspection
- Content (notes, passwords, contacts) is encrypted
- Only metadata (IDs, timestamps) is stored in plaintext

### Data Access Objects (DAOs)

**Purpose**: Type-safe database operations for each table

**DAOs**:
- `VaultDao`: Vault operations
- `MediaItemDao`: Media item operations
- `NoteDao`: Note operations
- `PasswordDao`: Password operations
- `ContactDao`: Contact operations
- `IntruderLogDao`: Intruder log operations
- `UserDao`: User operations

**Features**:
- CRUD operations for each table
- Query by foreign key (vault ID)
- Search operations
- Date range queries
- Batch operations

### Migration Strategy (`MIGRATION_STRATEGY.md`)

**Purpose**: Defines database schema migration process

**Migration Types**:
- Adding new columns
- Adding new tables
- Modifying columns
- Adding indexes
- Dropping columns/tables

**Migration Process**:
1. Automatic migration on app startup
2. Incremental version updates (v1 → v2 → v3)
3. Data integrity verification
4. Rollback support on failure

**Encryption Key Migration**:
- Rekey operation for key rotation
- Archive old key for rollback
- Schedule deletion of backup

### Repository Layer

**Purpose**: Clean architecture separation between data and domain

**Repositories**:
- `VaultRepositoryImpl`: Vault data operations
- `MediaItemRepositoryImpl`: Media item data operations
- `NoteRepositoryImpl`: Note data operations
- `PasswordRepositoryImpl`: Password data operations
- `ContactRepositoryImpl`: Contact data operations
- `IntruderLogRepositoryImpl`: Intruder log data operations
- `UserRepositoryImpl`: User data operations

**Features**:
- Error handling with logging
- Type conversions
- Business logic encapsulation

## Database Schema

### Users Table
- `id`: Primary key
- `vaultId`: Foreign key to vaults
- `pinHash`: Hashed PIN (not plaintext)
- `pinSalt`: Salt for PIN hashing
- `biometricEnabled`: Biometric unlock setting
- `autoLockEnabled`: Auto-lock setting
- `autoLockTimeout`: Auto-lock timeout in seconds
- `createdAt`, `updatedAt`: Timestamps

### Vaults Table
- `id`: UUID primary key
- `type`: 'real' or 'decoy'
- `name`: Optional vault name
- `isActive`: Whether vault is active
- `itemCount`: Number of items in vault
- `createdAt`, `updatedAt`: Timestamps

### MediaItems Table
- `id`: Primary key
- `vaultId`: Foreign key to vaults
- `type`: 'photo' or 'video'
- `encryptedFilePath`: Encrypted file path
- `encryptedThumbnailPath`: Encrypted thumbnail path
- `originalFileName`: Encrypted original file name
- `fileSize`: File size in bytes
- `mimeType`: MIME type
- `width`, `height`: Dimensions (for images/videos)
- `duration`: Duration in seconds (for videos)
- `createdAt`, `updatedAt`: Timestamps

### Notes Table
- `id`: Primary key
- `vaultId`: Foreign key to vaults
- `encryptedTitle`: Encrypted note title
- `encryptedContent`: Encrypted note content
- `encryptedFolder`: Encrypted folder name (optional)
- `encryptedTags`: Encrypted tags (comma-separated)
- `createdAt`, `updatedAt`: Timestamps

### Passwords Table
- `id`: Primary key
- `vaultId`: Foreign key to vaults
- `encryptedTitle`: Encrypted title
- `encryptedUsername`: Encrypted username
- `encryptedPassword`: Encrypted password
- `encryptedUrl`: Encrypted URL (optional)
- `encryptedNotes`: Encrypted notes (optional)
- `encryptedFolder`: Encrypted folder name (optional)
- `createdAt`, `updatedAt`: Timestamps

### Contacts Table
- `id`: Primary key
- `vaultId`: Foreign key to vaults
- `encryptedName`: Encrypted name
- `encryptedPhone`: Encrypted phone number
- `encryptedEmail`: Encrypted email (optional)
- `encryptedAddress`: Encrypted address (optional)
- `encryptedNotes`: Encrypted notes (optional)
- `encryptedFolder`: Encrypted folder name (optional)
- `createdAt`, `updatedAt`: Timestamps

### IntruderLogs Table
- `id`: Primary key
- `vaultId`: Foreign key to vaults (null for calculator attempts)
- `timestamp`: Event timestamp
- `eventType`: 'wrong_pin', 'screenshot', 'compromise_report'
- `encryptedPhotoPath`: Encrypted photo path (if captured)
- `encryptedLocation`: Encrypted location data (if captured)
- `metadata`: Additional metadata (JSON string)

## Usage Example

```dart
// Get database instance
final database = ref.watch(appDatabaseProvider);

// Create a vault
final vault = VaultsCompanion.insert(
  id: 'vault-id',
  type: 'real',
  name: const Value('My Vault'),
);
await database.vaultDao.createVault(vault);

// Create a media item
final mediaItem = MediaItemsCompanion.insert(
  vaultId: 'vault-id',
  type: 'photo',
  encryptedFilePath: encryptedPath,
  originalFileName: encryptedName,
  fileSize: 1024,
  mimeType: 'image/jpeg',
);
await database.mediaItemDao.createMediaItem(mediaItem);

// Query items
final items = await database.mediaItemDao.getMediaItemsByVault('vault-id');
```

## Security Considerations

### Encryption
- Database encrypted with 256-bit key via SQLCipher
- Encryption key stored in platform secure storage
- Key rotation supported via rekey operation
- No plaintext sensitive data in database

### Data Integrity
- Foreign key constraints ensure referential integrity
- Transactions ensure atomic operations
- Unique constraints prevent duplicates

### Access Control
- Database file accessible only to this app
- Encryption prevents external inspection
- App-level permissions control access

## Performance

### Optimization
- WAL mode for concurrent reads/writes
- Indexed foreign keys for faster joins
- Batch operations for bulk inserts
- Lazy loading with Drift streams

### Benchmarks
- Insert operations: ~1-5ms per row
- Query operations: ~1-10ms (with indexes)
- Migration: Depends on data size

## Testing

Run the database tests:
```bash
flutter test test/data/local/database/
flutter test test/data/repository/
```

Test coverage includes:
- ✅ Database schema creation
- ✅ CRUD operations for all tables
- ✅ Foreign key constraints
- ✅ Query operations
- ✅ Repository error handling
- ✅ Cascade deletes

## Dependencies

- `drift`: Type-safe SQL database for Dart/Flutter
- `sqlite3_flutter_libs`: SQLite bindings for Flutter
- `sqflite_sqlcipher`: SQLCipher support
- `path_provider`: File system access
- `path`: Path manipulation

## Future Enhancements

- [ ] Full-text search for notes
- [ ] Database backup/restore
- [ ] Incremental migration for large datasets
- [ ] Query optimization with EXPLAIN
- [ ] Database compression
- [ ] Sync support (if needed)
