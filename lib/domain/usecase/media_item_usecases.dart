import '../repository/media_item_repository.dart';
import '../model/media_item.dart';

/// Use case for adding a media item
class AddMediaItemUseCase {
  final MediaItemRepository _repository;

  AddMediaItemUseCase(this._repository);

  Future<int> call(MediaItem item) {
    return _repository.addMediaItem(item);
  }
}

/// Use case for retrieving all media items for a vault
class GetMediaItemsUseCase {
  final MediaItemRepository _repository;

  GetMediaItemsUseCase(this._repository);

  Future<List<MediaItem>> call(String vaultId) {
    return _repository.getMediaItems(vaultId);
  }
}

/// Use case for retrieving a media item by ID
class GetMediaItemByIdUseCase {
  final MediaItemRepository _repository;

  GetMediaItemByIdUseCase(this._repository);

  Future<MediaItem?> call(int id) {
    return _repository.getMediaItemById(id);
  }
}

/// Use case for updating a media item
class UpdateMediaItemUseCase {
  final MediaItemRepository _repository;

  UpdateMediaItemUseCase(this._repository);

  Future<void> call(MediaItem item) {
    return _repository.updateMediaItem(item);
  }
}

/// Use case for deleting a media item
class DeleteMediaItemUseCase {
  final MediaItemRepository _repository;

  DeleteMediaItemUseCase(this._repository);

  Future<void> call(int id) {
    return _repository.deleteMediaItem(id);
  }
}

/// Use case for getting media items by type
class GetMediaItemsByTypeUseCase {
  final MediaItemRepository _repository;

  GetMediaItemsByTypeUseCase(this._repository);

  Future<List<MediaItem>> call(String vaultId, String type) {
    return _repository.getMediaItemsByType(vaultId, type);
  }
}
