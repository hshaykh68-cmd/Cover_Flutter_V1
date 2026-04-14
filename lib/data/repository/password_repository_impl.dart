import 'package:cover/data/local/database/daos/password_dao.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/password_repository.dart';
import 'package:cover/core/utils/logger.dart';

class PasswordRepositoryImpl implements PasswordRepository {
  final PasswordDao _passwordDao;

  PasswordRepositoryImpl(this._passwordDao);

  @override
  Future<Password?> getPasswordById(int id) async {
    try {
      return await _passwordDao.getPasswordById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get password by id: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Password>> getPasswordsByVault(String vaultId) async {
    try {
      return await _passwordDao.getPasswordsByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get passwords for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Password>> getPasswordsByFolder(String vaultId, String encryptedFolder) async {
    try {
      return await _passwordDao.getPasswordsByFolder(vaultId, encryptedFolder);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get passwords by folder', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Password> createPassword(PasswordsCompanion password) async {
    try {
      return await _passwordDao.createPassword(password);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create password', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updatePassword(Password password) async {
    try {
      return await _passwordDao.updatePassword(password);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update password', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deletePassword(int id) async {
    try {
      return await _passwordDao.deletePassword(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete password: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deletePasswordsByVault(String vaultId) async {
    try {
      return await _passwordDao.deletePasswordsByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete passwords for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getPasswordCount(String vaultId) async {
    try {
      return await _passwordDao.getPasswordCount(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get password count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Password>> searchPasswords(String vaultId, String query) async {
    try {
      return await _passwordDao.searchPasswords(vaultId, query);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search passwords', e, stackTrace);
      rethrow;
    }
  }
}
