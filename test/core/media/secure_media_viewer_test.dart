import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:typed_data';
import 'package:cover/core/media/secure_media_viewer.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/data/local/database/tables.dart';

@GenerateMocks([
  SecureFileStorage,
  MediaItemRepository,
])
import 'secure_media_viewer_test.mocks.dart';

void main() {
  group('SecureMediaViewer', () {
    late SecureMediaViewerImpl secureMediaViewer;
    late MockSecureFileStorage mockSecureFileStorage;
    late MockMediaItemRepository mockMediaItemRepository;

    setUp(() {
      mockSecureFileStorage = MockSecureFileStorage();
      mockMediaItemRepository = MockMediaItemRepository();

      secureMediaViewer = SecureMediaViewerImpl(
        mockSecureFileStorage,
        mockMediaItemRepository,
      );
    });

    group('Load Media', () {
      test('should return error when media item not found', () async {
        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => null);

        final result = await secureMediaViewer.loadMedia(1);

        expect(result.success, isFalse);
        expect(result.error, contains('Media item not found'));
      });

      test('should return error when file cannot be retrieved', () async {
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
        when(mockSecureFileStorage.retrieveFile('file-uuid')).thenAnswer((_) async => null);

        final result = await secureMediaViewer.loadMedia(1);

        expect(result.success, isFalse);
        expect(result.error, contains('Could not retrieve media file'));
      });

      test('should return error for unsupported media type', () async {
        final mediaItem = MediaItem(
          id: 1,
          vaultId: 'vault-1',
          type: 'document',
          encryptedFilePath: 'file-uuid',
          originalFileName: 'doc.pdf',
          fileSize: 1000,
          mimeType: 'application/pdf',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => mediaItem);
        when(mockSecureFileStorage.retrieveFile('file-uuid')).thenAnswer((_) async => Uint8List(100));

        final result = await secureMediaViewer.loadMedia(1);

        expect(result.success, isFalse);
        expect(result.error, contains('Unsupported media type'));
      });
    });

    group('Unload Media', () {
      test('should unload media without throwing', () {
        expect(() => secureMediaViewer.unloadMedia(1), returnsNormally);
      });
    });

    group('Get Media Type', () {
      test('should return null when media item not found', () async {
        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => null);

        final mediaType = await secureMediaViewer.getMediaType(1);

        expect(mediaType, isNull);
      });

      test('should return photo type', () async {
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

        final mediaType = await secureMediaViewer.getMediaType(1);

        expect(mediaType, equals('photo'));
      });
    });

    group('Get Media Metadata', () {
      test('should return null when media item not found', () async {
        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => null);

        final metadata = await secureMediaViewer.getMediaMetadata(1);

        expect(metadata, isNull);
      });

      test('should return metadata for media item', () async {
        final mediaItem = MediaItem(
          id: 1,
          vaultId: 'vault-1',
          type: 'photo',
          encryptedFilePath: 'file-uuid',
          originalFileName: 'photo.jpg',
          fileSize: 1000,
          mimeType: 'image/jpeg',
          width: 1920,
          height: 1080,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMediaItemRepository.getMediaItemById(1)).thenAnswer((_) async => mediaItem);

        final metadata = await secureMediaViewer.getMediaMetadata(1);

        expect(metadata, isNotNull);
        expect(metadata!['type'], equals('photo'));
        expect(metadata['fileSize'], equals(1000));
        expect(metadata['mimeType'], equals('image/jpeg'));
        expect(metadata['width'], equals(1920));
        expect(metadata['height'], equals(1080));
      });
    });

    group('Cleanup All', () {
      test('should cleanup all media without throwing', () {
        expect(() => secureMediaViewer.cleanupAll(), returnsNormally);
      });
    });
  });
}
