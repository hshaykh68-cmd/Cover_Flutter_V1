import 'package:cover/data/local/database/daos/media_item_dao.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/core/utils/logger.dart';

class MediaItemRepositoryImpl implements MediaItemRepository {
  final MediaItemDao _mediaItemDao;

  MediaItemRepositoryImpl(this._mediaItemDao);

  @override
  Future<MediaItem?> getMediaItemById(int id) async {
    try {
      return await _mediaItemDao.getMediaItemById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get media item by id: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getMediaItemsByVault(String vaultId) async {
    try {
      return await _mediaItemDao.getMediaItemsByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get media items for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getMediaItemsByType(String vaultId, String type) async {
    try {
      return await _mediaItemDao.getMediaItemsByType(vaultId, type);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get media items by type', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getPhotosByVault(String vaultId) async {
    try {
      return await _mediaItemDao.getPhotosByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get photos for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getVideosByVault(String vaultId) async {
    try {
      return await _mediaItemDao.getVideosByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get videos for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<MediaItem> createMediaItem(MediaItemsCompanion mediaItem) async {
    try {
      return await _mediaItemDao.createMediaItem(mediaItem);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create media item', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> createMediaItems(List<MediaItemsCompanion> mediaItems) async {
    try {
      await _mediaItemDao.createMediaItems(mediaItems);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create media items', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateMediaItem(MediaItem mediaItem) async {
    try {
      return await _mediaItemDao.updateMediaItem(mediaItem);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update media item', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteMediaItem(int id) async {
    try {
      return await _mediaItemDao.deleteMediaItem(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete media item: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteMediaItemsByVault(String vaultId) async {
    try {
      return await _mediaItemDao.deleteMediaItemsByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete media items for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getMediaItemCount(String vaultId) async {
    try {
      return await _mediaItemDao.getMediaItemCount(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get media item count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getMediaItemCountByType(String vaultId, String type) async {
    try {
      return await _mediaItemDao.getMediaItemCountByType(vaultId, type);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get media item count by type', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> searchMediaItems(String vaultId, String query) async {
    try {
      return await _mediaItemDao.searchMediaItems(vaultId, query);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search media items', e, stackTrace);
      rethrow;
    }
  }
}
