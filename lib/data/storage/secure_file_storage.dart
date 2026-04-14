import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/domain/repository/vault_repository.dart';
import 'package:cover/core/utils/logger.dart';

/// Secure file storage manager interface
/// 
/// Handles encrypted file storage with UUID naming and organized directory layout
abstract class SecureFileStorage {
  /// Store encrypted file data
  /// 
  /// Parameters:
  /// - [vaultId]: The vault ID for organization
  /// - [type]: File type (photo, video, document, etc.)
  /// - [data]: The file data to encrypt and store
  /// - [originalFileName]: The original filename (will be encrypted)
  /// 
  /// Returns the UUID of the stored file
  Future<String> storeFile({
    required String vaultId,
    required String type,
    required Uint8List data,
    required String originalFileName,
    String? subType,
  });

  /// Retrieve and decrypt file data
  /// 
  /// Parameters:
  /// - [fileUuid]: The UUID of the file to retrieve
  /// 
  /// Returns the decrypted file data
  Future<Uint8List?> retrieveFile(String fileUuid);

  /// Delete a file
  /// 
  /// Parameters:
  /// - [fileUuid]: The UUID of the file to delete
  Future<void> deleteFile(String fileUuid);

  /// Delete all files for a vault
  /// 
  /// Parameters:
  /// - [vaultId]: The vault ID
  Future<void> deleteVaultFiles(String vaultId);

  /// Delete all files of a specific type for a vault
  /// 
  /// Parameters:
  /// - [vaultId]: The vault ID
  /// - [type]: The file type
  Future<void> deleteVaultFilesByType(String vaultId, String type);

  /// Get file metadata
  /// 
  /// Parameters:
  /// - [fileUuid]: The UUID of the file
  /// 
  /// Returns file metadata (path, size, encrypted filename)
  Future<FileMetadata?> getFileMetadata(String fileUuid);

  /// List all files for a vault
  /// 
  /// Parameters:
  /// - [vaultId]: The vault ID
  /// 
  /// Returns list of file metadata
  Future<List<FileMetadata>> listVaultFiles(String vaultId);

  /// List files by type for a vault
  /// 
  /// Parameters:
  /// - [vaultId]: The vault ID
  /// - [type]: The file type
  /// 
  /// Returns list of file metadata
  Future<List<FileMetadata>> listVaultFilesByType(String vaultId, String type);

  /// Get total storage size for a vault
  /// 
  /// Parameters:
  /// - [vaultId]: The vault ID
  /// 
  /// Returns total size in bytes
  Future<int> getVaultStorageSize(String vaultId);

  /// Clean up temporary files
  Future<void> cleanupTempFiles();
}

/// File metadata
class FileMetadata {
  final String uuid;
  final String vaultId;
  final String type;
  final String? subType;
  final String encryptedPath;
  final int size;
  final String encryptedFileName;
  final DateTime createdAt;

  FileMetadata({
    required this.uuid,
    required this.vaultId,
    required this.type,
    this.subType,
    required this.encryptedPath,
    required this.size,
    required this.encryptedFileName,
    required this.createdAt,
  });
}

/// Secure file storage implementation
class SecureFileStorageImpl implements SecureFileStorage {
  final CryptoService _cryptoService;
  final VaultRepository _vaultRepository;
  final SecureKeyStorage _secureKeyStorage;
  final Uuid _uuid = const Uuid();
  late final Directory _appDirectory;
  final Map<String, String> _uuidPathCache = {};

  SecureFileStorageImpl(this._cryptoService, this._vaultRepository, this._secureKeyStorage) {
    _initializeDirectory();
  }

  Future<void> _initializeDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _appDirectory = Directory(p.join(appDocDir.path, 'secure_storage'));
    
    if (!await _appDirectory.exists()) {
      await _appDirectory.create(recursive: true);
    }
    
    AppLogger.debug('Secure storage directory: ${_appDirectory.path}');
  }

  @override
  Future<String> storeFile({
    required String vaultId,
    required String type,
    required Uint8List data,
    required String originalFileName,
    String? subType,
  }) async {
    try {
      // Generate UUID for the file
      final fileUuid = _uuid.v4();
      
      // Create directory structure: /vault_id/type/
      final vaultDir = Directory(p.join(_appDirectory.path, vaultId));
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }
      
      final typeDir = Directory(p.join(vaultDir.path, type));
      if (!await typeDir.exists()) {
        await typeDir.create(recursive: true);
      }
      
      // Encrypt the file data
      final encryptionKey = await _getVaultEncryptionKey(vaultId);
      final encryptedData = await _cryptoService.encryptBytes(data, encryptionKey);
      
      // Encrypt the original filename
      final encryptedFileName = await _cryptoService.encryptString(
        originalFileName,
        encryptionKey,
      );
      
      // Create file with UUID
      final fileName = '$fileUuid.enc';
      final filePath = p.join(typeDir.path, fileName);
      final file = File(filePath);
      
      // Write encrypted data
      await file.writeAsBytes(encryptedData);
      
      // Write metadata file
      final metadata = {
        'uuid': fileUuid,
        'vaultId': vaultId,
        'type': type,
        'subType': subType,
        'encryptedFileName': encryptedFileName,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      final metadataFile = File('$filePath.meta');
      await metadataFile.writeAsString(await _encryptMetadata(metadata, encryptionKey));
      
      AppLogger.debug('Stored file: $fileUuid (size: ${data.length} bytes)');
      
      return fileUuid;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store file', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Uint8List?> retrieveFile(String fileUuid) async {
    try {
      // Find the file by UUID
      final file = await _findFileByUuid(fileUuid);
      if (file == null) {
        return null;
      }
      
      // Read encrypted data
      final encryptedData = await file.readAsBytes();
      
      // Get vault ID from metadata
      final metadata = await _readMetadata(file);
      final vaultId = metadata['vaultId'] as String;
      
      // Get encryption key
      final encryptionKey = await _getVaultEncryptionKey(vaultId);
      
      // Decrypt data
      final decryptedData = await _cryptoService.decryptBytes(encryptedData, encryptionKey);
      
      AppLogger.debug('Retrieved file: $fileUuid (size: ${decryptedData.length} bytes)');
      
      return decryptedData;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to retrieve file: $fileUuid', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(String fileUuid) async {
    try {
      final file = await _findFileByUuid(fileUuid);
      if (file == null) {
        return;
      }
      
      final metadataFile = File('${file.path}.meta');
      
      await file.delete();
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
      
      AppLogger.debug('Deleted file: $fileUuid');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete file: $fileUuid', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteVaultFiles(String vaultId) async {
    try {
      final vaultDir = Directory(p.join(_appDirectory.path, vaultId));
      if (!await vaultDir.exists()) {
        return;
      }
      
      await vaultDir.delete(recursive: true);
      
      AppLogger.debug('Deleted all files for vault: $vaultId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete vault files: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteVaultFilesByType(String vaultId, String type) async {
    try {
      final typeDir = Directory(p.join(_appDirectory.path, vaultId, type));
      if (!await typeDir.exists()) {
        return;
      }
      
      await typeDir.delete(recursive: true);
      
      AppLogger.debug('Deleted $type files for vault: $vaultId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete vault files by type', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<FileMetadata?> getFileMetadata(String fileUuid) async {
    try {
      final file = await _findFileByUuid(fileUuid);
      if (file == null) {
        return null;
      }
      
      final metadata = await _readMetadata(file);
      
      return FileMetadata(
        uuid: metadata['uuid'] as String,
        vaultId: metadata['vaultId'] as String,
        type: metadata['type'] as String,
        subType: metadata['subType'] as String?,
        encryptedPath: file.path,
        size: await file.length(),
        encryptedFileName: metadata['encryptedFileName'] as String,
        createdAt: DateTime.parse(metadata['createdAt'] as String),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get file metadata: $fileUuid', e, stackTrace);
      return null;
    }
  }

  @override
  Future<List<FileMetadata>> listVaultFiles(String vaultId) async {
    try {
      final vaultDir = Directory(p.join(_appDirectory.path, vaultId));
      if (!await vaultDir.exists()) {
        return [];
      }
      
      final files = <FileMetadata>[];
      
      await for (final entity in vaultDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.enc')) {
          final metadata = await _readMetadata(entity);
          files.add(FileMetadata(
            uuid: metadata['uuid'] as String,
            vaultId: metadata['vaultId'] as String,
            type: metadata['type'] as String,
            subType: metadata['subType'] as String?,
            encryptedPath: entity.path,
            size: await entity.length(),
            encryptedFileName: metadata['encryptedFileName'] as String,
            createdAt: DateTime.parse(metadata['createdAt'] as String),
          ));
        }
      }
      
      return files;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list vault files: $vaultId', e, stackTrace);
      return [];
    }
  }

  @override
  Future<List<FileMetadata>> listVaultFilesByType(String vaultId, String type) async {
    // Query DB directly filtered by type instead of loading all files
    // This is more efficient than loading all files and filtering in memory
    try {
      final vault = await _vaultRepository.getVaultById(vaultId);
      if (vault == null) {
        return [];
      }
      
      // Get file directory for this type
      final typeDir = Directory(p.join(_appDirectory.path, vaultId, type));
      if (!await typeDir.exists()) {
        return [];
      }
      
      final files = <FileMetadata>[];
      await for (final entity in typeDir.list()) {
        if (entity is File && entity.path.endsWith('.enc')) {
          try {
            final metadata = await _readMetadata(entity);
            files.add(FileMetadata(
              uuid: metadata['uuid'] as String,
              vaultId: metadata['vaultId'] as String,
              type: metadata['type'] as String,
              subType: metadata['subType'] as String?,
              encryptedPath: entity.path,
              size: await entity.length(),
              createdAt: DateTime.parse(metadata['createdAt'] as String),
            ));
            
            // Cache the path
            _uuidPathCache[metadata['uuid'] as String] = entity.path;
          } catch (e) {
            AppLogger.error('Failed to read metadata for ${entity.path}', e, null);
          }
        }
      }
      
      return files;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to list vault files by type', e, stackTrace);
      return [];
    }
  }

  @override
  Future<int> getVaultStorageSize(String vaultId) async {
    try {
      final vaultDir = Directory(p.join(_appDirectory.path, vaultId));
      if (!await vaultDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in vaultDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get vault storage size: $vaultId', e, stackTrace);
      return 0;
    }
  }

  @override
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = Directory(p.join(_appDirectory.path, 'temp'));
      if (!await tempDir.exists()) {
        return;
      }
      
      await tempDir.delete(recursive: true);
      
      AppLogger.debug('Cleaned up temporary files');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup temp files', e, stackTrace);
    }
  }

  Future<File?> _findFileByUuid(String fileUuid) async {
    try {
      // Check cache first
      if (_uuidPathCache.containsKey(fileUuid)) {
        final cachedPath = _uuidPathCache[fileUuid]!;
        final cachedFile = File(cachedPath);
        if (await cachedFile.exists()) {
          return cachedFile;
        } else {
          // Remove stale cache entry
          _uuidPathCache.remove(fileUuid);
        }
      }

      // Fall back to scan + populate cache
      await for (final entity in _appDirectory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('$fileUuid.enc')) {
          _uuidPathCache[fileUuid] = entity.path;
          return entity;
        }
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to find file by UUID: $fileUuid', e, stackTrace);
      return null;
    }
  }

  Future<Map<String, dynamic>> _readMetadata(File file) async {
    try {
      final metadataFile = File('${file.path}.meta');
      if (!await metadataFile.exists()) {
        throw Exception('Metadata file not found');
      }
      
      final encryptedMetadata = await metadataFile.readAsString();
      
      // Extract vault ID from file path
      final parts = p.split(file.path);
      final vaultId = parts[parts.length - 3];
      
      final encryptionKey = await _getVaultEncryptionKey(vaultId);
      final encryptedBytes = _cryptoService.base64ToBytes(encryptedMetadata);
      final decryptedMetadata = await _cryptoService.decryptBytes(encryptedBytes, encryptionKey);
      final metadataString = String.fromCharCodes(decryptedMetadata);
      
      // Parse JSON
      final metadata = jsonDecode(metadataString) as Map<String, dynamic>;
      
      return metadata;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read metadata', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _encryptMetadata(Map<String, dynamic> metadata, Uint8List key) async {
    final json = jsonEncode(metadata);
    final encrypted = await _cryptoService.encryptString(json, key);
    return _cryptoService.bytesToBase64(encrypted.toBytes());
  }

  Future<Uint8List> _getVaultEncryptionKey(String vaultId) async {
    // Retrieve encryption key from secure storage with key vault_enc_key_{vaultId}
    final keyBytes = await _secureKeyStorage.retrieveKey('vault_enc_key_$vaultId');
    if (keyBytes == null) {
      throw Exception('Vault encryption key not found in secure storage: $vaultId');
    }
    return keyBytes;
  }
}
