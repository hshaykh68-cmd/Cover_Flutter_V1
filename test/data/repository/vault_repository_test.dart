import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/crypto/crypto_service_impl.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/secure_storage/secure_key_storage_impl.dart';
import 'package:cover/data/local/database/app_database.dart';
import 'package:cover/data/local/database/daos/vault_dao.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/data/repository/vault_repository_impl.dart';

void main() {
  group('VaultRepositoryImpl', () {
    late VaultRepositoryImpl repository;
    late AppDatabase database;

    setUp(() async {
      final cryptoService = CryptoServiceImpl(
        pbkdf2Iterations: 1000,
        keyLength: 32,
        saltLength: 16,
      );
      final secureStorage = SecureKeyStorageImpl();
      database = AppDatabase.inMemory(cryptoService, secureStorage);
      final dao = VaultDao(database);
      repository = VaultRepositoryImpl(dao);
    });

    tearDown(() async {
      await database.close();
    });

    test('should create and retrieve vault', () async {
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
        name: const Value('Test Vault'),
      );

      await repository.createVault(vault);
      final retrieved = await repository.getVaultById('test-vault-id');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-vault-id'));
      expect(retrieved.type, equals('real'));
    });

    test('should get vault by type', () async {
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );

      await repository.createVault(vault);
      final retrieved = await repository.getVaultByType('real');

      expect(retrieved, isNotNull);
      expect(retrieved!.type, equals('real'));
    });

    test('should get all vaults', () async {
      await repository.createVault(VaultsCompanion.insert(id: 'vault1', type: 'real'));
      await repository.createVault(VaultsCompanion.insert(id: 'vault2', type: 'decoy'));

      final vaults = await repository.getAllVaults();

      expect(vaults.length, equals(2));
    });

    test('should update vault', () async {
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );

      final created = await repository.createVault(vault);
      final updated = created.copyWith(name: 'Updated Vault');

      await repository.updateVault(updated);
      final retrieved = await repository.getVaultById('test-vault-id');

      expect(retrieved!.name, equals('Updated Vault'));
    });

    test('should delete vault', () async {
      final vault = VaultsCompanion.insert(
        id: 'test-vault-id',
        type: 'real',
      );

      await repository.createVault(vault);
      await repository.deleteVault('test-vault-id');

      final exists = await repository.vaultExists('test-vault-id');
      expect(exists, isFalse);
    });

    test('should check vault existence', () async {
      final existsBefore = await repository.vaultExists('test-vault-id');
      expect(existsBefore, isFalse);

      await repository.createVault(VaultsCompanion.insert(id: 'test-vault-id', type: 'real'));

      final existsAfter = await repository.vaultExists('test-vault-id');
      expect(existsAfter, isTrue);
    });
  });
}
