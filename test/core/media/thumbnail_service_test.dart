import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:typed_data';
import 'package:cover/core/media/thumbnail_service.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/data/local/database/tables.dart';

@GenerateMocks([
  SecureFileStorage,
  MediaItemRepository,
  AppConfig,
])
import 'thumbnail_service_test.mocks.dart';

void main() {
  group('ThumbnailService', () {
    late ThumbnailServiceImpl thumbnailService;
    late MockSecureFileStorage mockSecureFileStorage;
    late MockMediaItemRepository mockMediaItemRepository;
    late MockAppConfig mockAppConfig;

    setUp(() {
      mockSecureFileStorage = MockSecureFileStorage();
      mockMediaItemRepository = MockMediaItemRepository();
      mockAppConfig = MockAppConfig();

      thumbnailService = ThumbnailServiceImpl(
        mockSecureFileStorage,
        mockMediaItemRepository,
        mockAppConfig,
      );
    });

    group('Generate Thumbnail', () {
      test('should return error when media item not found', () async {
        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => null);

        final result = await thumbnailService.generateThumbnail(1);

        expect(result.success, isFalse);
        expect(result.error, contains('Media item not found'));
      });

      test('should return success when thumbnail already exists', () async {
        final mediaItem = MediaItem(
          id: 1,
          vaultId: 'vault-1',
          type: 'photo',
          encryptedFilePath: 'file-uuid',
          encryptedThumbnailPath: 'thumb-uuid',
          originalFileName: 'photo.jpg',
          fileSize: 1000,
          mimeType: 'image/jpeg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => mediaItem);

        final result = await thumbnailService.generateThumbnail(1);

        expect(result.success, isTrue);
        expect(result.thumbnailUuid, equals('thumb-uuid'));
      });

      test('should skip thumbnail generation for videos', () async {
        final mediaItem = MediaItem(
          id: 1,
          vaultId: 'vault-1',
          type: 'video',
          encryptedFilePath: 'file-uuid',
          originalFileName: 'video.mp4',
          fileSize: 5000,
          mimeType: 'video/mp4',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => mediaItem);

        final result = await thumbnailService.generateThumbnail(1);

        expect(result.success, isFalse);
        expect(result.error, contains('Thumbnails only supported for photos'));
      });
    });

    group('Generate Multiple Thumbnails', () {
      test('should generate thumbnails for multiple items', () async {
        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => null);
        when(mockMediaItemRepository.getMediaItemById(2)).thenAnswer((_) async => null);

        final results = await thumbnailService.generateThumbnails([1, 2]);

        expect(results, hasLength(2));
      });
    });

    group('Get Thumbnail', () {
      test('should return null when media item not found', () async {
        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => null);

        final thumbnail = await thumbnailService.getThumbnail(1);

        expect(thumbnail, isNull);
      });

      test('should return null when no thumbnail exists', () async {
        final mediaItem = MediaItem(
          id: 1,
          vaultId: 'vault-1',
          type: 'photo',
          encryptedFilePath: 'file-uuid',
          originalFileName: 'photo.jpg',
          fileSize: 1000,
          mimeType: 'image/jpeg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => mediaItem);

        final thumbnail = await thumbnailService.getThumbnail(1);

        expect(thumbnail, isNull);
      });
    });

    group('Delete Thumbnail', () {
      test('should return early when media item not found', () async {
        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => null);

        expect(() => thumbnailService.deleteThumbnail(1), returnsNormally);
      });

      test('should return early when no thumbnail exists', () async {
        final mediaItem = MediaItem(
          id: 1,
          vaultId: 'vault-1',
          type: 'photo',
          encryptedFilePath: 'file-uuid',
          originalFileName: 'photo.jpg',
          fileSize: 1000,
          mimeType: 'image/jpeg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => mediaItem);

        expect(() => thumbnailService.deleteThumbnail(1), returnsNormally);
      });
    });

    group('Clear Cache', () {
      test('should clear cache without throwing', () {
        expect(() => thumbnailService.clearCache(), returnsNormally);
      });
    });
  });
}
