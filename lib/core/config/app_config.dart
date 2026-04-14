import 'package:cover/domain/repository/remote_config_repository.dart';
import 'package:cover/core/utils/logger.dart';

/// Typed configuration wrapper for Remote Config
/// Provides type-safe access to all remote config values with safe defaults
class AppConfig {
  final RemoteConfigRepository _remoteConfig;

  AppConfig(this._remoteConfig);

  // ========== Security Config ==========
  String get encryptionAlgorithm =>
      _remoteConfig.getString('encryption_algorithm', 'AES-256-GCM');

  int get keyDerivationIterations =>
      _remoteConfig.getInt('key_derivation_iterations', 100000);

  int get minPinLength => _remoteConfig.getInt('min_pin_length', 4);

  int get maxPinLength => _remoteConfig.getInt('max_pin_length', 12);

  bool get lockOnBackground =>
      _remoteConfig.getBool('lock_on_background', true);

  int get autoLockInactivitySeconds =>
      _remoteConfig.getInt('auto_lock_inactivity_seconds', 30);

  int get clipboardTimeoutSeconds =>
      _remoteConfig.getInt('clipboard_timeout_seconds', 20);

  bool get denyScreenshotsAndroid =>
      _remoteConfig.getBool('deny_screenshots_android', true);

  bool get blurAppSwitcherIos =>
      _remoteConfig.getBool('blur_app_switcher_ios', true);

  // ========== Calculator Config ==========
  String get pinPattern => _remoteConfig.getString('pin_pattern', '{pin}+0=');

  String get decoyPinPattern =>
      _remoteConfig.getString('decoy_pin_pattern', '{pin}+1=');

  bool get enableAdvancedCalculator =>
      _remoteConfig.getBool('enable_advanced_calculator', true);

  String get calculatorStyle =>
      _remoteConfig.getString('calculator_style', 'ios');

  int get maxPinAttemptsBeforeLockout =>
      _remoteConfig.getInt('max_pin_attempts_before_lockout', 3);

  int get lockoutDurationMinutes =>
      _remoteConfig.getInt('lockout_duration_minutes', 15);

  // ========== Navigation/UI Config ==========
  String get bottomNavStyle =>
      _remoteConfig.getString('bottom_nav_style', 'labeled');

  int get animationDurationMs =>
      _remoteConfig.getInt('animation_duration_ms', 300);

  bool get enableHapticFeedback =>
      _remoteConfig.getBool('enable_haptic_feedback', true);

  int get vaultGridColumns =>
      _remoteConfig.getInt('vault_grid_columns', 3);

  bool get showTutorialOnFirstLaunch =>
      _remoteConfig.getBool('show_tutorial_on_first_launch', true);

  bool get galleryTabEnabled =>
      _remoteConfig.getBool('tabs_enabled_gallery', true);

  bool get filesTabEnabled =>
      _remoteConfig.getBool('tabs_enabled_files', true);

  bool get notesTabEnabled =>
      _remoteConfig.getBool('tabs_enabled_notes', true);

  bool get passwordsTabEnabled =>
      _remoteConfig.getBool('tabs_enabled_passwords', true);

  bool get contactsTabEnabled =>
      _remoteConfig.getBool('tabs_enabled_contacts', true);

  // ========== Media Config ==========
  int get thumbnailQuality =>
      _remoteConfig.getInt('thumbnail_quality', 80);

  int get maxImportBatchSize =>
      _remoteConfig.getInt('max_import_batch_size', 100);

  int get secureDeletePasses =>
      _remoteConfig.getInt('secure_delete_passes', 3);

  // ========== Notes Config ==========
  bool get notesEnabled => _remoteConfig.getBool('notes_enabled', true);

  String get notesSearchMode =>
      _remoteConfig.getString('notes_search_mode', 'title_only');

  // ========== Passwords Config ==========
  bool get passwordsEnabled =>
      _remoteConfig.getBool('passwords_enabled', true);

  int get passwordGeneratorMin =>
      _remoteConfig.getInt('password_generator_min', 12);

  int get passwordGeneratorMax =>
      _remoteConfig.getInt('password_generator_max', 32);

  // ========== Contacts Config ==========
  bool get contactsEnabled =>
      _remoteConfig.getBool('contacts_enabled', true);

  bool get contactsAllowExternalIntents =>
      _remoteConfig.getBool('contacts_allow_external_intents', false);

  // ========== Intruder Config ==========
  bool get intruderEnabled => _remoteConfig.getBool('intruder_enabled', true);
  int get maxAttemptsBeforeCapture => _remoteConfig.getInt('max_attempts_before_capture', 2);
  int get captureCountPerAttempt => _remoteConfig.getInt('capture_count_per_attempt', 2);
  int get locationTimeoutSeconds => _remoteConfig.getInt('location_timeout_seconds', 5);
  bool get enableScreenshotDetection => _remoteConfig.getBool('enable_screenshot_detection', true);
  double get shakeSensitivity => _remoteConfig.getDouble('shake_sensitivity', 2.5);

  // ========== Biometrics Config ==========
  bool get biometricsEnabled =>
      _remoteConfig.getBool('biometrics_enabled', true);

  String get biometricsPromptVariant =>
      _remoteConfig.getString('biometrics_prompt_variant', 'after_first_unlock');

  String get biometricsPaywallVariant =>
      _remoteConfig.getString('biometrics_paywall_variant', 'none');

  // ========== Monetization Config ==========
  int get maxFreeItems => _remoteConfig.getInt('max_free_items', 50);

  int get maxFreeVaults => _remoteConfig.getInt('max_free_vaults', 1);

  int get upsellTriggerItemsRemaining =>
      _remoteConfig.getInt('upsell_trigger_items_remaining', 10);

  int get upsellTriggerAfterDays =>
      _remoteConfig.getInt('upsell_trigger_after_days', 3);

  bool get bannerEnabled => _remoteConfig.getBool('banner_enabled', true);

  bool get interstitialEnabled =>
      _remoteConfig.getBool('interstitial_enabled', true);

  bool get rewardedEnabled => _remoteConfig.getBool('rewarded_enabled', true);

  int get interstitialMinIntervalMinutes =>
      _remoteConfig.getInt('interstitial_min_interval_minutes', 10);

  // ========== Subscription Config ==========
  String get subscriptionMonthlyProductId =>
      _remoteConfig.getString('subscription_monthly_product_id', 'com.cover.subscription.monthly');

  String get subscriptionYearlyProductId =>
      _remoteConfig.getString('subscription_yearly_product_id', 'com.cover.subscription.yearly');

  String get subscriptionLifetimeProductId =>
      _remoteConfig.getString('subscription_lifetime_product_id', 'com.cover.lifetime');

  double get subscriptionMonthlyPriceUsd =>
      _remoteConfig.getDouble('subscription_monthly_price_usd', 1.99);

  double get subscriptionYearlyPriceUsd =>
      _remoteConfig.getDouble('subscription_yearly_price_usd', 9.99);

  double get subscriptionLifetimePriceUsd =>
      _remoteConfig.getDouble('subscription_lifetime_price_usd', 49.99);

  bool get subscriptionDiscountEnabled =>
      _remoteConfig.getBool('subscription_discount_enabled', true);

  String get subscriptionDiscountCountries =>
      _remoteConfig.getString('subscription_discount_countries', 'IN,BD,PK,LK,NP,BT,PH,ID,VN,MM,KH,LA,NG,KE,GH,ET,TZ,UG,EG,MA,BO,HN,NI,SV,GT,UA,UZ');

  double get subscriptionDiscountMultiplier =>
      _remoteConfig.getDouble('subscription_discount_multiplier', 0.5);

  bool get subscriptionWebhookEnabled =>
      _remoteConfig.getBool('subscription_webhook_enabled', true);

  int get subscriptionGracePeriodDays =>
      _remoteConfig.getInt('subscription_grace_period_days', 3);

  bool get subscriptionAutoRenewalEnabled =>
      _remoteConfig.getBool('subscription_auto_renewal_enabled', true);

  // ========== System Config ==========
  int get configFetchIntervalMinutes =>
      _remoteConfig.getInt('config_fetch_interval_minutes', 60);

  int get configMinimumFetchInterval =>
      _remoteConfig.getInt('config_minimum_fetch_interval', 15);

  bool get enableRealtimeConfig =>
      _remoteConfig.getBool('enable_realtime_config', true);

  String get configVersion =>
      _remoteConfig.getString('config_version', '1.0.0');

  bool get killSwitchAppDisabled =>
      _remoteConfig.getBool('kill_switch_app_disabled', false);

  /// Check if the app should be disabled via kill switch
  bool get isAppDisabled => killSwitchAppDisabled;

  /// Log current config values for debugging
  void logConfig() {
    AppLogger.info('=== App Configuration ===');
    AppLogger.info('Config Version: $configVersion');
    AppLogger.info('Kill Switch: ${isAppDisabled ? "DISABLED" : "ENABLED"}');
    AppLogger.info('Encryption: $encryptionAlgorithm');
    AppLogger.info('Max Free Items: $maxFreeItems');
    AppLogger.info('Max Free Vaults: $maxFreeVaults');
    AppLogger.info('Biometrics: ${biometricsEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Intruder Detection: ${intruderEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('Subscription Monthly Price: \$$subscriptionMonthlyPriceUsd');
    AppLogger.info('Subscription Yearly Price: \$$subscriptionYearlyPriceUsd');
    AppLogger.info('Subscription Lifetime Price: \$$subscriptionLifetimePriceUsd');
    AppLogger.info('Regional Discount: ${subscriptionDiscountEnabled ? "ENABLED" : "DISABLED"}');
    AppLogger.info('========================');
  }
}
