import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/crypto/crypto_service_impl.dart';
import 'package:cover/data/storage/secure_file_storage.dart';

void main() {
  group('SecureFileStorageImpl', () {
    late SecureFileStorage secureStorage;
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoServiceImpl(
        pbkdf2Iterations: 1000,
        keyLength: 32,
        saltLength: 16,
      );
      secureStorage = SecureFileStorageImpl(cryptoService);
    });

    tearDown(() async {
      await secureStorage.cleanupTempFiles();
    });

    group('storeFile and retrieveFile', () {
      test('should store and retrieve file correctly', () async {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final fileUuid = await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test.jpg',
        );

        final retrieved = await secureStorage.retrieveFile(fileUuid);

        expect(retrieved, isNotNull);
        expect(retrieved!.length, equals(data.length));
        expect(retrieved, equals(data));
      });

      test('should store file with UUID naming', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        final fileUuid = await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test.jpg',
        );

        // UUID should be in v4 format
        expect(fileUuid, matches(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));
      });

      test('should store file with subType', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        final fileUuid = await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          subType: 'thumbnail',
          data: data,
          originalFileName: 'test.jpg',
        );

        final metadata = await secureStorage.getFileMetadata(fileUuid);

        expect(metadata, isNotNull);
        expect(metadata!.subType, equals('thumbnail'));
      });

      test('should return null for non-existent file', () async {
        final retrieved = await secureStorage.retrieveFile('non-existent-uuid');
        expect(retrieved, isNull);
      });

      test('should handle large files', () async {
        final data = Uint8List.fromList(List.generate(100000, (i) => i % 256));
        final fileUuid = await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'large.jpg',
        );

        final retrieved = await secureStorage.retrieveFile(fileUuid);

        expect(retrieved, isNotNull);
        expect(retrieved!.length, equals(data.length));
      });
    });

    group('deleteFile', () {
      test('should delete existing file', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        final fileUuid = await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test.jpg',
        );

        await secureStorage.deleteFile(fileUuid);

        final retrieved = await secureStorage.retrieveFile(fileUuid);
        expect(retrieved, isNull);
      });

      test('should handle deleting non-existent file', () async {
        await secureStorage.deleteFile('non-existent-uuid');
        // Should not throw
        expect(() async => await secureStorage.deleteFile('non-existent-uuid'), returnsNormally);
      });
    });

    group('deleteVaultFiles', () {
      test('should delete all files for a vault', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test1.jpg',
        );
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'video',
          data: data,
          originalFileName: 'test2.mp4',
        );

        await secureStorage.deleteVaultFiles('test-vault');

        final files = await secureStorage.listVaultFiles('test-vault');
        expect(files, isEmpty);
      });

      test('should handle deleting non-existent vault', () async {
        await secureStorage.deleteVaultFiles('non-existent-vault');
        // Should not throw
        expect(() async => await secureStorage.deleteVaultFiles('non-existent-vault'), returnsNormally);
      });
    });

    group('deleteVaultFilesByType', () {
      test('should delete files by type for a vault', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test1.jpg',
        );
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test2.jpg',
        );
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'video',
          data: data,
          originalFileName: 'test3.mp4',
        );

        await secureStorage.deleteVaultFilesByType('test-vault', 'photo');

        final photos = await secureStorage.listVaultFilesByType('test-vault', 'photo');
        final videos = await secureStorage.listVaultFilesByType('test-vault', 'video');
        
        expect(photos, isEmpty);
        expect(videos, hasLength(1));
      });
    });

    group('getFileMetadata', () {
      test('should return file metadata', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        final fileUuid = await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test.jpg',
        );

        final metadata = await secureStorage.getFileMetadata(fileUuid);

        expect(metadata, isNotNull);
        expect(metadata!.uuid, equals(fileUuid));
        expect(metadata.vaultId, equals('test-vault'));
        expect(metadata.type, equals('photo'));
        expect(metadata.size, equals(data.length));
      });

      test('should return null for non-existent file', () async {
        final metadata = await secureStorage.getFileMetadata('non-existent-uuid');
        expect(metadata, isNull);
      });
    });

    group('listVaultFiles', () {
      test('should list all files for a vault', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test1.jpg',
        );
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'video',
          data: data,
          originalFileName: 'test2.mp4',
        );

        final files = await secureStorage.listVaultFiles('test-vault');

        expect(files, hasLength(2));
      });

      test('should return empty list for non-existent vault', () async {
        final files = await secureStorage.listVaultFiles('non-existent-vault');
        expect(files, isEmpty);
      });
    });

    group('listVaultFilesByType', () {
      test('should list files by type for a vault', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test1.jpg',
        );
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data,
          originalFileName: 'test2.jpg',
        );
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'video',
          data: data,
          originalFileName: 'test3.mp4',
        );

        final photos = await secureStorage.listVaultFilesByType('test-vault', 'photo');
        final videos = await secureStorage.listVaultFilesByType('test-vault', 'video');
        
        expect(photos, hasLength(2));
        expect(videos, hasLength(1));
      });
    });

    group('getVaultStorageSize', () {
      test('should calculate vault storage size', () async {
        final data1 = Uint8List.fromList(List.generate(100, (i) => i));
        final data2 = Uint8List.fromList(List.generate(200, (i) => i));
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'photo',
          data: data1,
          originalFileName: 'test1.jpg',
        );
        
        await secureStorage.storeFile(
          vaultId: 'test-vault',
          type: 'video',
          data: data2,
          originalFileName: 'test2.mp4',
        );

        final size = await secureStorage.getVaultStorageSize('test-vault');

        expect(size, equals(300));
      });

      test('should return 0 for non-existent vault', () async {
        final size = await secureStorage.getVaultStorageSize('non-existent-vault');
        expect(size, equals(0));
      });
    });

    group('cleanupTempFiles', () {
      test('should clean up temporary files', () async {
        await secureStorage.cleanupTempFiles();
        // Should not throw
        expect(() async => await secureStorage.cleanupTempFiles(), returnsNormally);
      });
    });
  });
}
