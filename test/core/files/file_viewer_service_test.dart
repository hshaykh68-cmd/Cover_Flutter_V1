import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:typed_data';
import 'package:cover/core/files/file_viewer_service.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/file_repository.dart';
import 'package:cover/data/local/database/tables.dart';

@GenerateMocks([
  SecureFileStorage,
  FileRepository,
])
import 'file_viewer_service_test.mocks.dart';

void main() {
  group('FileViewerService', () {
    late FileViewerServiceImpl fileViewerService;
    late MockSecureFileStorage mockSecureFileStorage;
    late MockFileRepository mockFileRepository;

    setUp(() {
      mockSecureFileStorage = MockSecureFileStorage();
      mockFileRepository = MockFileRepository();

      fileViewerService = FileViewerServiceImpl(
        mockSecureFileStorage,
        mockFileRepository,
      );
    });

    group('Load File', () {
      test('should return error when file not found', () async {
        when(mockFileRepository.getFileById(1)).thenAnswer((_) async => null);

        final result = await fileViewerService.loadFile(1);

        expect(result.success, isFalse);
        expect(result.error, contains('File not found'));
      });

      test('should return error when file data cannot be retrieved', () async {
        final fileItem = FileItem(
          id: 1,
          vaultId: 'vault-1',
          encryptedFilePath: 'file-uuid',
          originalFileName: 'document.pdf',
          fileSize: 1000,
          mimeType: 'application/pdf',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockFileRepository.getFileById(1)).thenAnswer((_) async => fileItem);
        when(mockSecureFileStorage.retrieveFile('file-uuid')).thenAnswer((_) async => null);

        final result = await fileViewerService.loadFile(1);

        expect(result.success, isFalse);
        expect(result.error, contains('Could not retrieve file data'));
      });

      test('should mark unsupported types as requiring export', () async {
        final fileItem = FileItem(
          id: 1,
          vaultId: 'vault-1',
          encryptedFilePath: 'file-uuid',
          originalFileName: 'document.pdf',
          fileSize: 1000,
          mimeType: 'application/pdf',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockFileRepository.getFileById(1)).thenAnswer((_) async => fileItem);
        when(mockSecureFileStorage.retrieveFile('file-uuid')).thenAnswer((_) async => Uint8List(100));

        final result = await fileViewerService.loadFile(1);

        expect(result.success, isTrue);
        expect(result.requiresExport, isTrue);
      });

      test('should not mark supported types as requiring export', () async {
        final fileItem = FileItem(
          id: 1,
          vaultId: 'vault-1',
          encryptedFilePath: 'file-uuid',
          originalFileName: 'image.jpg',
          fileSize: 1000,
          mimeType: 'image/jpeg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockFileRepository.getFileById(1)).thenAnswer((_) async => fileItem);
        when(mockSecureFileStorage.retrieveFile('file-uuid')).thenAnswer((_) async => Uint8List(100));

        final result = await fileViewerService.loadFile(1);

        expect(result.success, isTrue);
        expect(result.requiresExport, isFalse);
      });
    });

    group('Is Supported Type', () {
      test('should return true for supported image types', () {
        expect(fileViewerService.isSupportedType('image/jpeg'), isTrue);
        expect(fileViewerService.isSupportedType('image/png'), isTrue);
        expect(fileViewerService.isSupportedType('image/gif'), isTrue);
      });

      test('should return true for supported text types', () {
        expect(fileViewerService.isSupportedType('text/plain'), isTrue);
        expect(fileViewerService.isSupportedType('text/html'), isTrue);
        expect(fileViewerService.isSupportedType('application/json'), isTrue);
      });

      test('should return false for unsupported types', () {
        expect(fileViewerService.isSupportedType('application/pdf'), isFalse);
        expect(fileViewerService.isSupportedType('application/zip'), isFalse);
        expect(fileViewerService.isSupportedType('application/octet-stream'), isFalse);
      });
    });

    group('Cleanup Temp Files', () {
      test('should cleanup without throwing', () {
        expect(() => fileViewerService.cleanupTempFiles(), returnsNormally);
      });
    });
  });
}
