import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/file_repository.dart';
import 'package:cover/domain/repository/vault_repository.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:path/path.dart' as p;

/// Result of file import
class FileImportResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final List<ImportedFileItem> importedFiles;

  FileImportResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
    required this.importedFiles,
  });
}

/// Imported file item
class ImportedFileItem {
  final int fileId;
  final String fileName;
  final int fileSize;
  final String mimeType;

  ImportedFileItem({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
  });
}

/// File import service interface
abstract class FileImportService {
  /// Import files from device using file picker
  Future<FileImportResult> importFiles({
    required String vaultId,
    String? encryptedFolder,
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  });

  /// Cancel ongoing import
  void cancelImport();
}

/// File import service implementation
class FileImportServiceImpl implements FileImportService {
  final SecureFileStorage _secureFileStorage;
  final FileRepository _fileRepository;
  final VaultRepository _vaultRepository;
  final AppConfig _appConfig;
  final FilePicker _filePicker = FilePicker.platform;
  
  bool _isImporting = false;
  bool _isCancelled = false;

  FileImportServiceImpl(
    this._secureFileStorage,
    this._fileRepository,
    this._vaultRepository,
    this._appConfig,
  );

  @override
  Future<FileImportResult> importFiles({
    required String vaultId,
    String? encryptedFolder,
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    if (_isImporting) {
      throw StateError('File import already in progress');
    }

    _isImporting = true;
    _isCancelled = false;

    try {
      // Verify vault exists
      final vault = await _vaultRepository.getVaultById(vaultId);
      if (vault == null) {
        return FileImportResult(
          successCount: 0,
          failureCount: 0,
          errors: ['Vault not found'],
          importedFiles: [],
        );
      }

      // Open file picker
      FilePickerResult? result;
      if (allowMultiple) {
        result = await _filePicker.pickFiles(
          type: allowedExtensions != null
              ? FileType.custom
              : FileType.any,
          allowMultiple: true,
          allowedExtensions: allowedExtensions,
        );
      } else {
        result = await _filePicker.pickFiles(
          type: allowedExtensions != null
              ? FileType.custom
              : FileType.any,
          allowMultiple: false,
          allowedExtensions: allowedExtensions,
        );
      }

      if (result == null || result.files.isEmpty) {
        return FileImportResult(
          successCount: 0,
          failureCount: 0,
          errors: [],
          importedFiles: [],
        );
      }

      // Process files
      final importedFiles = <ImportedFileItem>[];
      final errors = <String>[];
      int successCount = 0;
      int failureCount = 0;

      for (final file in result.files) {
        if (_isCancelled) {
          break;
        }

        try {
          if (file.path == null) {
            errors.add('${file.name}: Invalid file path');
            failureCount++;
            continue;
        }

          final fileData = await File(file.path!).readAsBytes();
          final importedItem = await _importFile(
            vaultId: vaultId,
            file: File(file.path!),
            fileName: file.name,
            encryptedFolder: encryptedFolder,
          );

          importedFiles.add(importedItem);
          successCount++;
        } catch (e, stackTrace) {
          AppLogger.error('Failed to import ${file.name}', e, stackTrace);
          errors.add('${file.name}: ${e.toString()}');
          failureCount++;
        }
      }

      // Update vault item count
      await _updateVaultItemCount(vaultId);

      return FileImportResult(
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
        importedFiles: importedFiles,
      );
    } catch (e, stackTrace) {
      AppLogger.error('File import failed', e, stackTrace);
      rethrow;
    } finally {
      _isImporting = false;
      _isCancelled = false;
    }
  }

  @override
  void cancelImport() {
    _isCancelled = true;
  }

  Future<ImportedFileItem> _importFile({
    required String vaultId,
    required File file,
    required String fileName,
    String? encryptedFolder,
  }) async {
    // Read file data
    final fileData = await file.readAsBytes();
    final fileSize = fileData.length;

    // Determine MIME type
    final mimeType = _getMimeType(fileName);

    // Store encrypted file
    final fileUuid = await _secureFileStorage.storeFile(
      vaultId: vaultId,
      type: 'file',
      data: fileData,
      originalFileName: fileName,
      subType: encryptedFolder,
    );

    // Create database record
    final fileItem = await _fileRepository.createFile(
      FilesCompanion(
        vaultId: Value(vaultId),
        encryptedFilePath: Value(fileUuid),
        originalFileName: Value(fileName),
        fileSize: Value(fileSize),
        mimeType: Value(mimeType),
        encryptedFolder: encryptedFolder != null ? Value(encryptedFolder) : const Value.absent(),
      ),
    );

    AppLogger.info('Imported file: $fileName (ID: ${fileItem.id})');

    return ImportedFileItem(
      fileId: fileItem.id,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );
  }

  Future<void> _updateVaultItemCount(String vaultId) async {
    try {
      final mediaCount = await _fileRepository.getFileCount(vaultId);
      await _vaultRepository.updateVaultItemCount(vaultId, mediaCount);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update vault item count', e, stackTrace);
    }
  }

  String _getMimeType(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    
    // Document MIME types
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';
      case '.odt':
        return 'application/vnd.oasis.opendocument.text';
      case '.ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case '.odp':
        return 'application/vnd.oasis.opendocument.presentation';
      
      // Archive MIME types
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/vnd.rar';
      case '.7z':
        return 'application/x-7z-compressed';
      case '.tar':
        return 'application/x-tar';
      case '.gz':
        return 'application/gzip';
      
      // Other common types
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';
      case '.csv':
        return 'text/csv';
      case '.md':
        return 'text/markdown';
      case '.html':
        return 'text/html';
      case '.css':
        return 'text/css';
      case '.js':
        return 'application/javascript';
      default:
        return 'application/octet-stream';
    }
  }
}
