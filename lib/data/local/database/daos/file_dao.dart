import 'package:cover/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

part 'file_dao.g.dart';

/// Data Access Object for File operations
@DriftAccessor(tables: [Files])
class FileDao extends DatabaseAccessor<AppDatabase> with _$FileDaoMixin {
  FileDao(AppDatabase db) : super(db);

  /// Get a file by ID
  Future<FileItem?> getFileById(int id) {
    return (select(files)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get all files for a vault
  Future<List<FileItem>> getFilesByVault(String vaultId) {
    return (select(files)
          ..where((tbl) => tbl.vaultId.equals(vaultId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  /// Get files by folder
  Future<List<FileItem>> getFilesByFolder(String vaultId, String encryptedFolder) {
    return (select(files)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedFolder.equals(encryptedFolder))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  /// Get files without folder (root)
  Future<List<FileItem>> getRootFiles(String vaultId) {
    return (select(files)
          ..where((tbl) => tbl.vaultId.equals(vaultId) & tbl.encryptedFolder.isNull())
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  /// Create a new file
  Future<FileItem> createFile(FilesCompanion file) async {
    return await into(files).insert(file);
  }

  /// Create multiple files
  Future<void> createFiles(List<FilesCompanion> filesList) async {
    await batch((batch) {
      batch.insertAll(files, filesList);
    });
  }

  /// Update a file
  Future<bool> updateFile(FileItem file) {
    return update(files).replace(file);
  }

  /// Delete a file
  Future<int> deleteFile(int id) {
    return (delete(files)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete all files for a vault
  Future<int> deleteFilesByVault(String vaultId) {
    return (delete(files)..where((tbl) => tbl.vaultId.equals(vaultId))).go();
  }

  /// Delete files by folder
  Future<int> deleteFilesByFolder(String vaultId, String encryptedFolder) {
    return (delete(files)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedFolder.equals(encryptedFolder)))
        .go();
  }

  /// Get file count for a vault
  Future<int> getFileCount(String vaultId) {
    return (select(files)..where((tbl) => tbl.vaultId.equals(vaultId))).get().then((list) => list.length);
  }

  /// Get file count by folder
  Future<int> getFileCountByFolder(String vaultId, String encryptedFolder) {
    return (select(files)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedFolder.equals(encryptedFolder)))
        .get()
        .then((list) => list.length);
  }

  /// Search files by name
  Future<List<FileItem>> searchFiles(String vaultId, String query) {
    return (select(files)
          ..where((tbl) => tbl.vaultId.equals(vaultId) & tbl.originalFileName.contains(query))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }
}
