# Cover - Project Metadata

## Project Information
- **Name**: Cover
- **Description**: Privacy vault app disguised as a calculator
- **Platform**: Flutter (Android & iOS)
- **Version**: 1.0.0
- **Phase**: 3 - Encrypted Database

## Architecture
- **Pattern**: Clean Architecture (MVVM)
- **State Management**: Riverpod
- **Navigation**: go_router
- **Database**: Drift + SQLCipher
- **DI**: Riverpod Providers

## Directory Structure
```
lib/
├── main.dart                    # App entry point
├── core/                        # Core utilities
│   ├── app/                     # App configuration
│   ├── constants/               # App constants
│   ├── crypto/                  # Cryptographic primitives (Phase 1)
│   │   ├── aes_gcm_cipher.dart  # AES-256-GCM encryption/decryption
│   │   ├── pbkdf2_key_deriver.dart # PBKDF2 key derivation
│   │   ├── crypto_service.dart  # Crypto service interface
│   │   ├── crypto_service_impl.dart # Crypto service implementation
│   │   ├── secure_key_storage.dart # Secure storage interface
│   │   ├── secure_key_storage_impl.dart # flutter_secure_storage implementation
│   │   └── KEY_ROTATION_STRATEGY.md # Key rotation documentation
│   ├── di/                      # Dependency injection
│   ├── theme/                   # App theming
│   └── utils/                   # Utility functions
├── data/                        # Data layer
│   ├── local/                   # Local database (Phase 3)
│   │   ├── database/            # Drift + SQLCipher database
│   │   │   ├── app_database.dart # Database configuration
│   │   │   ├── tables.dart      # Database entities
│   │   │   ├── MIGRATION_STRATEGY.md # Migration documentation
│   │   │   └── daos/            # Data access objects
│   │   │       ├── vault_dao.dart
│   │   │       ├── media_item_dao.dart
│   │   │       ├── note_dao.dart
│   │   │       ├── password_dao.dart
│   │   │       ├── contact_dao.dart
│   │   │       ├── intruder_log_dao.dart
│   │   │       └── user_dao.dart
│   └── repository/              # Repository implementations (Phase 3)
│       ├── vault_repository_impl.dart
│       ├── media_item_repository_impl.dart
│       ├── note_repository_impl.dart
│       ├── password_repository_impl.dart
│       ├── contact_repository_impl.dart
│       ├── intruder_log_repository_impl.dart
│       └── user_repository_impl.dart
├── domain/                      # Domain layer
│   ├── model/                   # Domain models
│   ├── repository/              # Repository interfaces (Phase 3)
│   │   ├── vault_repository.dart
│   │   ├── media_item_repository.dart
│   │   ├── note_repository.dart
│   │   ├── password_repository.dart
│   │   ├── contact_repository.dart
│   │   ├── intruder_log_repository.dart
│   │   └── user_repository.dart
│   └── usecase/                 # Use cases
└── presentation/                # Presentation layer
    ├── navigation/              # Navigation configuration
    └── screens/                 # UI screens
```

## CI/CD
- **Platform**: Codemagic
- **Config**: codemagic.yaml
- **Build Type**: Debug APK (Android), Debug App (iOS)

## Dependencies
See pubspec.yaml for complete dependency list.

## Phase 1 Implementation (Crypto Primitives)
- ✅ AES-256-GCM encryption/decryption utilities
- ✅ PBKDF2-SHA256 key derivation with configurable iterations
- ✅ Crypto service interface and implementation
- ✅ NIST/RFC test vectors for validation
- ✅ Comprehensive unit tests for all crypto primitives
- ✅ Dependency injection wiring for crypto service

## Phase 2 Implementation (Secure Key Storage)
- ✅ Secure key storage interface with platform-specific options
- ✅ flutter_secure_storage implementation (Android Keystore / iOS Keychain)
- ✅ Key rotation strategy documentation
- ✅ Dependency injection wiring for secure storage
- ✅ Comprehensive unit tests for secure storage operations

## Phase 3 Implementation (Encrypted Database)
- ✅ Drift + SQLCipher database configuration with encryption
- ✅ Database entities: Users, Vaults, MediaItems, Notes, Passwords, Contacts, IntruderLogs
- ✅ DAOs for all database operations
- ✅ Database migration strategy documentation
- ✅ Repository interfaces and implementations for clean architecture
- ✅ Dependency injection wiring for database, DAOs, and repositories
- ✅ Unit tests for database operations and repositories

## Phase 4 Implementation (Secure Storage Manager)
- ✅ Secure storage manager interface and implementation
- ✅ Integration with secure key storage
- ✅ Comprehensive unit tests for secure storage manager

## Phase 5 Implementation (Calculator UI MVP)
- ✅ Calculator UI implementation
- ✅ Basic arithmetic operations
- ✅ Comprehensive unit tests for calculator UI

## Phase 6 Implementation (PIN Pattern Detection)
- ✅ PIN pattern detection interface and implementation
- ✅ Integration with secure storage manager
- ✅ Comprehensive unit tests for PIN pattern detection

## Phase 7 Implementation (Decoy Vault Plumbing)
- ✅ Decoy vault plumbing interface and implementation
- ✅ Integration with encrypted database
- ✅ Comprehensive unit tests for decoy vault plumbing

## Phase 8 Implementation (Vault Shell + Bottom Nav)
- ✅ Vault shell interface and implementation
- ✅ Integration with encrypted database
- ✅ Comprehensive unit tests for vault shell

## Completed Phases
- Phase 0: Project Setup & CI
- Phase 1: Crypto Primitives
- Phase 2: Secure Key Storage
- Phase 3: Encrypted Database
- Phase 4: Secure Storage Manager
- Phase 5: Calculator UI MVP
- Phase 6: PIN Pattern Detection
- Phase 7: Decoy Vault Plumbing
- Phase 8: Vault Shell + Bottom Nav

## Next Phase
Proceed to Phase 9 - Remote Config Manager
## Next Steps
Proceed to Phase 4: PIN Setup & Validation
