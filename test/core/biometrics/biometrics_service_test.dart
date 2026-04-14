import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cover/core/biometrics/biometrics_service.dart';
import 'package:cover/core/config/app_config.dart';

@GenerateMocks([
  AppConfig,
  LocalAuthentication,
])
import 'biometrics_service_test.mocks.dart';

void main() {
  group('BiometricsService', () {
    late BiometricsServiceImpl service;
    late MockAppConfig mockAppConfig;
    late MockLocalAuthentication mockLocalAuth;

    setUp(() {
      mockAppConfig = MockAppConfig();
      mockLocalAuth = MockLocalAuthentication();
      
      when(mockAppConfig.biometricsEnabled).thenReturn(true);
      when(mockAppConfig.biometricsPromptVariant).thenReturn('after_first_unlock');

      service = BiometricsServiceImpl(
        localAuth: mockLocalAuth,
        appConfig: mockAppConfig,
      );
    });

    test('should check if biometrics is available', () async {
      // Arrange
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);

      // Act
      final result = await service.isAvailable();

      // Assert
      expect(result, true);
      verify(mockLocalAuth.canCheckBiometrics).called(1);
      verify(mockLocalAuth.getAvailableBiometrics()).called(1);
    });

    test('should return false when biometrics not available', () async {
      // Arrange
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

      // Act
      final result = await service.isAvailable();

      // Assert
      expect(result, false);
    });

    test('should enable and disable biometrics', () async {
      // Arrange
      expect(service.isEnabled, false);

      // Act
      await service.setEnabled(true);

      // Assert
      expect(service.isEnabled, true);

      // Act
      await service.setEnabled(false);

      // Assert
      expect(service.isEnabled, false);
    });

    test('should authenticate successfully', () async {
      // Arrange
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        useErrorDialogs: anyNamed('useErrorDialogs'),
        stickyAuth: anyNamed('stickyAuth'),
        biometricOnly: anyNamed('biometricOnly'),
      )).thenAnswer((_) async => true);

      // Act
      final result = await service.authenticate();

      // Assert
      expect(result, true);
      verify(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        useErrorDialogs: anyNamed('useErrorDialogs'),
        stickyAuth: anyNamed('stickyAuth'),
        biometricOnly: anyNamed('biometricOnly'),
      )).called(1);
    });

    test('should return false when authentication fails', () async {
      // Arrange
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        useErrorDialogs: anyNamed('useErrorDialogs'),
        stickyAuth: anyNamed('stickyAuth'),
        biometricOnly: anyNamed('biometricOnly'),
      )).thenAnswer((_) async => false);

      // Act
      final result = await service.authenticate();

      // Assert
      expect(result, false);
    });

    test('should return false when authentication throws error', () async {
      // Arrange
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        useErrorDialogs: anyNamed('useErrorDialogs'),
        stickyAuth: anyNamed('stickyAuth'),
        biometricOnly: anyNamed('biometricOnly'),
      )).thenThrow(Exception('Authentication error'));

      // Act
      final result = await service.authenticate();

      // Assert
      expect(result, false);
    });

    test('should get available biometrics', () async {
      // Arrange
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint, BiometricType.face]);

      // Act
      final result = await service.getAvailableBiometrics();

      // Assert
      expect(result.length, 2);
      expect(result, contains(BiometricType.fingerprint));
      expect(result, contains(BiometricType.face));
    });

    test('should check if specific biometric type is available', () async {
      // Arrange
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);

      // Act
      final result = await service.hasBiometricType(BiometricType.fingerprint);

      // Assert
      expect(result, true);
    });

    test('should return false for unavailable biometric type', () async {
      // Arrange
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.fingerprint]);

      // Act
      final result = await service.hasBiometricType(BiometricType.face);

      // Assert
      expect(result, false);
    });

    test('should get correct prompt variant', () {
      // Act
      final variant = service.promptVariant;

      // Assert
      expect(variant, BiometricPromptVariant.afterFirstUnlock);
    });

    test('should set prompt variant', () {
      // Act
      service.setPromptVariant(BiometricPromptVariant.onDemand);

      // Assert
      expect(service.promptVariant, BiometricPromptVariant.onDemand);
    });

    test('should get biometric type name', () {
      // Act
      final faceName = service.getBiometricTypeName(BiometricType.face);
      final fingerprintName = service.getBiometricTypeName(BiometricType.fingerprint);

      // Assert
      expect(faceName, 'Face ID');
      expect(fingerprintName, 'Fingerprint');
    });
  });
}
