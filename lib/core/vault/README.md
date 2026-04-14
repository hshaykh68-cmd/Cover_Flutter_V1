# Vault Service

## Overview

The Vault Service provides namespace management and parity checks for real and decoy vaults. It ensures that decoy vaults maintain structural parity with real vaults while keeping their data completely separate.

## Components

### VaultService

Service for managing real and decoy vault namespaces.

**Key Features:**
- Vault namespace management (real/decoy)
- Vault existence checking
- Vault creation and deletion
- Parity checks between vaults
- Settings synchronization for parity
- Vault lifecycle management

## Vault Namespace

### VaultNamespace Enum

- `VaultNamespace.real` - The primary secure vault
- `VaultNamespace.decoy` - The decoy vault for plausible deniability

## Data Separation

Each vault maintains completely separate data:
- Separate vault IDs in the database
- Separate file storage directories
- Separate user records
- Separate media items, notes, passwords, etc.

The `type` field in the `Vaults` table distinguishes between 'real' and 'decoy' vaults.

## Parity Checks

Parity ensures that the decoy vault looks and behaves identically to the real vault from a user perspective, while keeping the actual content separate.

**Parity Checks:**
- Both vaults exist
- Vault types are correct ('real' and 'decoy')
- Settings structure matches
- UI layout matches (tabs enabled, etc.)

**Settings Sync:**
Syncs non-sensitive settings from real to decoy vault:
- Vault name
- Tab configuration
- Display settings
- (Does NOT sync actual content or PINs)

## Usage

### Getting Vault ID

```dart
final vaultService = ref.watch(vaultServiceProvider);
final vaultId = await vaultService.getVaultId(VaultNamespace.real);
```

### Checking Vault Existence

```dart
final vaultService = ref.watch(vaultServiceProvider);
final exists = await vaultService.vaultExists(VaultNamespace.decoy);
```

### Creating a Vault

```dart
final vaultService = ref.watch(vaultServiceProvider);
final vaultId = await vaultService.createVault(
  VaultNamespace.real,
  name: 'My Vault',
);
```

### Ensuring Vault Exists

```dart
final vaultService = ref.watch(vaultServiceProvider);
final vaultId = await vaultService.ensureVaultExists(
  VaultNamespace.decoy,
  name: 'Decoy Vault',
);
```

### Checking Parity

```dart
final vaultService = ref.watch(vaultServiceProvider);
final hasParity = await vaultService.checkVaultParity();

if (!hasParity) {
  await vaultService.syncVaultSettings();
}
```

### Syncing Settings

```dart
final vaultService = ref.watch(vaultServiceProvider);
await vaultService.syncVaultSettings();
```

### Deleting a Vault

```dart
final vaultService = ref.watch(vaultServiceProvider);
await vaultService.deleteVault(VaultNamespace.decoy);
```

## Security Properties

1. **Data Isolation**: Real and decoy vaults have completely separate data
2. **Structural Parity**: Decoy vault looks identical to real vault
3. **No Content Leak**: Settings sync does not include actual content
4. **Separate Storage**: Separate file storage directories per vault
5. **Database Separation**: Separate vault IDs and records

## Testing

Unit tests are located in `test/core/vault/vault_service_test.dart`.

**Test Coverage:**
- Vault ID retrieval
- Vault existence checking
- Vault creation
- Vault existence ensuring
- Parity checks
- Settings synchronization
- Vault deletion

## Dependencies

- `vault_repository` - For database operations on vaults
- Riverpod - For dependency injection

## DI Integration

The vault service is wired up in `lib/core/di/di_container.dart`:

```dart
@Riverpod(keepAlive: true)
VaultService vaultService(VaultServiceRef ref) {
  final vaultRepository = ref.watch(vaultRepositoryProvider);
  return VaultService(vaultRepository);
}
```

## Database Schema

The `Vaults` table supports both real and decoy vaults:

```dart
class Vaults extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get type => text()(); // 'real' or 'decoy'
  TextColumn get name => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

## File Storage

Files are organized by vault ID in the secure storage:

```
secure_storage/
├── {real_vault_id}/
│   ├── photos/
│   ├── videos/
│   └── documents/
└── {decoy_vault_id}/
    ├── photos/
    ├── videos/
    └── documents/
```

## Future Enhancements

- Advanced parity checks (UI state, tab configuration)
- Automatic parity enforcement
- Vault migration support
- Vault backup/restore
- Vault statistics
