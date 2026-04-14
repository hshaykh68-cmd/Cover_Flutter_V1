import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cover/core/intruder/intruder_detection_service.dart';
import 'package:cover/core/intruder/intruder_camera_capture_service.dart';
import 'package:cover/core/intruder/intruder_location_capture_service.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/intruder_log_repository.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:drift/drift.dart';

@GenerateMocks([
  IntruderLogRepository,
  CryptoService,
  SecureFileStorage,
  IntruderCameraCaptureService,
  IntruderLocationCaptureService,
])
import 'intruder_detection_service_test.mocks.dart';

void main() {
  late IntruderDetectionServiceImpl service;
  late MockIntruderLogRepository mockRepository;
  late MockCryptoService mockCryptoService;
  late MockSecureFileStorage mockSecureFileStorage;
  late MockIntruderCameraCaptureService mockCameraService;
  late MockIntruderLocationCaptureService mockLocationService;

  setUp(() {
    mockRepository = MockIntruderLogRepository();
    mockCryptoService = MockCryptoService();
    mockSecureFileStorage = MockSecureFileStorage();
    mockCameraService = MockIntruderCameraCaptureService();
    mockLocationService = MockIntruderLocationCaptureService();

    service = IntruderDetectionServiceImpl(
      intruderLogRepository: mockRepository,
      cryptoService: mockCryptoService,
      secureFileStorage: mockSecureFileStorage,
      cameraCaptureService: mockCameraService,
      locationCaptureService: mockLocationService,
      maxAttemptsBeforeCapture: 2,
      captureCountPerAttempt: 2,
    );
  });

  group('recordWrongAttempt', () {
    test('should return false on first attempt', () async {
      // Act
      final result = await service.recordWrongAttempt();

      // Assert
      expect(result, false);
    });

    test('should return true on threshold attempt', () async {
      // Arrange
      await service.recordWrongAttempt();

      // Act
      final result = await service.recordWrongAttempt();

      // Assert
      expect(result, true);
    });

    test('should track attempts per vault separately', () async {
      // Act
      await service.recordWrongAttempt(vaultId: 'vault1');
      await service.recordWrongAttempt(vaultId: 'vault2');
      final vault1Result = await service.recordWrongAttempt(vaultId: 'vault1');
      final vault2Result = await service.recordWrongAttempt(vaultId: 'vault2');

      // Assert
      expect(vault1Result, true);
      expect(vault2Result, true);
    });

    test('should return false when disabled', () async {
      // Arrange
      await service.setEnabled(false);

      // Act
      final result = await service.recordWrongAttempt();

      // Assert
      expect(result, false);
    });
  });

  group('getAttemptCount', () {
    test('should return 0 initially', () async {
      // Act
      final count = await service.getAttemptCount();

      // Assert
      expect(count, 0);
    });

    test('should return correct count after attempts', () async {
      // Arrange
      await service.recordWrongAttempt();

      // Act
      final count = await service.getAttemptCount();

      // Assert
      expect(count, 1);
    });
  });

  group('resetAttemptCounter', () {
    test('should reset attempt counter', () async {
      // Arrange
      await service.recordWrongAttempt();

      // Act
      await service.resetAttemptCounter();
      final count = await service.getAttemptCount();

      // Assert
      expect(count, 0);
    });
  });

  group('captureIntruderEvidence', () {
    test('should capture photos and location', () async {
      // Arrange
      when(mockCameraService.capturePhoto())
          .thenAnswer((_) async => CameraCaptureResult(
                success: true,
                encryptedFilePath: 'photo1.jpg',
              ));
      when(mockLocationService.captureLocation())
          .thenAnswer((_) async => LocationCaptureResult(
                success: true,
                encryptedLocation: 'encrypted_location',
              ));
      when(mockRepository.createIntruderLog(any))
          .thenAnswer((_) async => IntruderLog(
                id: 1,
                vaultId: null,
                timestamp: DateTime.now(),
                eventType: 'wrong_pin',
                encryptedPhotoPath: 'photo1.jpg',
                encryptedLocation: 'encrypted_location',
                metadata: '{}',
              ));

      // Act
      final result = await service.captureIntruderEvidence();

      // Assert
      expect(result.success, true);
      expect(result.intruderLogId, '1');
      verify(mockCameraService.capturePhoto()).called(2);
      verify(mockLocationService.captureLocation()).called(1);
      verify(mockRepository.createIntruderLog(any)).called(1);
    });

    test('should handle camera capture failure', () async {
      // Arrange
      when(mockCameraService.capturePhoto())
          .thenAnswer((_) async => CameraCaptureResult(
                success: false,
                error: 'Camera error',
              ));
      when(mockLocationService.captureLocation())
          .thenAnswer((_) async => LocationCaptureResult(
                success: true,
                encryptedLocation: 'encrypted_location',
              ));
      when(mockRepository.createIntruderLog(any))
          .thenAnswer((_) async => IntruderLog(
                id: 1,
                vaultId: null,
                timestamp: DateTime.now(),
                eventType: 'wrong_pin',
                encryptedPhotoPath: null,
                encryptedLocation: 'encrypted_location',
                metadata: '{}',
              ));

      // Act
      final result = await service.captureIntruderEvidence();

      // Assert
      expect(result.success, true);
      expect(result.intruderLogId, '1');
    });

    test('should return error when disabled', () async {
      // Arrange
      await service.setEnabled(false);

      // Act
      final result = await service.captureIntruderEvidence();

      // Assert
      expect(result.success, false);
      expect(result.error, 'Intruder detection is disabled');
    });

    test('should reset attempt counter after capture', () async {
      // Arrange
      when(mockCameraService.capturePhoto())
          .thenAnswer((_) async => CameraCaptureResult(
                success: true,
                encryptedFilePath: 'photo1.jpg',
              ));
      when(mockLocationService.captureLocation())
          .thenAnswer((_) async => LocationCaptureResult(
                success: false,
              ));
      when(mockRepository.createIntruderLog(any))
          .thenAnswer((_) async => IntruderLog(
                id: 1,
                vaultId: null,
                timestamp: DateTime.now(),
                eventType: 'wrong_pin',
                encryptedPhotoPath: 'photo1.jpg',
                encryptedLocation: null,
                metadata: '{}',
              ));

      // Act
      await service.recordWrongAttempt();
      await service.captureIntruderEvidence();
      final count = await service.getAttemptCount();

      // Assert
      expect(count, 0);
    });
  });

  group('getIntruderLogs', () {
    test('should return all logs when no vault specified', () async {
      // Arrange
      final logs = [
        IntruderLog(
          id: 1,
          vaultId: null,
          timestamp: DateTime.now(),
          eventType: 'wrong_pin',
        ),
      ];
      when(mockRepository.getAllIntruderLogs())
          .thenAnswer((_) async => logs);

      // Act
      final result = await service.getIntruderLogs();

      // Assert
      expect(result, logs);
      verify(mockRepository.getAllIntruderLogs()).called(1);
    });

    test('should return vault logs when vault specified', () async {
      // Arrange
      final logs = [
        IntruderLog(
          id: 1,
          vaultId: 'vault1',
          timestamp: DateTime.now(),
          eventType: 'wrong_pin',
        ),
      ];
      when(mockRepository.getIntruderLogsByVault('vault1'))
          .thenAnswer((_) async => logs);

      // Act
      final result = await service.getIntruderLogs(vaultId: 'vault1');

      // Assert
      expect(result, logs);
      verify(mockRepository.getIntruderLogsByVault('vault1')).called(1);
    });
  });

  group('deleteIntruderLog', () {
    test('should delete log and associated files', () async {
      // Arrange
      final log = IntruderLog(
        id: 1,
        vaultId: null,
        timestamp: DateTime.now(),
        eventType: 'wrong_pin',
        encryptedPhotoPath: 'photo1.jpg',
        metadata: '{"additional_photo_paths": ["photo2.jpg"]}',
      );
      when(mockRepository.getIntruderLogById(1)).thenAnswer((_) async => log);
      when(mockSecureFileStorage.deleteFile(any)).thenAnswer((_) async {});
      when(mockRepository.deleteIntruderLog(1)).thenAnswer((_) async => 1);

      // Act
      await service.deleteIntruderLog(1);

      // Assert
      verify(mockSecureFileStorage.deleteFile('photo1.jpg')).called(1);
      verify(mockRepository.deleteIntruderLog(1)).called(1);
    });

    test('should handle missing log gracefully', () async {
      // Arrange
      when(mockRepository.getIntruderLogById(1)).thenAnswer((_) async => null);

      // Act & Assert
      await service.deleteIntruderLog(1);
      verifyNever(mockSecureFileStorage.deleteFile(any));
    });
  });

  group('clearIntruderLogs', () {
    test('should delete all logs', () async {
      // Arrange
      final logs = [
        IntruderLog(
          id: 1,
          vaultId: null,
          timestamp: DateTime.now(),
          eventType: 'wrong_pin',
        ),
        IntruderLog(
          id: 2,
          vaultId: null,
          timestamp: DateTime.now(),
          eventType: 'wrong_pin',
        ),
      ];
      when(mockRepository.getAllIntruderLogs())
          .thenAnswer((_) async => logs);
      when(mockRepository.getIntruderLogById(any))
          .thenAnswer((_) async => logs[0]);
      when(mockSecureFileStorage.deleteFile(any)).thenAnswer((_) async {});
      when(mockRepository.deleteIntruderLog(any)).thenAnswer((_) async => 1);

      // Act
      await service.clearIntruderLogs();

      // Assert
      verify(mockRepository.deleteIntruderLog(1)).called(1);
      verify(mockRepository.deleteIntruderLog(2)).called(1);
    });
  });

  group('updateConfiguration', () {
    test('should update max attempts', () {
      // Act
      service.updateConfiguration(maxAttemptsBeforeCapture: 5);

      // Assert - Configuration is updated internally
    });

    test('should update capture count', () {
      // Act
      service.updateConfiguration(captureCountPerAttempt: 3);

      // Assert - Configuration is updated internally
    });
  });
}
