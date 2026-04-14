# Cover - Privacy Vault App

> A privacy vault app that disguises itself as a calculator with on-device encryption, decoy vaults, and intruder defense.

## 🎯 Overview

Cover is a privacy-first mobile application designed to protect sensitive content through:
- **Calculator Camouflage**: Disguises as a fully functional calculator
- **On-Device Encryption**: AES-256-GCM encryption with no cloud storage
- **Decoy Vaults**: Separate vault for plausible deniability
- **Intruder Defense**: Automatic capture of unauthorized access attempts
- **Remote Config**: Firebase Remote Config for feature control

## 🏗️ Architecture

Cover follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                   │
│              (UI Screens, ViewModels, Navigation)       │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                      Domain Layer                        │
│           (Business Logic, Use Cases, Models)           │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                       Data Layer                         │
│      (Repositories, Database, API, Storage Managers)     │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                        Core Layer                        │
│          (Utilities, Constants, DI, Theme)              │
└─────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

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
│   │   └── crypto_service_impl.dart # Crypto service implementation
│   ├── secure_storage/          # Secure key storage (Phase 2)
│   │   ├── secure_key_storage.dart # Secure storage interface
│   │   ├── secure_key_storage_impl.dart # flutter_secure_storage implementation
│   │   └── KEY_ROTATION_STRATEGY.md # Key rotation documentation
│   ├── pin/                     # PIN pattern detection (Phase 6)
│   │   ├── pin_pattern_detector.dart # Pattern parser
│   │   ├── pin_lockout_manager.dart # Lockout behavior
│   │   └── pin_state_machine.dart # State machine
│   ├── vault/                   # Vault management (Phase 7)
│   │   └── vault_service.dart # Decoy vault plumbing
│   ├── di/                      # Dependency injection
│   ├── theme/                   # App theming (Apple-inspired)
│   └── utils/                   # Utility functions (Logger, etc.)
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
│   ├── storage/                 # Secure file storage (Phase 4)
│   │   └── secure_file_storage.dart # Encrypted file storage manager
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
    ├── navigation/              # Navigation configuration (go_router)
    └── screens/                 # UI screens
        ├── calculator/          # Calculator screen (Phase 5)
        │   ├── calculator_screen.dart
        │   └── calculator_controller.dart
        └── vault/               # Vault screens (Phase 8)
            ├── vault_shell_screen.dart # Vault shell with bottom nav
            └── tabs/            # Vault tabs
                ├── gallery_tab.dart
                ├── files_tab.dart
                ├── notes_tab.dart
                └── settings_tab.dart
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.19+ / Dart 3.3+
- **State Management**: Riverpod 2.4+
- **Navigation**: go_router 13.0+
- **Database**: Drift 2.14+ with SQLCipher
- **Cryptography**: encrypt 5.0+, cryptography 2.7+
- **Secure Storage**: flutter_secure_storage 9.0+
- **Firebase**: Remote Config, Analytics, Crashlytics, Performance
- **Monetization**: in_app_purchase, google_mobile_ads
- **Media**: photo_manager, file_picker, camera, image_picker
- **Location**: geolocator
- **Permissions**: permission_handler
- **Sensors**: sensors_plus

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.19 or higher
- Dart 3.3 or higher
- Android Studio / Xcode (for platform-specific builds)
- Firebase account (for Remote Config and Analytics)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Cover__V1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure local Flutter SDK**
   ```bash
   cp local.properties.example local.properties
   # Edit local.properties and set flutter.sdk path
   ```

4. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Development

### Code Generation

This project uses code generation for:
- Riverpod providers
- Drift database
- Freezed models
- JSON serialization

Run code generation after making changes:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Linting

The project uses strict linting rules. Run analysis:
```bash
flutter analyze
```

### Testing

Run unit tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test/
```

## 📦 Build & Deploy

### Codemagic CI/CD

This project uses Codemagic for CI/CD. Configuration is in `codemagic.yaml`.

**Debug Pipeline** (Phase 0):
- Runs on push to `main` or `develop` branches
- Runs tests and code analysis
- Builds debug APK (Android)
- Builds debug app (iOS) on macOS

**No local builds are permitted** - all builds must go through Codemagic.

### Manual Build (if needed)

**Android Debug APK:**
```bash
cd android
./gradlew assembleDebug
```

**iOS Debug:**
```bash
cd ios
pod install
flutter build ios --debug --no-codesign
```

## 📋 Phase Progress

This project follows a 27-phase delivery roadmap:

- ✅ **Phase 0**: Project Setup & CI
- ✅ **Phase 1**: Crypto Primitives
- ✅ **Phase 2**: Secure Key Storage
- ✅ **Phase 3**: Encrypted Database
- ✅ **Phase 4**: Secure Storage Manager
- ✅ **Phase 5**: Calculator UI MVP
- ✅ **Phase 6**: PIN Pattern Detection
- ✅ **Phase 7**: Decoy Vault Plumbing
- ✅ **Phase 8**: Vault Shell + Bottom Nav
- ⏳ **Phase 9**: Remote Config Manager
- ... (18 more phases)

See [PRD_FINAL.md](./PRD_FINAL.md) for complete roadmap.

## 🔐 Security Principles

1. **On-device only privacy**: No cloud backup, no accounts, no server-side storage
2. **Security-first defaults**: Lock-on-background, least-privilege permissions
3. **Remote Config first**: User-facing limits controlled via Firebase Remote Config
4. **Decoy parity**: Decoy vault must look/behave identical to real vault
5. **Performance**: Smooth 60-120fps interactions

### Phase 1 Summary (Crypto Primitives)

Implemented industry-standard cryptographic primitives:

- **AES-256-GCM**: Authenticated encryption with confidentiality and integrity
- **PBKDF2-SHA256**: Key derivation from passwords/PINs with 100,000 iterations
- **Crypto Service**: Unified interface for all cryptographic operations
- **Test Vectors**: NIST/RFC standards validation
- **Comprehensive Tests**: Unit tests covering all crypto primitives
- **DI Integration**: Crypto service wired up in Riverpod provider

See [lib/core/crypto/README.md](./lib/core/crypto/README.md) for detailed documentation.

### Phase 2 Summary (Secure Key Storage)

Implemented platform-specific secure key storage:

- **Secure Key Storage Interface**: Abstract interface for key storage operations
- **flutter_secure_storage Implementation**: Android Keystore / iOS Keychain integration
- **Key Rotation Strategy**: Comprehensive documentation for key rotation (time-based, version-based, compromise-based)
- **Storage Options**: Configurable accessibility levels and biometric requirements
- **Comprehensive Tests**: Unit tests covering all storage operations
- **DI Integration**: Secure storage wired up in Riverpod provider

See [lib/core/secure_storage/README.md](./lib/core/secure_storage/README.md) for detailed documentation.

### Phase 3 Summary (Encrypted Database)

Implemented encrypted database with Drift + SQLCipher:

- **Database Configuration**: Drift ORM with SQLCipher encryption (256-bit key)
- **Database Entities**: Users, Vaults, MediaItems, Notes, Passwords, Contacts, IntruderLogs
- **Data Access Objects (DAOs)**: Type-safe database operations for each table
- **Migration Strategy**: Comprehensive documentation for schema migrations
- **Repository Layer**: Clean architecture with repository interfaces and implementations
- **Comprehensive Tests**: Unit tests for database operations and repositories
- **DI Integration**: Database, DAOs, and repositories wired up in Riverpod

See [lib/data/local/database/README.md](./lib/data/local/database/README.md) for detailed documentation.

### Phase 4 Summary (Secure Storage Manager)

Implemented secure file storage manager with encrypted file operations:

- **Secure File Storage Interface**: Abstract interface for encrypted file storage operations
- **Encrypted File Read/Write APIs**: AES-256-GCM encryption for all file data
- **UUID Naming**: Files stored with UUID names, no original filenames exposed
- **Directory Layout**: Organized by vault_id/type/ (e.g., /vault_id/photos/, /vault_id/videos/)
- **File Metadata**: Encrypted metadata including original filename, type, subType, createdAt
- **Vault Organization**: Files organized by vault for isolation
- **Comprehensive Tests**: Unit tests covering all storage operations
- **DI Integration**: Secure file storage wired up in Riverpod provider

See [lib/data/storage/secure_file_storage.dart](./lib/data/storage/secure_file_storage.dart) for implementation.

### Phase 5 Summary (Calculator UI MVP)

Implemented iOS-style calculator UI with full functionality:

- **Calculator Screen**: Full iOS calculator UI with proper button layout
- **Calculator Controller**: State management with Riverpod StateNotifier
- **Core Operations**: Addition, subtraction, multiplication, division, percentage, sign toggle
- **iOS-Style Rendering**: iOS color scheme, button shapes, and typography
- **Haptic Feedback**: Light haptic feedback on button presses
- **Animations**: Scale animation on button press (150ms)
- **Display Logic**: Dynamic font sizing, previous calculation display
- **Error Handling**: Division by zero error handling
- **Comprehensive Tests**: Unit tests covering all calculator operations
- **Navigation**: Wired up in go_router as initial route

See [lib/presentation/screens/calculator/](./lib/presentation/screens/calculator/) for implementation.

### Phase 6 Summary (PIN Pattern Detection)

Implemented PIN pattern detection with state machine and lockout behavior:

- **PIN Pattern Parser**: Detects PIN patterns in calculator display (e.g., `{pin}+0=` for real vault, `{pin}+1=` for decoy vault)
- **PIN State Machine**: Tracks PIN entry state and pattern matching
- **Lockout Manager**: Handles failed attempts and lockout periods (configurable duration)
- **Pattern Matching**: Configurable patterns via Remote Config support
- **PIN Validation**: Validates PIN length (4-12 digits, configurable)
- **Lockout Behavior**: Auto-lock after max attempts (default: 3, configurable)
- **Calculator Integration**: Integrated PIN detection into calculator screen
- **Comprehensive Tests**: Unit tests for pattern detection, lockout, and state machine
- **DI Integration**: PIN state machine wired up in Riverpod provider

See [lib/core/pin/](./lib/core/pin/) for implementation.

### Phase 7 Summary (Decoy Vault Plumbing)

Implemented decoy vault namespace and data separation:

- **Vault Service**: Service for managing real and decoy vault namespaces
- **Vault Namespace**: Separate namespace for real and decoy vaults
- **Data Separation**: Vault-specific data isolation at repository level
- **Parity Checks**: Ensures decoy vault structure matches real vault
- **Settings Sync**: Syncs settings from real to decoy vault for parity
- **Vault Lifecycle**: Create, delete, and ensure vaults exist
- **Database Support**: Vaults table already supports type field ('real'/'decoy')
- **Comprehensive Tests**: Unit tests for vault service operations
- **DI Integration**: Vault service wired up in Riverpod provider

See [lib/core/vault/](./lib/core/vault/) for implementation.

### Phase 8 Summary (Vault Shell + Bottom Nav)

Implemented vault shell with custom bottom navigation and tabs:

- **VaultShellScreen**: Scaffold with custom bottom navigation bar
- **Custom Bottom Navigation**: Apple-style bottom nav with sliding pill indicator
- **4 Tabs**: Gallery, Files, Notes, Settings (RC-gated)
- **State Preservation**: AutomaticKeepAliveClientMixin for tab state preservation
- **Shared Axis Transitions**: PageView with 250ms animation and easeOut curve
- **Sliding Pill Indicator**: AnimatedPositioned with spring physics
- **Haptic Feedback**: Medium impact haptic on tab selection
- **Back Button Behavior**: First back returns to calculator, second back minimizes app
- **Vault Type Parameter**: Passes vault type from calculator to vault screen
- **Safe Area Support**: Respects notch/dynamic island on all devices
- **Dark Theme**: OLED black background verified

See [lib/presentation/screens/vault/](./lib/presentation/screens/vault/) for implementation.

## 📱 Platform Support

- **Android**: Primary platform (SDK 26-34)
- **iOS**: Fully supported (iOS 13+)

## 🎨 Design Philosophy

The app's design follows Apple-level standards:
- Calm, minimal, fluid, and fast
- Glassmorphic UI elements
- Smooth animations and haptics
- Accessibility-first approach

## 📄 License

Proprietary - All rights reserved

## 🤝 Contributing

This is a private project. No external contributions are accepted.

## 📞 Support

For internal support, contact the development team.

---

**Note**: This is Phase 3 of the project. The app is in development stage.
