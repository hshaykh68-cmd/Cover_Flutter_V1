import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/crypto/crypto_service_impl.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/secure_storage/secure_key_storage_impl.dart';
import 'package:cover/data/local/database/app_database.dart';
import 'package:cover/data/local/database/tables.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase database;
    late CryptoService cryptoService;
    late SecureKeyStorage secureStorage;

    setUp(() async {
      cryptoService = CryptoServiceImpl(
        pbkdf2Iterations: 1000, // Use lower iterations for tests
        keyLength: 32,
        saltLength: 16,
      );
      secureStorage = SecureKeyStorageImpl();
      database = AppDatabase.inMemory(cryptoService, secureStorage);
    });

    tearDown(() async {
      await database.close();
      await secureStorage.clearAll();
    });

    test('should create database schema', () async {
      // Verify database is created
      expect(database, isNotNull);
      expect(database.schemaVersion, equals(1));
    });

    test('should insert and retrieve vault', () async {
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
        name: const Value('Test Vault'),
      );

      await database.vaultDao.createVault(vault);
      final retrieved = await database.vaultDao.getVaultById('test-vault-id');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-vault-id'));
      expect(retrieved.type, equals('real'));
    });

    test('should insert and retrieve media item', () async {
      // First create a vault
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );
      await database.vaultDao.createVault(vault);

      // Then create a media item
      final mediaItem = MediaItemsCompanion.insert(
        vaultId: 'test-vault-id',
        type: 'photo',
        encryptedFilePath: '/encrypted/path/photo.jpg',
        originalFileName: 'photo.jpg',
        fileSize: 1024,
        mimeType: 'image/jpeg',
      );

      await database.mediaItemDao.createMediaItem(mediaItem);
      final retrieved = await database.mediaItemDao.getMediaItemById(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.type, equals('photo'));
      expect(retrieved.vaultId, equals('test-vault-id'));
    });

    test('should insert and retrieve note', () async {
      // First create a vault
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );
      await database.vaultDao.createVault(vault);

      // Then create a note
      final note = NotesCompanion.insert(
        vaultId: 'test-vault-id',
        encryptedTitle: 'encrypted_title',
        encryptedContent: 'encrypted_content',
      );

      await database.noteDao.createNote(note);
      final retrieved = await database.noteDao.getNoteById(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.encryptedTitle, equals('encrypted_title'));
    });

    test('should insert and retrieve password', () async {
      // First create a vault
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );
      await database.vaultDao.createVault(vault);

      // Then create a password
      final password = PasswordsCompanion.insert(
        vaultId: 'test-vault-id',
        encryptedTitle: 'encrypted_title',
        encryptedUsername: 'encrypted_user',
        encryptedPassword: 'encrypted_pass',
      );

      await database.passwordDao.createPassword(password);
      final retrieved = await database.passwordDao.getPasswordById(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.encryptedTitle, equals('encrypted_title'));
    });

    test('should insert and retrieve contact', () async {
      // First create a vault
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );
      await database.vaultDao.createVault(vault);

      // Then create a contact
      final contact = ContactsCompanion.insert(
        vaultId: 'test-vault-id',
        encryptedName: 'encrypted_name',
        encryptedPhone: 'encrypted_phone',
      );

      await database.contactDao.createContact(contact);
      final retrieved = await database.contactDao.getContactById(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.encryptedName, equals('encrypted_name'));
    });

    test('should insert and retrieve intruder log', () async {
      final intruderLog = IntruderLogsCompanion.insert(
        eventType: 'wrong_pin',
        vaultId: const Value('test-vault-id'),
      );

      await database.intruderLogDao.createIntruderLog(intruderLog);
      final retrieved = await database.intruderLogDao.getIntruderLogById(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.eventType, equals('wrong_pin'));
    });

    test('should insert and retrieve user', () async {
      // First create a vault
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );
      await database.vaultDao.createVault(vault);

      // Then create a user
      final user = UsersCompanion.insert(
        vaultId: 'test-vault-id',
        pinHash: 'test_hash',
        pinSalt: 'test_salt',
      );

      await database.userDao.createUser(user);
      final retrieved = await database.userDao.getUserById(1);

      expect(retrieved, isNotNull);
      expect(retrieved!.pinHash, equals('test_hash'));
    });

    test('should cascade delete vault', () async {
      // Create a vault
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );
      await database.vaultDao.createVault(vault);

      // Create a media item in the vault
      final mediaItem = MediaItemsCompanion.insert(
        vaultId: 'test-vault-id',
        type: 'photo',
        encryptedFilePath: '/encrypted/path/photo.jpg',
        originalFileName: 'photo.jpg',
        fileSize: 1024,
        mimeType: 'image/jpeg',
      );
      await database.mediaItemDao.createMediaItem(mediaItem);

      // Delete the vault
      await database.vaultDao.deleteVault('test-vault-id');

      // Verify vault is deleted
      final vaultExists = await database.vaultDao.vaultExists('test-vault-id');
      expect(vaultExists, isFalse);
    });

    test('should update vault item count', () async {
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );
      await database.vaultDao.createVault(vault);

      await database.vaultDao.updateVaultItemCount('test-vault-id', 5);
      final retrieved = await database.vaultDao.getVaultById('test-vault-id');

      expect(retrieved!.itemCount, equals(5));
    });
  });
}
