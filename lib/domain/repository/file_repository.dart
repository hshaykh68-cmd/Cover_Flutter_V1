import 'package:cover/data/local/database/tables.dart';

abstract class FileRepository {
  Future<FileItem?> getFileById(int id);
  Future<List<FileItem>> getFilesByVault(String vaultId);
  Future<List<FileItem>> getFilesByFolder(String vaultId, String encryptedFolder);
  Future<List<FileItem>> getRootFiles(String vaultId);
  Future<FileItem> createFile(FilesCompanion file);
  Future<void> createFiles(List<FilesCompanion> files);
  Future<bool> updateFile(FileItem file);
  Future<int> deleteFile(int id);
  Future<int> deleteFilesByVault(String vaultId);
  Future<int> deleteFilesByFolder(String vaultId, String encryptedFolder);
  Future<int> getFileCount(String vaultId);
  Future<int> getFileCountByFolder(String vaultId, String encryptedFolder);
  Future<List<FileItem>> searchFiles(String vaultId, String query);
}
