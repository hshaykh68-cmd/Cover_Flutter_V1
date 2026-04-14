import 'package:drift/drift.dart';

/// Users table
/// 
/// Stores user configuration and settings
@DataClassName('User')
class Users extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();
  
  /// Vault ID this user belongs to (for multi-vault support)
  TextColumn get vaultId => text().references(Vaults, #id)();
  
  /// User PIN hash (not the actual PIN)
  TextColumn get pinHash => text()();
  
  /// Salt used for PIN hashing
  TextColumn get pinSalt => text()();
  
  /// Whether biometric unlock is enabled
  BoolColumn get biometricEnabled => boolean().withDefault(const Constant(false))();
  
  /// Whether auto-lock is enabled
  BoolColumn get autoLockEnabled => boolean().withDefault(const Constant(true))();
  
  /// Auto-lock timeout in seconds
  IntColumn get autoLockTimeout => integer().withDefault(const Constant(30))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Vaults table
/// 
/// Stores vault information (real and decoy)
@DataClassName('Vault')
class Vaults extends Table {
  /// Primary key (UUID)
  TextColumn get id => text().withLength(min: 36, max: 36)();
  
  /// Vault type: 'real' or 'decoy'
  TextColumn get type => text()();
  
  /// Vault name (optional)
  TextColumn get name => text().nullable()();
  
  /// Whether this vault is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Number of items in vault
  IntColumn get itemCount => integer().withDefault(const Constant(0))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Media items table
/// 
/// Stores photos and videos
@DataClassName('MediaItem')
class MediaItems extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();
  
  /// Vault ID this item belongs to
  TextColumn get vaultId => text().references(Vaults, #id)();
  
  /// Media type: 'photo' or 'video'
  TextColumn get type => text()();
  
  /// Encrypted file path
  TextColumn get encryptedFilePath => text()();
  
  /// Encrypted thumbnail path
  TextColumn get encryptedThumbnailPath => text().nullable()();
  
  /// Original file name (encrypted)
  TextColumn get originalFileName => text()();
  
  /// File size in bytes
  IntColumn get fileSize => integer()();
  
  /// MIME type
  TextColumn get mimeType => text()();
  
  /// Width in pixels (for images/videos)
  IntColumn get width => integer().nullable()();
  
  /// Height in pixels (for images/videos)
  IntColumn get height => integer().nullable()();
  
  /// Duration in seconds (for videos)
  IntColumn get duration => integer().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Index for faster queries
  @override
  List<Set<Column>>? get uniqueKeys => [
        {vaultId, encryptedFilePath},
      ];
}

/// Notes table
/// 
/// Stores secure notes
@DataClassName('Note')
class Notes extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();
  
  /// Vault ID this note belongs to
  TextColumn get vaultId => text().references(Vaults, #id)();
  
  /// Encrypted note title
  TextColumn get encryptedTitle => text()();
  
  /// Encrypted note content
  TextColumn get encryptedContent => text()();
  
  /// Encrypted folder name (optional)
  TextColumn get encryptedFolder => text().nullable()();
  
  /// Encrypted tags (comma-separated)
  TextColumn get encryptedTags => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Passwords table
/// 
/// Stores password entries
@DataClassName('Password')
class Passwords extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();
  
  /// Vault ID this password belongs to
  TextColumn get vaultId => text().references(Vaults, #id)();
  
  /// Encrypted title
  TextColumn get encryptedTitle => text()();
  
  /// Encrypted username
  TextColumn get encryptedUsername => text()();
  
  /// Encrypted password
  TextColumn get encryptedPassword => text()();
  
  /// Encrypted URL
  TextColumn get encryptedUrl => text().nullable()();
  
  /// Encrypted notes
  TextColumn get encryptedNotes => text().nullable()();
  
  /// Encrypted folder name (optional)
  TextColumn get encryptedFolder => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Contacts table
/// 
/// Stores private contacts
@DataClassName('Contact')
class Contacts extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();
  
  /// Vault ID this contact belongs to
  TextColumn get vaultId => text().references(Vaults, #id)();
  
  /// Encrypted name
  TextColumn get encryptedName => text()();
  
  /// Encrypted phone number
  TextColumn get encryptedPhone => text()();
  
  /// Encrypted email
  TextColumn get encryptedEmail => text().nullable()();
  
  /// Encrypted address
  TextColumn get encryptedAddress => text().nullable()();
  
  /// Encrypted notes
  TextColumn get encryptedNotes => text().nullable()();
  
  /// Encrypted folder name (optional)
  TextColumn get encryptedFolder => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Files table
/// 
/// Stores imported files (documents, archives, etc.)
@DataClassName('FileItem')
class Files extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();
  
  /// Vault ID this file belongs to
  TextColumn get vaultId => text().references(Vaults, #id)();
  
  /// Encrypted file path
  TextColumn get encryptedFilePath => text()();
  
  /// Original file name (encrypted)
  TextColumn get originalFileName => text()();
  
  /// File size in bytes
  IntColumn get fileSize => integer()();
  
  /// MIME type
  TextColumn get mimeType => text()();
  
  /// Encrypted folder name (optional)
  TextColumn get encryptedFolder => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Index for faster queries
  @override
  List<Set<Column>>? get uniqueKeys => [
        {vaultId, encryptedFilePath},
      ];
}

/// Intruder logs table
/// 
/// Stores intruder detection events
@DataClassName('IntruderLog')
class IntruderLogs extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();
  
  /// Vault ID (null if attempt was on calculator)
  TextColumn get vaultId => text().references(Vaults, #id).nullable()();
  
  /// Timestamp of the event
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  
  /// Type of event: 'wrong_pin', 'screenshot', 'compromise_report'
  TextColumn get eventType => text()();
  
  /// Encrypted photo path (if captured)
  TextColumn get encryptedPhotoPath => text().nullable()();
  
  /// Encrypted location data (if captured)
  TextColumn get encryptedLocation => text().nullable()();
  
  /// Additional metadata (JSON string)
  TextColumn get metadata => text().nullable()();
  
  /// Index for faster queries
  @override
  List<Set<Column>>? get indexes => [
        {timestamp},
      ];
}
