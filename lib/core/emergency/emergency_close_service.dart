import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';

/// Emergency close service interface
/// 
/// Detects shake gestures and triggers emergency close of the vault
abstract class EmergencyCloseService {
  /// Start monitoring for shake gestures
  void startMonitoring();

  /// Stop monitoring for shake gestures
  void stopMonitoring();

  /// Check if monitoring is active
  bool get isMonitoring;

  /// Callback when emergency close is triggered
  VoidCallback? onEmergencyClose;

  /// Update shake sensitivity
  void updateSensitivity(double sensitivity);

  /// Enable or disable emergency close
  void setEnabled(bool enabled);

  /// Check if emergency close is enabled
  bool get isEnabled;
}

/// Emergency close service implementation
class EmergencyCloseServiceImpl implements EmergencyCloseService {
  final AppConfig _appConfig;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Shake detection parameters
  double _sensitivity = 2.5;
  bool _enabled = true;
  bool _isMonitoring = false;
  
  // Shake detection state
  DateTime? _lastShakeTime;
  static const _shakeCooldown = Duration(milliseconds: 500);
  static const _shakeThreshold = 20.0; // m/s²
  static const _requiredShakeCount = 3;
  int _shakeCount = 0;

  @override
  VoidCallback? onEmergencyClose;

  EmergencyCloseServiceImpl({
    required AppConfig appConfig,
    double? sensitivity,
  }) : _appConfig = appConfig {
    _sensitivity = sensitivity ?? appConfig.shakeSensitivity;
  }

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  bool get isEnabled => _enabled;

  @override
  void setEnabled(bool enabled) {
    _enabled = enabled;
    AppLogger.info('Emergency close ${enabled ? "enabled" : "disabled"}');
    
    if (!enabled && _isMonitoring) {
      stopMonitoring();
    } else if (enabled && !_isMonitoring) {
      startMonitoring();
    }
  }

  @override
  void updateSensitivity(double sensitivity) {
    _sensitivity = sensitivity;
    AppLogger.info('Shake sensitivity updated to $sensitivity');
  }

  @override
  void startMonitoring() {
    if (_isMonitoring || !_enabled) {
      return;
    }

    AppLogger.info('Starting emergency close monitoring');
    _isMonitoring = true;

    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval, // ~60Hz — sufficient for shake
    ).listen(
      _handleAccelerometerEvent,
      onError: (error) {
        AppLogger.error('Accelerometer error', error);
      },
      cancelOnError: false,
    );
  }

  @override
  void stopMonitoring() {
    if (!_isMonitoring) {
      return;
    }

    AppLogger.info('Stopping emergency close monitoring');
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _shakeCount = 0;
    _lastShakeTime = null;
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (!_enabled) {
      return;
    }

    // Calculate total acceleration magnitude
    final acceleration = (event.x * event.x) + (event.y * event.y) + (event.z * event.z);
    final magnitude = acceleration.abs();

    // Adjust threshold based on sensitivity
    final adjustedThreshold = _shakeThreshold / _sensitivity;

    if (magnitude > adjustedThreshold) {
      _handleShakeDetected();
    }
  }

  void _handleShakeDetected() {
    final now = DateTime.now();

    // Check cooldown
    if (_lastShakeTime != null && now.difference(_lastShakeTime!) < _shakeCooldown) {
      return;
    }

    _lastShakeTime = now;
    _shakeCount++;

    AppLogger.debug('Shake detected: $_shakeCount/$_requiredShakeCount');

    // Check if we have enough shakes to trigger emergency close
    if (_shakeCount >= _requiredShakeCount) {
      _triggerEmergencyClose();
      _shakeCount = 0;
      _lastShakeTime = null;
    }

    // Reset count if too much time passes between shakes
    Timer(_shakeCooldown * 2, () {
      if (_shakeCount > 0 && _shakeCount < _requiredShakeCount) {
        _shakeCount = 0;
      }
    });
  }

  void _triggerEmergencyClose() {
    AppLogger.warning('Emergency close triggered by shake gesture');
    
    // Trigger haptic feedback
    HapticFeedback.heavyImpact();
    
    // Call the callback
    onEmergencyClose?.call();
  }

  void dispose() {
    stopMonitoring();
  }
}
