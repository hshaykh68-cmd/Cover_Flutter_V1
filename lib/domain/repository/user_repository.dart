import 'package:cover/data/local/database/tables.dart';

abstract class UserRepository {
  Future<User?> getUserById(int id);
  Future<User?> getUserByVaultId(String vaultId);
  Future<List<User>> getAllUsers();
  Future<User> createUser(UsersCompanion user);
  Future<bool> updateUser(User user);
  Future<bool> updateUserPin(int userId, String pinHash, String pinSalt);
  Future<bool> updateUserBiometric(int userId, bool enabled);
  Future<bool> updateUserAutoLock(int userId, bool enabled, int timeout);
  Future<int> deleteUser(int id);
  Future<int> deleteUserByVaultId(String vaultId);
  Future<int> getUserCount();
  Future<bool> userExistsForVault(String vaultId);
}
