import 'package:cover/data/local/database/daos/user_dao.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/user_repository.dart';
import 'package:cover/core/utils/logger.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDao _userDao;

  UserRepositoryImpl(this._userDao);

  @override
  Future<User?> getUserById(int id) async {
    try {
      return await _userDao.getUserById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user by id: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<User?> getUserByVaultId(String vaultId) async {
    try {
      return await _userDao.getUserByVaultId(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user by vault id: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      return await _userDao.getAllUsers();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all users', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<User> createUser(UsersCompanion user) async {
    try {
      return await _userDao.createUser(user);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create user', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateUser(User user) async {
    try {
      return await _userDao.updateUser(user);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateUserPin(int userId, String pinHash, String pinSalt) async {
    try {
      return await _userDao.updateUserPin(userId, pinHash, pinSalt);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user PIN', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateUserBiometric(int userId, bool enabled) async {
    try {
      return await _userDao.updateUserBiometric(userId, enabled);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user biometric setting', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateUserAutoLock(int userId, bool enabled, int timeout) async {
    try {
      return await _userDao.updateUserAutoLock(userId, enabled, timeout);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user auto-lock settings', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteUser(int id) async {
    try {
      return await _userDao.deleteUser(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete user: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteUserByVaultId(String vaultId) async {
    try {
      return await _userDao.deleteUserByVaultId(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete user by vault id: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getUserCount() async {
    try {
      return await _userDao.getUserCount();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> userExistsForVault(String vaultId) async {
    try {
      return await _userDao.userExistsForVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check user existence for vault', e, stackTrace);
      rethrow;
    }
  }
}
