import 'package:cover/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

part 'vault_dao.g.dart';

/// Data Access Object for Vault operations
@DriftAccessor(tables: [Vaults])
class VaultDao extends DatabaseAccessor<AppDatabase> with _$VaultDaoMixin {
  VaultDao(AppDatabase db) : super(db);

  /// Get a vault by ID
  Future<Vault?> getVaultById(String id) {
    return (select(vaults)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get vault by type (real or decoy)
  Future<Vault?> getVaultByType(String type) {
    return (select(vaults)
          ..where((tbl) => tbl.type.equals(type))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get all vaults
  Future<List<Vault>> getAllVaults() {
    return select(vaults).get();
  }

  /// Get active vaults
  Future<List<Vault>> getActiveVaults() {
    return (select(vaults)..where((tbl) => tbl.isActive.equals(true))).get();
  }

  /// Create a new vault
  Future<Vault> createVault(VaultsCompanion vault) async {
    return await into(vaults).insert(vault);
  }

  /// Update a vault
  Future<bool> updateVault(Vault vault) {
    return update(vaults).replace(vault);
  }

  /// Update vault item count
  Future<bool> updateVaultItemCount(String vaultId, int count) {
    return (update(vaults)..where((tbl) => tbl.id.equals(vaultId)))
        .write(VaultsCompanion(itemCount: Value(count)));
  }

  /// Delete a vault
  Future<int> deleteVault(String id) {
    return (delete(vaults)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Get vault count
  Future<int> getVaultCount() {
    return select(vaults).get().then((list) => list.length);
  }

  /// Check if vault exists
  Future<bool> vaultExists(String id) {
    return (select(vaults)..where((tbl) => tbl.id.equals(id))).get().then((list) => list.isNotEmpty);
  }
}
