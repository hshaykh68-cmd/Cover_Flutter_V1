import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';

/// Biometrics service interface
/// 
/// Manages biometric authentication for vault unlock
abstract class BiometricsService {
  /// Check if biometrics is available on the device
  Future<bool> isAvailable();

  /// Check if biometrics is enabled for the user
  bool get isEnabled;

  /// Enable or disable biometrics
  Future<void> setEnabled(bool enabled);

  /// Authenticate using biometrics
  /// 
  /// Returns true if authentication succeeded
  Future<bool> authenticate({
    String? localizedReason,
    bool stickyAuth = false,
    bool biometricOnly = false,
  });

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics();

  /// Check if device has specific biometric type
  Future<bool> hasBiometricType(BiometricType type);

  /// Get the biometric prompt variant from RC
  BiometricPromptVariant get promptVariant;

  /// Update biometric prompt variant
  void setPromptVariant(BiometricPromptVariant variant);
}

/// Biometric prompt variants for A/B testing
enum BiometricPromptVariant {
  /// Prompt immediately after first unlock
  afterFirstUnlock,
  /// Prompt only when explicitly requested
  onDemand,
  /// Prompt with explanation screen
  withExplanation,
}

/// Biometrics service implementation
class BiometricsServiceImpl implements BiometricsService {
  final LocalAuthentication _localAuth;
  final AppConfig _appConfig;
  
  bool _enabled = false;
  BiometricPromptVariant _promptVariant = BiometricPromptVariant.afterFirstUnlock;

  BiometricsServiceImpl({
    required LocalAuthentication localAuth,
    required AppConfig appConfig,
  }) : _localAuth = localAuth,
        _appConfig = appConfig {
    _promptVariant = _getPromptVariantFromConfig();
  }

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    AppLogger.info('Biometrics ${enabled ? "enabled" : "disabled"}');
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check biometrics availability', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> authenticate({
    String? localizedReason,
    bool stickyAuth = false,
    bool biometricOnly = false,
  }) async {
    if (!_enabled) {
      return false;
    }

    try {
      final reason = localizedReason ?? _getLocalizedReason();

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        stickyAuth: stickyAuth,
        biometricOnly: biometricOnly,
      );

      if (didAuthenticate) {
        HapticFeedback.mediumImpact();
        AppLogger.info('Biometric authentication succeeded');
      } else {
        AppLogger.warning('Biometric authentication failed');
      }

      return didAuthenticate;
    } catch (e, stackTrace) {
      AppLogger.error('Biometric authentication error', e, stackTrace);
      return false;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get available biometrics', e, stackTrace);
      return [];
    }
  }

  @override
  Future<bool> hasBiometricType(BiometricType type) async {
    try {
      final available = await getAvailableBiometrics();
      return available.contains(type);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check biometric type', e, stackTrace);
      return false;
    }
  }

  @override
  BiometricPromptVariant get promptVariant => _promptVariant;

  @override
  void setPromptVariant(BiometricPromptVariant variant) {
    _promptVariant = variant;
    AppLogger.info('Biometric prompt variant set to $variant');
  }

  String _getLocalizedReason() {
    switch (_promptVariant) {
      case BiometricPromptVariant.afterFirstUnlock:
        return 'Authenticate to unlock your vault';
      case BiometricPromptVariant.onDemand:
        return 'Authenticate to access';
      case BiometricPromptVariant.withExplanation:
        return 'Use your fingerprint or face to securely unlock your vault';
    }
  }

  BiometricPromptVariant _getPromptVariantFromConfig() {
    final variant = _appConfig.biometricsPromptVariant;
    
    switch (variant) {
      case 'after_first_unlock':
        return BiometricPromptVariant.afterFirstUnlock;
      case 'on_demand':
        return BiometricPromptVariant.onDemand;
      case 'with_explanation':
        return BiometricPromptVariant.withExplanation;
      default:
        return BiometricPromptVariant.afterFirstUnlock;
    }
  }

  /// Get user-friendly name for biometric type
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
      case BiometricType.strong:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.none:
        return 'None';
      default:
        return 'Biometrics';
    }
  }

  /// Get platform-specific biometric name
  String getPlatformBiometricName() {
    if (Platform.isIOS) {
      return 'Face ID';
    } else if (Platform.isAndroid) {
      return 'Fingerprint';
    }
    return 'Biometrics';
  }
}
