import 'package:cover/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

part 'password_dao.g.dart';

/// Data Access Object for Password operations
@DriftAccessor(tables: [Passwords])
class PasswordDao extends DatabaseAccessor<AppDatabase> with _$PasswordDaoMixin {
  PasswordDao(AppDatabase db) : super(db);

  /// Get password by ID
  Future<Password?> getPasswordById(int id) {
    return (select(passwords)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get all passwords for a vault
  Future<List<Password>> getPasswordsByVault(String vaultId) {
    return (select(passwords)..where((tbl) => tbl.vaultId.equals(vaultId))).get();
  }

  /// Get passwords by folder for a vault
  Future<List<Password>> getPasswordsByFolder(String vaultId, String encryptedFolder) {
    return (select(passwords)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedFolder.equals(encryptedFolder)))
        .get();
  }

  /// Create a new password
  Future<Password> createPassword(PasswordsCompanion password) async {
    return await into(passwords).insert(password);
  }

  /// Update a password
  Future<bool> updatePassword(Password password) {
    return update(passwords).replace(password);
  }

  /// Delete a password
  Future<int> deletePassword(int id) {
    return (delete(passwords)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete all passwords for a vault
  Future<int> deletePasswordsByVault(String vaultId) {
    return (delete(passwords)..where((tbl) => tbl.vaultId.equals(vaultId))).go();
  }

  /// Get password count for a vault
  Future<int> getPasswordCount(String vaultId) {
    return (select(passwords)..where((tbl) => tbl.vaultId.equals(vaultId)))
        .get()
        .then((list) => list.length);
  }

  /// Search passwords by encrypted title
  Future<List<Password>> searchPasswords(String vaultId, String query) {
    return (select(passwords)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedTitle.contains(query)))
        .get();
  }
}
