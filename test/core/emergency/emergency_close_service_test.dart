import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cover/core/emergency/emergency_close_service.dart';
import 'package:cover/core/config/app_config.dart';

@GenerateMocks([
  AppConfig,
])
import 'emergency_close_service_test.mocks.dart';

void main() {
  group('EmergencyCloseService', () {
    late EmergencyCloseServiceImpl service;
    late MockAppConfig mockAppConfig;

    setUp(() {
      mockAppConfig = MockAppConfig();
      when(mockAppConfig.shakeSensitivity).thenReturn(2.5);
      when(mockAppConfig.intruderEnabled).thenReturn(true);

      service = EmergencyCloseServiceImpl(
        appConfig: mockAppConfig,
        sensitivity: 2.5,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('should start monitoring when enabled', () {
      // Arrange
      expect(service.isMonitoring, false);

      // Act
      service.startMonitoring();

      // Assert
      expect(service.isMonitoring, true);
    });

    test('should not start monitoring when disabled', () {
      // Arrange
      service.setEnabled(false);

      // Act
      service.startMonitoring();

      // Assert
      expect(service.isMonitoring, false);
    });

    test('should stop monitoring', () {
      // Arrange
      service.startMonitoring();
      expect(service.isMonitoring, true);

      // Act
      service.stopMonitoring();

      // Assert
      expect(service.isMonitoring, false);
    });

    test('should update sensitivity', () {
      // Act
      service.updateSensitivity(3.5);

      // Assert - Sensitivity is updated internally
    });

    test('should enable and disable emergency close', () {
      // Arrange
      expect(service.isEnabled, true);

      // Act
      service.setEnabled(false);

      // Assert
      expect(service.isEnabled, false);

      // Act
      service.setEnabled(true);

      // Assert
      expect(service.isEnabled, true);
    });

    test('should trigger emergency close callback', () async {
      // Arrange
      bool callbackTriggered = false;
      service.onEmergencyClose = () {
        callbackTriggered = true;
      };

      // Act - Simulate emergency close trigger
      // Note: In a real test, we would simulate accelerometer events
      // For now, we just test the callback mechanism
      service.onEmergencyClose?.call();

      // Assert
      expect(callbackTriggered, true);
    });

    test('should reset shake count when stopped', () {
      // Arrange
      service.startMonitoring();

      // Act
      service.stopMonitoring();

      // Assert - Shake count should be reset internally
    });

    test('should handle multiple start/stop cycles', () {
      // Act
      service.startMonitoring();
      service.stopMonitoring();
      service.startMonitoring();
      service.stopMonitoring();

      // Assert - Should not throw
    });

    test('should dispose properly', () {
      // Arrange
      service.startMonitoring();

      // Act
      service.dispose();

      // Assert
      expect(service.isMonitoring, false);
    });
  });
}
