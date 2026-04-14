import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:path/path.dart' as p;

/// Thumbnail generation result
class ThumbnailResult {
  final bool success;
  final String? thumbnailUuid;
  final String? error;

  ThumbnailResult({
    required this.success,
    this.thumbnailUuid,
    this.error,
  });
}

/// Thumbnail service interface
abstract class ThumbnailService {
  /// Generate and store encrypted thumbnail for a media item
  Future<ThumbnailResult> generateThumbnail(int mediaItemId);

  /// Generate and store encrypted thumbnails for multiple media items
  Future<List<ThumbnailResult>> generateThumbnails(List<int> mediaItemIds);

  /// Retrieve and decrypt thumbnail for a media item
  Future<Uint8List?> getThumbnail(int mediaItemId);

  /// Delete thumbnail for a media item
  Future<void> deleteThumbnail(int mediaItemId);

  /// Clear thumbnail cache
  void clearCache();
}

/// Thumbnail service implementation
class ThumbnailServiceImpl implements ThumbnailService {
  final SecureFileStorage _secureFileStorage;
  final MediaItemRepository _mediaItemRepository;
  final AppConfig _appConfig;
  
  // In-memory cache for thumbnails
  final Map<int, Uint8List> _thumbnailCache = {};
  static const int _maxCacheSize = 100;

  ThumbnailServiceImpl(
    this._secureFileStorage,
    this._mediaItemRepository,
    this._appConfig,
  );

  @override
  Future<ThumbnailResult> generateThumbnail(int mediaItemId) async {
    try {
      // Get media item
      final mediaItem = await _mediaItemRepository.getMediaItemById(mediaItemId);
      if (mediaItem == null) {
        return ThumbnailResult(
          success: false,
          error: 'Media item not found',
        );
      }

      // Skip if already has thumbnail
      if (mediaItem.encryptedThumbnailPath != null) {
        return ThumbnailResult(
          success: true,
          thumbnailUuid: mediaItem.encryptedThumbnailPath,
        );
      }

      // Only generate thumbnails for photos
      if (mediaItem.type != 'photo') {
        return ThumbnailResult(
          success: false,
          error: 'Thumbnails only supported for photos',
        );
      }

      // Retrieve original file
      final fileData = await _secureFileStorage.retrieveFile(mediaItem.encryptedFilePath);
      if (fileData == null) {
        return ThumbnailResult(
          success: false,
          error: 'Could not retrieve original file',
        );
      }

      // Generate thumbnail
      final thumbnailData = await _generateThumbnailData(fileData);
      if (thumbnailData == null) {
        return ThumbnailResult(
          success: false,
          error: 'Failed to generate thumbnail',
        );
      }

      // Store encrypted thumbnail
      final thumbnailUuid = await _secureFileStorage.storeFile(
        vaultId: mediaItem.vaultId,
        type: 'thumbnail',
        data: thumbnailData,
        originalFileName: 'thumb_${mediaItem.id}.jpg',
      );

      // Update media item with thumbnail path
      final updatedItem = mediaItem.copyWith(
        encryptedThumbnailPath: thumbnailUuid,
      );
      await _mediaItemRepository.updateMediaItem(updatedItem);

      AppLogger.info('Generated thumbnail for media item $mediaItemId');

      return ThumbnailResult(
        success: true,
        thumbnailUuid: thumbnailUuid,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate thumbnail for $mediaItemId', e, stackTrace);
      return ThumbnailResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<List<ThumbnailResult>> generateThumbnails(List<int> mediaItemIds) async {
    final results = <ThumbnailResult>[];

    for (final id in mediaItemIds) {
      final result = await generateThumbnail(id);
      results.add(result);
    }

    return results;
  }

  @override
  Future<Uint8List?> getThumbnail(int mediaItemId) async {
    try {
      // Check cache first
      if (_thumbnailCache.containsKey(mediaItemId)) {
        return _thumbnailCache[mediaItemId];
      }

      // Get media item
      final mediaItem = await _mediaItemRepository.getMediaItemById(mediaItemId);
      if (mediaItem == null || mediaItem.encryptedThumbnailPath == null) {
        return null;
      }

      // Retrieve and decrypt thumbnail
      final thumbnailData = await _secureFileStorage.retrieveFile(
        mediaItem.encryptedThumbnailPath!,
      );
      if (thumbnailData == null) {
        return null;
      }

      // Add to cache
      _addToCache(mediaItemId, thumbnailData);

      return thumbnailData;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get thumbnail for $mediaItemId', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> deleteThumbnail(int mediaItemId) async {
    try {
      final mediaItem = await _mediaItemRepository.getMediaItemById(mediaItemId);
      if (mediaItem == null || mediaItem.encryptedThumbnailPath == null) {
        return;
      }

      // Delete from secure storage
      await _secureFileStorage.deleteFile(mediaItem.encryptedThumbnailPath!);

      // Update media item
      final updatedItem = mediaItem.copyWith(encryptedThumbnailPath: null);
      await _mediaItemRepository.updateMediaItem(updatedItem);

      // Remove from cache
      _thumbnailCache.remove(mediaItemId);

      AppLogger.info('Deleted thumbnail for media item $mediaItemId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete thumbnail for $mediaItemId', e, stackTrace);
    }
  }

  @override
  void clearCache() {
    _thumbnailCache.clear();
    AppLogger.debug('Cleared thumbnail cache');
  }

  Future<Uint8List?> _generateThumbnailData(Uint8List imageData) async {
    try {
      // Decode image
      final image = img.decodeImage(imageData);
      if (image == null) {
        return null;
      }

      // Get thumbnail quality from config
      final quality = _appConfig.thumbnailQuality;

      // Calculate thumbnail size (max 300px on longest side)
      final maxDimension = 300;
      int width = image.width;
      int height = image.height;

      if (width > height) {
        if (width > maxDimension) {
          height = (height * maxDimension / width).round();
          width = maxDimension;
        }
      } else {
        if (height > maxDimension) {
          width = (width * maxDimension / height).round();
          height = maxDimension;
        }
      }

      // Resize image
      final thumbnail = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      // Encode to JPEG
      final thumbnailData = img.encodeJpg(thumbnail, quality: quality);

      return thumbnailData;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate thumbnail data', e, stackTrace);
      return null;
    }
  }

  void _addToCache(int mediaItemId, Uint8List thumbnailData) {
    // Evict oldest if cache is full
    if (_thumbnailCache.length >= _maxCacheSize) {
      _thumbnailCache.remove(_thumbnailCache.keys.first);
    }
    _thumbnailCache[mediaItemId] = thumbnailData;
  }
}
