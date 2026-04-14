import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:typed_data';
import 'package:cover/core/files/export_hardening_service.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/file_repository.dart';
import 'package:cover/data/local/database/tables.dart';

@GenerateMocks([
  SecureFileStorage,
  FileRepository,
])
import 'export_hardening_service_test.mocks.dart';

void main() {
  group('ExportHardeningService', () {
    late ExportHardeningServiceImpl exportHardeningService;
    late MockSecureFileStorage mockSecureFileStorage;
    late MockFileRepository mockFileRepository;

    setUp(() {
      mockSecureFileStorage = MockSecureFileStorage();
      mockFileRepository = MockFileRepository();

      exportHardeningService = ExportHardeningServiceImpl(
        mockSecureFileStorage,
        mockFileRepository,
      );
    });

    group('Export With Confirmation', () {
      test('should return error when file not found', () async {
        when(mockFileRepository.getFileById(1)).thenAnswer((_) async => null);

        final result = await exportHardeningService.exportWithConfirmation(
          1,
          null, // BuildContext would be mocked in real test
          requireConfirmation: false,
        );

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

        final result = await exportHardeningService.exportWithConfirmation(
          1,
          null,
          requireConfirmation: false,
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Could not retrieve file data'));
      });
    });

    group('Cleanup Temp File', () {
      test('should cleanup without throwing', () {
        expect(() => exportHardeningService.cleanupTempFile('/tmp/test.pdf'), returnsNormally);
      });
    });

    group('Cleanup All Temp Files', () {
      test('should cleanup all without throwing', () {
        expect(() => exportHardeningService.cleanupAllTempFiles(), returnsNormally);
      });
    });

    group('Get Active Temp Files', () {
      test('should return empty list initially', () async {
        final activeFiles = await exportHardeningService.getActiveTempFiles();
        expect(activeFiles, isEmpty);
      });
    });

    group('Needs Cleanup', () {
      test('should return false initially', () async {
        final needsCleanup = await exportHardeningService.needsCleanup();
        expect(needsCleanup, isFalse);
      });
    });
  });
}
