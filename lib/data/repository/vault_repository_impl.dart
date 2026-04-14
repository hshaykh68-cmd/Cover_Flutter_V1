import 'package:cover/data/local/database/daos/vault_dao.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/vault_repository.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/secure_storage/secure_key_storage_impl.dart';

class VaultRepositoryImpl implements VaultRepository {
  final VaultDao _vaultDao;

  VaultRepositoryImpl(this._vaultDao);

  @override
  Future<Vault?> getVaultById(String id) async {
    try {
      return await _vaultDao.getVaultById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get vault by id: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Vault?> getVaultByType(String type) async {
    try {
      return await _vaultDao.getVaultByType(type);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get vault by type: $type', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Vault>> getAllVaults() async {
    try {
      return await _vaultDao.getAllVaults();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all vaults', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Vault>> getActiveVaults() async {
    try {
      return await _vaultDao.getActiveVaults();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get active vaults', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Vault> createVault({required String type, String? name, required String encryptionKey}) async {
    try {
      // Create vault without encryptionKey in DB - it's stored in secure storage
      final vault = await _vaultDao.createVault(
        VaultsCompanion(
          type: Value(type),
          name: Value(name),
        ),
      );
      
      // Store encryption key in secure storage with key vault_enc_key_{vaultId}
      final secureStorage = SecureKeyStorageImpl();
      final keyBytes = encryptionKey.codeUnits; // Convert string to bytes
      await secureStorage.storeKey('vault_enc_key_${vault.id}', keyBytes);
      
      return vault;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create vault', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateVault(Vault vault) async {
    try {
      return await _vaultDao.updateVault(vault);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update vault', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateVaultItemCount(String vaultId, int count) async {
    try {
      return await _vaultDao.updateVaultItemCount(vaultId, count);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update vault item count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteVault(String id) async {
    try {
      return await _vaultDao.deleteVault(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete vault: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getVaultCount() async {
    try {
      return await _vaultDao.getVaultCount();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get vault count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> vaultExists(String id) async {
    try {
      return await _vaultDao.vaultExists(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check vault existence', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String?> getVaultEncryptionKey(String vaultId) async {
    try {
      // Retrieve encryption key from secure storage with key vault_enc_key_{vaultId}
      final secureStorage = SecureKeyStorageImpl();
      final keyBytes = await secureStorage.retrieveKey('vault_enc_key_$vaultId');
      if (keyBytes == null) {
        return null;
      }
      return String.fromCharCodes(keyBytes);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get vault encryption key', e, stackTrace);
      rethrow;
    }
  }
}
