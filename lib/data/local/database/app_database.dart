import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite_sqlcipher.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/data/local/database/tables.dart';

part 'app_database.g.dart';

/// Main database class for Cover app
/// 
/// Uses Drift ORM with SQLCipher for encrypted database storage
/// Database is encrypted with a key derived from the master key
@DriftDatabase(tables: [
  Users,
  Vaults,
  MediaItems,
  Notes,
  Passwords,
  Contacts,
  IntruderLogs,
])
class AppDatabase extends _$AppDatabase {
  final CryptoService _cryptoService;
  final SecureKeyStorage _secureStorage;

  AppDatabase(
    QueryExecutor e,
    this._cryptoService,
    this._secureStorage,
  ) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        AppLogger.info('Creating database schema v$schemaVersion');
        
        // Create all tables
        await m.createAll();
        
        // Create indexes for performance
        await m.createIndex(Index('idx_users_vault_id', const [Reference('users', 'vaultId')]));
        await m.createIndex(Index('idx_media_items_vault_id', const [Reference('media_items', 'vaultId')]));
        await m.createIndex(Index('idx_media_items_type', const [Reference('media_items', 'type')]));
        await m.createIndex(Index('idx_notes_vault_id', const [Reference('notes', 'vaultId')]));
        await m.createIndex(Index('idx_passwords_vault_id', const [Reference('passwords', 'vaultId')]));
        await m.createIndex(Index('idx_contacts_vault_id', const [Reference('contacts', 'vaultId')]));
        await m.createIndex(Index('idx_intruder_logs_timestamp', const [Reference('intruder_logs', 'timestamp')]));
        
        AppLogger.info('Database schema created successfully');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        AppLogger.info('Migrating database from v$from to v$to');
        
        // Handle migrations
        for (int version = from; version < to; version++) {
          await _performMigration(m, version, version + 1);
        }
        
        AppLogger.info('Database migration completed successfully');
      },
      beforeOpen: (OpeningDetails details) async {
        AppLogger.debug('Opening database (schema version: ${details.version})');
        
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
        
        // Enable WAL mode for better performance
        await customStatement('PRAGMA journal_mode = WAL');
        
        // Set cache size - adaptive based on device (8-16MB for vault app)
        await customStatement('PRAGMA cache_size = -8000'); // 8MB cache
      },
    );
  }

  /// Performs a specific migration step
  Future<void> _performMigration(Migrator m, int from, int to) async {
    switch (to) {
      case 2:
        // Future migration: Add new columns or tables
        break;
      default:
        AppLogger.warning('No migration defined for version $to');
    }
  }

  /// Gets or creates the database encryption key
  Future<Uint8List> _getDatabaseKey() async {
    // Check if key exists in secure storage
    final existingKey = await _secureStorage.retrieveKey('db_encryption_key');
    
    if (existingKey != null) {
      AppLogger.debug('Retrieved existing database encryption key');
      return existingKey;
    }
    
    // Generate new key
    AppLogger.info('Generating new database encryption key');
    final newKey = _cryptoService.generateRandomKey(length: 32);
    await _secureStorage.storeKey('db_encryption_key', newKey);
    
    return newKey;
  }

  /// Rekeys the database with a new encryption key
  /// 
  /// This is used during key rotation
  Future<void> rekeyDatabase(Uint8List newKey) async {
    AppLogger.info('Rekeying database with new encryption key');
    
    try {
      // SQLCipher rekey operation
      await customStatement('PRAGMA rekey = "x\'${newKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}\'"');
      
      // Update stored key
      await _secureStorage.storeKey('db_encryption_key', newKey);
      
      AppLogger.info('Database rekeyed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to rekey database', e, stackTrace);
      rethrow;
    }
  }

  /// Closes the database connection
  @override
  Future<void> close() async {
    AppLogger.info('Closing database connection');
    await super.close();
  }
}

/// Factory for creating AppDatabase instances
class AppDatabaseFactory {
  final CryptoService _cryptoService;
  final SecureKeyStorage _secureStorage;

  AppDatabaseFactory({
    required CryptoService cryptoService,
    required SecureKeyStorage secureStorage,
  })  : _cryptoService = cryptoService,
        _secureStorage = secureStorage;

  /// Creates an in-memory database for testing
  static AppDatabase inMemory(
    CryptoService cryptoService,
    SecureKeyStorage secureStorage,
  ) {
    return AppDatabase(
      LazyDatabase(() async {
        return NativeDatabase.createInBackground(
          Database.inMemoryDatabasePath(),
        );
      }),
      cryptoService,
      secureStorage,
    );
  }

  /// Creates a file-based database for production
  Future<AppDatabase> create() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cover.db'));

    AppLogger.info('Creating database at: ${file.path}');

    // Initialize SQLite3 Flutter Libs for SQLCipher
    if (Platform.isAndroid || Platform.isIOS) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      sqlite3FlutterLibsInit();
    }

    final dbKey = await _secureStorage.retrieveKey('db_encryption_key');
    if (dbKey == null) {
      final newKey = _cryptoService.generateRandomKey(length: 32);
      await _secureStorage.storeKey('db_encryption_key', newKey);
    }

    final executor = LazyDatabase(() async {
      return NativeDatabase.createInBackground(
        file,
        setup: (database) async {
          // Set encryption key
          final key = await _secureStorage.retrieveKey('db_encryption_key');
          final keyHex = key!.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          await database.execute('PRAGMA key = "x\'$keyHex\'"');
        },
      );
    });

    return AppDatabase(executor, _cryptoService, _secureStorage);
  }
}
