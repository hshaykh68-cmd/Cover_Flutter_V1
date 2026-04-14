import 'package:cover/data/local/database/app_database.dart';
import 'package:cover/data/local/database/daos/file_dao.dart';
import 'package:cover/domain/repository/file_repository.dart';
import 'package:cover/core/utils/logger.dart';

class FileRepositoryImpl implements FileRepository {
  final AppDatabase _database;
  late final FileDao _fileDao;

  FileRepositoryImpl(this._database) {
    _fileDao = FileDao(_database);
  }

  @override
  Future<FileItem?> getFileById(int id) async {
    try {
      return await _fileDao.getFileById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get file by ID', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<FileItem>> getFilesByVault(String vaultId) async {
    try {
      return await _fileDao.getFilesByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get files by vault', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<FileItem>> getFilesByFolder(String vaultId, String encryptedFolder) async {
    try {
      return await _fileDao.getFilesByFolder(vaultId, encryptedFolder);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get files by folder', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<FileItem>> getRootFiles(String vaultId) async {
    try {
      return await _fileDao.getRootFiles(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get root files', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<FileItem> createFile(FilesCompanion file) async {
    try {
      return await _fileDao.createFile(file);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create file', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> createFiles(List<FilesCompanion> files) async {
    try {
      await _fileDao.createFiles(files);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create files', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateFile(FileItem file) async {
    try {
      return await _fileDao.updateFile(file);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update file', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteFile(int id) async {
    try {
      return await _fileDao.deleteFile(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete file', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteFilesByVault(String vaultId) async {
    try {
      return await _fileDao.deleteFilesByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete files by vault', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteFilesByFolder(String vaultId, String encryptedFolder) async {
    try {
      return await _fileDao.deleteFilesByFolder(vaultId, encryptedFolder);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete files by folder', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getFileCount(String vaultId) async {
    try {
      return await _fileDao.getFileCount(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get file count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getFileCountByFolder(String vaultId, String encryptedFolder) async {
    try {
      return await _fileDao.getFileCountByFolder(vaultId, encryptedFolder);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get file count by folder', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<FileItem>> searchFiles(String vaultId, String query) async {
    try {
      return await _fileDao.searchFiles(vaultId, query);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search files', e, stackTrace);
      rethrow;
    }
  }
}
