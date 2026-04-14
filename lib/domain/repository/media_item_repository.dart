import 'package:cover/data/local/database/tables.dart';

abstract class MediaItemRepository {
  Future<MediaItem?> getMediaItemById(int id);
  Future<List<MediaItem>> getMediaItemsByVault(String vaultId);
  Future<List<MediaItem>> getMediaItemsByType(String vaultId, String type);
  Future<List<MediaItem>> getPhotosByVault(String vaultId);
  Future<List<MediaItem>> getVideosByVault(String vaultId);
  Future<MediaItem> createMediaItem(MediaItemsCompanion mediaItem);
  Future<void> createMediaItems(List<MediaItemsCompanion> mediaItems);
  Future<bool> updateMediaItem(MediaItem mediaItem);
  Future<int> deleteMediaItem(int id);
  Future<int> deleteMediaItemsByVault(String vaultId);
  Future<int> getMediaItemCount(String vaultId);
  Future<int> getMediaItemCountByType(String vaultId, String type);
  Future<List<MediaItem>> searchMediaItems(String vaultId, String query);
}
