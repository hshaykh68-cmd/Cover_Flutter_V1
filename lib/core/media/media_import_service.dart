import 'dart:typed_data';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/domain/repository/vault_repository.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:path/path.dart' as p;

/// Result of importing media
class MediaImportResult {
  final int successCount;
  final int failedCount;
  final List<String> errors;
  final List<ImportedMediaItem> importedItems;

  MediaImportResult({
    required this.successCount,
    required this.failedCount,
    required this.errors,
    required this.importedItems,
  });
}

/// Information about an imported media item
class ImportedMediaItem {
  final int mediaItemId;
  final String type;
  final String originalFileName;
  final int fileSize;
  final String mimeType;

  ImportedMediaItem({
    required this.mediaItemId,
    required this.type,
    required this.originalFileName,
    required this.fileSize,
    required this.mimeType,
  });
}

/// Media import service interface
abstract class MediaImportService {
  /// Import photos from device gallery
  Future<MediaImportResult> importPhotos({
    required String vaultId,
    int maxCount = 100,
  });

  /// Import videos from device gallery
  Future<MediaImportResult> importVideos({
    required String vaultId,
    int maxCount = 100,
  });

  /// Import media using image picker (single)
  Future<ImportedMediaItem?> importSingle({
    required String vaultId,
  });

  /// Import media using camera
  Future<ImportedMediaItem?> importFromCamera({
    required String vaultId,
  });

  /// Cancel ongoing import
  void cancelImport();
}

/// Media import service implementation
class MediaImportServiceImpl implements MediaImportService {
  final SecureFileStorage _secureFileStorage;
  final MediaItemRepository _mediaItemRepository;
  final VaultRepository _vaultRepository;
  final AppConfig _appConfig;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isImporting = false;
  bool _isCancelled = false;

  MediaImportServiceImpl(
    this._secureFileStorage,
    this._mediaItemRepository,
    this._vaultRepository,
    this._appConfig,
  );

  @override
  Future<MediaImportResult> importPhotos({
    required String vaultId,
    int maxCount = 100,
  }) async {
    if (_isImporting) {
      throw StateError('Import already in progress');
    }

    _isImporting = true;
    _isCancelled = false;

    final successCount = <int>[];
    final errors = <String>[];
    final importedItems = <ImportedMediaItem>[];

    try {
      // Request permission
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        throw Exception('Photo library permission denied');
      }

      // Get max batch size from config
      final batchSize = _appConfig.maxImportBatchSize;

      // Fetch photos
      final List<AssetEntity> photos = await PhotoManager.assetPath
          .getAssetListRange(
            start: 0,
            end: maxCount,
            type: RequestType.image,
          );

      AppLogger.info('Found ${photos.length} photos to import');

      // Process in batches
      for (int i = 0; i < photos.length; i += batchSize) {
        if (_isCancelled) break;

        final batch = photos.skip(i).take(batchSize).toList();
        final results = await _processBatch(
          vaultId: vaultId,
          assets: batch,
          type: 'photo',
        );

        successCount.addAll(results.successCount);
        errors.addAll(results.errors);
        importedItems.addAll(results.importedItems);

        AppLogger.debug('Processed batch ${i ~/ batchSize + 1}/${(photos.length / batchSize).ceil()}');
      }

      // Update vault item count
      await _updateVaultItemCount(vaultId);

      return MediaImportResult(
        successCount: successCount.length,
        failedCount: errors.length,
        errors: errors,
        importedItems: importedItems,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to import photos', e, stackTrace);
      rethrow;
    } finally {
      _isImporting = false;
    }
  }

  @override
  Future<MediaImportResult> importVideos({
    required String vaultId,
    int maxCount = 100,
  }) async {
    if (_isImporting) {
      throw StateError('Import already in progress');
    }

    _isImporting = true;
    _isCancelled = false;

    final successCount = <int>[];
    final errors = <String>[];
    final importedItems = <ImportedMediaItem>[];

    try {
      // Request permission
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        throw Exception('Photo library permission denied');
      }

      // Get max batch size from config
      final batchSize = _appConfig.maxImportBatchSize;

      // Fetch videos
      final List<AssetEntity> videos = await PhotoManager.assetPath
          .getAssetListRange(
            start: 0,
            end: maxCount,
            type: RequestType.video,
          );

      AppLogger.info('Found ${videos.length} videos to import');

      // Process in batches
      for (int i = 0; i < videos.length; i += batchSize) {
        if (_isCancelled) break;

        final batch = videos.skip(i).take(batchSize).toList();
        final results = await _processBatch(
          vaultId: vaultId,
          assets: batch,
          type: 'video',
        );

        successCount.addAll(results.successCount);
        errors.addAll(results.errors);
        importedItems.addAll(results.importedItems);

        AppLogger.debug('Processed batch ${i ~/ batchSize + 1}/${(videos.length / batchSize).ceil()}');
      }

      // Update vault item count
      await _updateVaultItemCount(vaultId);

      return MediaImportResult(
        successCount: successCount.length,
        failedCount: errors.length,
        errors: errors,
        importedItems: importedItems,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to import videos', e, stackTrace);
      rethrow;
    } finally {
      _isImporting = false;
    }
  }

  @override
  Future<ImportedMediaItem?> importSingle({
    required String vaultId,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return null;

      return await _importFile(
        vaultId: vaultId,
        file: File(pickedFile.path),
        type: 'photo',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to import single media', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<ImportedMediaItem?> importFromCamera({
    required String vaultId,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile == null) return null;

      return await _importFile(
        vaultId: vaultId,
        file: File(pickedFile.path),
        type: 'photo',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to import from camera', e, stackTrace);
      rethrow;
    }
  }

  @override
  void cancelImport() {
    _isCancelled = true;
    AppLogger.info('Import cancelled');
  }

  Future<_BatchResult> _processBatch({
    required String vaultId,
    required List<AssetEntity> assets,
    required String type,
  }) async {
    final successCount = <int>[];
    final errors = <String>[];
    final importedItems = <ImportedMediaItem>[];

    for (final asset in assets) {
      if (_isCancelled) break;

      try {
        final result = await _importAsset(vaultId, asset, type);
        successCount.add(result.mediaItemId);
        importedItems.add(result);
      } catch (e, stackTrace) {
        final error = 'Failed to import ${asset.title}: $e';
        AppLogger.error(error, e, stackTrace);
        errors.add(error);
      }
    }

    return _BatchResult(
      successCount: successCount,
      errors: errors,
      importedItems: importedItems,
    );
  }

  Future<ImportedMediaItem> _importAsset(
    String vaultId,
    AssetEntity asset,
    String type,
  ) async {
    // Get file data
    final file = await asset.file;
    if (file == null) {
      throw Exception('Could not access asset file');
    }

    return await _importFile(vaultId: vaultId, file: file, type: type);
  }

  Future<ImportedMediaItem> _importFile({
    required String vaultId,
    required File file,
    required String type,
  }) async {
    // Read file data
    final fileData = await file.readAsBytes();
    final fileSize = fileData.length;
    final fileName = p.basename(file.path);

    // Determine MIME type
    final mimeType = _getMimeType(fileName, type);

    // Get dimensions for images/videos
    int? width;
    int? height;
    int? duration;

    if (type == 'photo') {
      final image = await _getImageDimensions(file);
      width = image['width'];
      height = image['height'];
    } else if (type == 'video') {
      final video = await _getVideoMetadata(file);
      width = video['width'];
      height = video['height'];
      duration = video['duration'];
    }

    // Store encrypted file
    final fileUuid = await _secureFileStorage.storeFile(
      vaultId: vaultId,
      type: type,
      data: fileData,
      originalFileName: fileName,
    );

    // Create database record
    final mediaItem = await _mediaItemRepository.createMediaItem(
      MediaItemsCompanion(
        vaultId: Value(vaultId),
        type: Value(type),
        encryptedFilePath: Value(fileUuid),
        originalFileName: Value(fileName),
        fileSize: Value(fileSize),
        mimeType: Value(mimeType),
        width: Value(width),
        height: Value(height),
        duration: Value(duration),
      ),
    );

    AppLogger.info('Imported $type: $fileName (ID: ${mediaItem.id})');

    return ImportedMediaItem(
      mediaItemId: mediaItem.id,
      type: type,
      originalFileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );
  }

  Future<void> _updateVaultItemCount(String vaultId) async {
    final vault = await _vaultRepository.getVaultById(vaultId);
    if (vault != null) {
      final count = await _mediaItemRepository.getMediaItemCount(vaultId);
      await _vaultRepository.updateVaultItemCount(vaultId, count);
    }
  }

  String _getMimeType(String fileName, String type) {
    final extension = p.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      default:
        return type == 'photo' ? 'image/jpeg' : 'video/mp4';
    }
  }

  Future<Map<String, int>> _getImageDimensions(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        return {'width': image.width, 'height': image.height};
      }
      return {'width': 0, 'height': 0};
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get image dimensions', e, stackTrace);
      return {'width': 0, 'height': 0};
    }
  }

  Future<Map<String, int>> _getVideoMetadata(File file) async {
    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      
      final metadata = {
        'width': controller.value.size.width.toInt(),
        'height': controller.value.size.height.toInt(),
        'duration': controller.value.duration.inSeconds,
      };
      
      controller.dispose();
      return metadata;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get video metadata', e, stackTrace);
      return {'width': 0, 'height': 0, 'duration': 0};
    }
  }
}

class _BatchResult {
  final List<int> successCount;
  final List<String> errors;
  final List<ImportedMediaItem> importedItems;

  _BatchResult({
    required this.successCount,
    required this.errors,
    required this.importedItems,
  });
}
