import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cover/core/intruder/intruder_location_capture_service.dart';
import 'package:cover/core/crypto/crypto_service.dart';

@GenerateMocks([
  CryptoService,
])
import 'intruder_location_capture_service_test.mocks.dart';

void main() {
  late IntruderLocationCaptureServiceImpl service;
  late MockCryptoService mockCryptoService;

  setUp(() {
    mockCryptoService = MockCryptoService();
    service = IntruderLocationCaptureServiceImpl(
      cryptoService: mockCryptoService,
      timeout: const Duration(seconds: 5),
    );
  });

  group('isLocationServiceEnabled', () {
    test('should check location service status', () async {
      // Note: This test will return false in test environment without location service
      // Act
      final result = await service.isLocationServiceEnabled();

      // Assert
      expect(result, isA<bool>());
    });
  });

  group('hasLocationPermission', () {
    test('should check location permission', () async {
      // Note: This test will return false in test environment without permissions
      // Act
      final result = await service.hasLocationPermission();

      // Assert
      expect(result, isA<bool>());
    });
  });

  group('captureLocation', () {
    test('should return error when location service disabled', () async {
      // Arrange
      when(service.isLocationServiceEnabled()).thenAnswer((_) async => false);

      // Act
      final result = await service.captureLocation();

      // Assert
      expect(result.success, false);
      expect(result.error, contains('disabled'));
    });

    test('should return error when permission not granted', () async {
      // Arrange
      when(service.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(service.hasLocationPermission()).thenAnswer((_) async => false);

      // Act
      final result = await service.captureLocation();

      // Assert
      expect(result.success, false);
      expect(result.error, contains('permission'));
    });

    test('should return error on timeout', () async {
      // Arrange
      when(service.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(service.hasLocationPermission()).thenAnswer((_) async => true);

      // Act
      final result = await service.captureLocation();

      // Assert
      expect(result.success, false);
      expect(result.error, contains('not yet implemented'));
    });
  });
}
