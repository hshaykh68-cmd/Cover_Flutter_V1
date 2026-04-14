import 'package:cover/data/local/database/tables.dart';

abstract class VaultRepository {
  Future<Vault?> getVaultById(String id);
  Future<Vault?> getVaultByType(String type);
  Future<List<Vault>> getAllVaults();
  Future<List<Vault>> getActiveVaults();
  Future<Vault> createVault({required String type, String? name, required String encryptionKey});
  Future<bool> updateVault(Vault vault);
  Future<bool> updateVaultItemCount(String vaultId, int count);
  Future<int> deleteVault(String id);
  Future<int> getVaultCount();
  Future<bool> vaultExists(String id);
  Future<String?> getVaultEncryptionKey(String vaultId);
}
