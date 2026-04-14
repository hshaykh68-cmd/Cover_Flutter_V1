import 'package:cover/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

part 'user_dao.g.dart';

/// Data Access Object for User operations
@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  /// Get user by ID
  Future<User?> getUserById(int id) {
    return (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get user by vault ID
  Future<User?> getUserByVaultId(String vaultId) {
    return (select(users)..where((tbl) => tbl.vaultId.equals(vaultId))).getSingleOrNull();
  }

  /// Get all users
  Future<List<User>> getAllUsers() {
    return select(users).get();
  }

  /// Create a new user
  Future<User> createUser(UsersCompanion user) async {
    return await into(users).insert(user);
  }

  /// Update a user
  Future<bool> updateUser(User user) {
    return update(users).replace(user);
  }

  /// Update user PIN
  Future<bool> updateUserPin(int userId, String pinHash, String pinSalt) {
    return (update(users)..where((tbl) => tbl.id.equals(userId)))
        .write(UsersCompanion(pinHash: Value(pinHash), pinSalt: Value(pinSalt)));
  }

  /// Update user biometric setting
  Future<bool> updateUserBiometric(int userId, bool enabled) {
    return (update(users)..where((tbl) => tbl.id.equals(userId)))
        .write(UsersCompanion(biometricEnabled: Value(enabled)));
  }

  /// Update user auto-lock settings
  Future<bool> updateUserAutoLock(int userId, bool enabled, int timeout) {
    return (update(users)..where((tbl) => tbl.id.equals(userId)))
        .write(UsersCompanion(
          autoLockEnabled: Value(enabled),
          autoLockTimeout: Value(timeout),
        ));
  }

  /// Delete a user
  Future<int> deleteUser(int id) {
    return (delete(users)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete user by vault ID
  Future<int> deleteUserByVaultId(String vaultId) {
    return (delete(users)..where((tbl) => tbl.vaultId.equals(vaultId))).go();
  }

  /// Get user count
  Future<int> getUserCount() {
    return select(users).get().then((list) => list.length);
  }

  /// Check if user exists for vault
  Future<bool> userExistsForVault(String vaultId) {
    return (select(users)..where((tbl) => tbl.vaultId.equals(vaultId)))
        .get()
        .then((list) => list.isNotEmpty);
  }
}
