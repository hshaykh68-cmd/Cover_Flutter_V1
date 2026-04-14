import 'package:cover/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

part 'media_item_dao.g.dart';

/// Data Access Object for Media Item operations
@DriftAccessor(tables: [MediaItems])
class MediaItemDao extends DatabaseAccessor<AppDatabase> with _$MediaItemDaoMixin {
  MediaItemDao(AppDatabase db) : super(db);

  /// Get media item by ID
  Future<MediaItem?> getMediaItemById(int id) {
    return (select(mediaItems)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get all media items for a vault
  Future<List<MediaItem>> getMediaItemsByVault(String vaultId) {
    return (select(mediaItems)..where((tbl) => tbl.vaultId.equals(vaultId))).get();
  }

  /// Get media items by type for a vault
  Future<List<MediaItem>> getMediaItemsByType(String vaultId, String type) {
    return (select(mediaItems)
          ..where((tbl) => tbl.vaultId.equals(vaultId) & tbl.type.equals(type)))
        .get();
  }

  /// Get photos for a vault
  Future<List<MediaItem>> getPhotosByVault(String vaultId) {
    return getMediaItemsByType(vaultId, 'photo');
  }

  /// Get videos for a vault
  Future<List<MediaItem>> getVideosByVault(String vaultId) {
    return getMediaItemsByType(vaultId, 'video');
  }

  /// Create a new media item
  Future<MediaItem> createMediaItem(MediaItemsCompanion mediaItem) async {
    return await into(mediaItems).insert(mediaItem);
  }

  /// Create multiple media items
  Future<void> createMediaItems(List<MediaItemsCompanion> mediaItems) async {
    await batch((batch) {
      batch.insertAll(this.mediaItems, mediaItems);
    });
  }

  /// Update a media item
  Future<bool> updateMediaItem(MediaItem mediaItem) {
    return update(mediaItems).replace(mediaItem);
  }

  /// Delete a media item
  Future<int> deleteMediaItem(int id) {
    return (delete(mediaItems)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete all media items for a vault
  Future<int> deleteMediaItemsByVault(String vaultId) {
    return (delete(mediaItems)..where((tbl) => tbl.vaultId.equals(vaultId))).go();
  }

  /// Get media item count for a vault
  Future<int> getMediaItemCount(String vaultId) {
    return (select(mediaItems)..where((tbl) => tbl.vaultId.equals(vaultId)))
        .get()
        .then((list) => list.length);
  }

  /// Get media item count by type for a vault
  Future<int> getMediaItemCountByType(String vaultId, String type) {
    return (select(mediaItems)
          ..where((tbl) => tbl.vaultId.equals(vaultId) & tbl.type.equals(type)))
        .get()
        .then((list) => list.length);
  }

  /// Search media items by encrypted file name
  Future<List<MediaItem>> searchMediaItems(String vaultId, String query) {
    return (select(mediaItems)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.originalFileName.contains(query)))
        .get();
  }
}
