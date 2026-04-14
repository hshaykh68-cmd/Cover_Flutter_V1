import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/utils/logger.dart';

/// Service for checking feature gates controlled by Remote Config
/// Provides a clean interface for feature flag checks throughout the app
class FeatureGating {
  final AppConfig _config;

  FeatureGating(this._config);

  // ========== Security Features ==========
  bool get lockOnBackground => _config.lockOnBackground;
  bool get denyScreenshots => _config.denyScreenshotsAndroid;
  bool get blurAppSwitcher => _config.blurAppSwitcherIos;

  // ========== Calculator Features ==========
  bool get advancedCalculator => _config.enableAdvancedCalculator;

  // ========== Tab Features ==========
  bool get isGalleryEnabled => _config.galleryTabEnabled;
  bool get isFilesEnabled => _config.filesTabEnabled;
  bool get isNotesEnabled => _config.notesTabEnabled;
  bool get isPasswordsEnabled => _config.passwordsTabEnabled;
  bool get isContactsEnabled => _config.contactsTabEnabled;

  /// Check if any tab is enabled
  bool get isAnyTabEnabled =>
      isGalleryEnabled || isFilesEnabled || isNotesEnabled || isPasswordsEnabled || isContactsEnabled;

  // ========== Content Features ==========
  bool get isNotesFeatureEnabled => _config.notesEnabled;
  bool get isPasswordsFeatureEnabled => _config.passwordsEnabled;
  bool get isContactsFeatureEnabled => _config.contactsEnabled;

  // ========== Intruder Defense Features ==========
  bool get isIntruderDetectionEnabled => _config.intruderEnabled;
  bool get isScreenshotDetectionEnabled => _config.enableScreenshotDetection;
  bool get isLocationCaptureEnabled => _config.locationTimeoutSeconds > 0;

  // ========== Biometrics Features ==========
  bool get isBiometricsEnabled => _config.biometricsEnabled;

  /// Check if biometrics should prompt on first unlock
  bool get shouldPromptBiometricsOnFirstUnlock =>
      _config.biometricsPromptVariant == 'after_first_unlock';

  /// Check if biometrics is behind a paywall
  bool get isBiometricsPaywalled => _config.biometricsPaywallVariant != 'none';

  // ========== Monetization Features ==========
  bool get areAdsEnabled => _config.bannerEnabled || _config.interstitialEnabled || _config.rewardedEnabled;
  bool get isBannerAdEnabled => _config.bannerEnabled;
  bool get isInterstitialAdEnabled => _config.interstitialEnabled;
  bool get isRewardedAdEnabled => _config.rewardedEnabled;

  // ========== System Features ==========
  bool get isHapticFeedbackEnabled => _config.enableHapticFeedback;
  bool get isTutorialEnabled => _config.showTutorialOnFirstLaunch;
  bool get isRealtimeConfigEnabled => _config.enableRealtimeConfig;

  // ========== Import/Export Features ==========
  int get maxImportBatchSize => _config.maxImportBatchSize;
  int get thumbnailQuality => _config.thumbnailQuality;

  /// Check if the app should be disabled via kill switch
  bool get isAppDisabled => _config.isAppDisabled;

  /// Log feature gate status for debugging
  void logFeatureStatus() {
    AppLogger.info('=== Feature Gating Status ===');
    AppLogger.info('Gallery Tab: ${isGalleryEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Files Tab: ${isFilesEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Notes Tab: ${isNotesEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Passwords Tab: ${isPasswordsEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Contacts Tab: ${isContactsEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Intruder Detection: ${isIntruderDetectionEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Biometrics: ${isBiometricsEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Ads: ${areAdsEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('App Disabled: ${isAppDisabled ? "YES" : "NO"}');
    AppLogger.info('============================');
  }

  /// Get list of disabled features for user feedback
  List<String> getDisabledFeatures() {
    final disabled = <String>[];
    if (!isGalleryEnabled) disabled.add('Gallery');
    if (!isFilesEnabled) disabled.add('Files');
    if (!isNotesEnabled) disabled.add('Notes');
    if (!isPasswordsEnabled) disabled.add('Passwords');
    if (!isContactsEnabled) disabled.add('Contacts');
    if (!isIntruderDetectionEnabled) disabled.add('Intruder Detection');
    if (!isBiometricsEnabled) disabled.add('Biometrics');
    return disabled;
  }
}
