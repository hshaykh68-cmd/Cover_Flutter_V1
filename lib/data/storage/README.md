# Secure File Storage Manager

## Overview

The Secure File Storage Manager provides encrypted file storage capabilities for the Cover vault application. All files are encrypted using AES-256-GCM and stored with UUID-based naming to prevent filename exposure.

## Components

### SecureFileStorage (Interface)

Abstract interface defining the contract for secure file storage operations.

**Key Methods:**
- `storeFile()` - Encrypt and store file data with UUID naming
- `retrieveFile()` - Retrieve and decrypt file data by UUID
- `deleteFile()` - Delete a file by UUID
- `deleteVaultFiles()` - Delete all files for a vault
- `deleteVaultFilesByType()` - Delete files by type for a vault
- `getFileMetadata()` - Get encrypted file metadata
- `listVaultFiles()` - List all files for a vault
- `listVaultFilesByType()` - List files by type for a vault
- `getVaultStorageSize()` - Calculate total storage size for a vault
- `cleanupTempFiles()` - Clean up temporary files

### SecureFileStorageImpl (Implementation)

Concrete implementation using the CryptoService for encryption/decryption.

**Features:**
- AES-256-GCM encryption for all file data
- UUID v4 naming for files (no original filenames exposed)
- Organized directory layout: `/vault_id/type/`
- Encrypted metadata (original filename, type, subType, createdAt)
- Vault-based file organization for isolation
- Automatic directory creation

## Directory Layout

```
secure_storage/
├── {vault_id}/
│   ├── {type}/
│   │   ├── {uuid}.enc          # Encrypted file data
│   │   └── {uuid}.enc.meta     # Encrypted metadata
│   └── ...
└── temp/                       # Temporary files
```

**Supported Types:**
- `photo` - Images
- `video` - Videos
- `document` - Documents
- `audio` - Audio files
- `thumbnail` - Thumbnail previews

## Security Properties

1. **Encryption**: All file data encrypted with AES-256-GCM
2. **UUID Naming**: Files stored with UUID names, original filenames encrypted in metadata
3. **Vault Isolation**: Files organized by vault ID for separation
4. **Metadata Encryption**: Metadata (including original filename) encrypted
5. **Secure Storage**: Uses platform-specific secure storage for vault keys

## Usage

### Storing a File

```dart
final storage = ref.read(secureFileStorageProvider);
final fileData = await File('photo.jpg').readAsBytes();

final fileUuid = await storage.storeFile(
  vaultId: 'vault-123',
  type: 'photo',
  data: fileData,
  originalFileName: 'photo.jpg',
);
```

### Retrieving a File

```dart
final storage = ref.read(secureFileStorageProvider);
final decryptedData = await storage.retrieveFile(fileUuid);
```

### Listing Files

```dart
final storage = ref.read(secureFileStorageProvider);
final photos = await storage.listVaultFilesByType('vault-123', 'photo');
```

### Deleting Files

```dart
final storage = ref.read(secureFileStorageProvider);

// Delete single file
await storage.deleteFile(fileUuid);

// Delete all files for a vault
await storage.deleteVaultFiles('vault-123');

// Delete files by type
await storage.deleteVaultFilesByType('vault-123', 'photo');
```

## Testing

Unit tests are located in `test/data/storage/secure_file_storage_test.dart`.

**Test Coverage:**
- Store and retrieve files
- UUID naming validation
- File metadata operations
- Delete operations (single, by vault, by type)
- List operations (all files, by type)
- Storage size calculation
- Large file handling
- Error handling

## Dependencies

- `crypto_service` - For encryption/decryption operations
- `uuid` - For UUID v4 generation
- `path_provider` - For accessing app document directory
- `path` - For path manipulation

## DI Integration

The secure file storage is wired up in `lib/core/di/di_container.dart`:

```dart
@Riverpod(keepAlive: true)
SecureFileStorage secureFileStorage(SecureFileStorageRef ref) {
  final cryptoService = ref.watch(cryptoServiceProvider);
  return SecureFileStorageImpl(cryptoService);
}
```

## Future Enhancements

- Compression support for large files
- Chunked file operations for very large files
- File deduplication
- Thumbnail generation on store
- Background upload/download support
