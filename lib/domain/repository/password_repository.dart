import 'package:cover/data/local/database/tables.dart';

abstract class PasswordRepository {
  Future<Password?> getPasswordById(int id);
  Future<List<Password>> getPasswordsByVault(String vaultId);
  Future<List<Password>> getPasswordsByFolder(String vaultId, String encryptedFolder);
  Future<Password> createPassword(PasswordsCompanion password);
  Future<bool> updatePassword(Password password);
  Future<int> deletePassword(int id);
  Future<int> deletePasswordsByVault(String vaultId);
  Future<int> getPasswordCount(String vaultId);
  Future<List<Password>> searchPasswords(String vaultId, String query);
}
