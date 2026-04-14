import 'package:cover/domain/repository/remote_config_repository.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cover/core/utils/logger.dart';

class RemoteConfigRepositoryImpl implements RemoteConfigRepository {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigRepositoryImpl(this._remoteConfig);

  @override
  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(_getDefaultValues());
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 15),
      ));
      await fetchAndActivate();
      AppLogger.info('Remote Config initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Remote Config', e, stackTrace);
      // App will use default values if fetch fails
    }
  }

  @override
  Future<void> fetchAndActivate() async {
    try {
      final fetched = await _remoteConfig.fetch();
      if (fetched) {
        await _remoteConfig.activate();
        AppLogger.info('Remote Config fetched and activated');
      } else {
        AppLogger.info('Remote Config using cached values');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch Remote Config', e, stackTrace);
      // Use cached values if fetch fails
    }
  }

  /// Fetch with retry logic
  Future<void> fetchWithRetry({int maxRetries = 3}) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        await fetchAndActivate();
        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          AppLogger.error('Remote Config fetch failed after $maxRetries retries');
          rethrow;
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  /// Check if config needs refresh based on fetch interval
  bool needsRefresh(DateTime lastFetchTime) {
    final interval = Duration(minutes: _remoteConfig.getInt('config_fetch_interval_minutes', 60));
    return DateTime.now().difference(lastFetchTime) > interval;
  }

  @override
  T getValue<T>(String key, T defaultValue) {
    switch (T) {
      case bool:
        return _remoteConfig.getBool(key) as T;
      case int:
        return _remoteConfig.getInt(key) as T;
      case double:
        return _remoteConfig.getDouble(key) as T;
      case String:
        return _remoteConfig.getString(key) as T;
      default:
        return defaultValue;
    }
  }

  @override
  bool getBool(String key, bool defaultValue) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  int getInt(String key, int defaultValue) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  double getDouble(String key, double defaultValue) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  String getString(String key, String defaultValue) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      return defaultValue;
    }
  }

  Map<String, dynamic> _getDefaultValues() {
    return {
      // Security
      'encryption_algorithm': 'AES-256-GCM',
      'key_derivation_iterations': 100000,
      'min_pin_length': 4,
      'max_pin_length': 12,
      'lock_on_background': true,
      'auto_lock_inactivity_seconds': 30,
      'clipboard_timeout_seconds': 20,
      'deny_screenshots_android': true,
      'blur_app_switcher_ios': true,

      // Calculator
      'pin_pattern': '{pin}+0=',
      'decoy_pin_pattern': '{pin}+1=',
      'enable_advanced_calculator': true,
      'calculator_style': 'ios',
      'max_pin_attempts_before_lockout': 3,
      'lockout_duration_minutes': 15,

      // Navigation/UI
      'bottom_nav_style': 'labeled',
      'animation_duration_ms': 300,
      'enable_haptic_feedback': true,
      'vault_grid_columns': 3,
      'show_tutorial_on_first_launch': true,
      'tabs_enabled_gallery': true,
      'tabs_enabled_files': true,
      'tabs_enabled_notes': true,
      'tabs_enabled_passwords': true,
      'tabs_enabled_contacts': true,

      // Media
      'thumbnail_quality': 80,
      'max_import_batch_size': 100,
      'secure_delete_passes': 3,

      // Notes
      'notes_enabled': true,
      'notes_search_mode': 'title_only',

      // Passwords
      'passwords_enabled': true,
      'password_generator_min': 12,
      'password_generator_max': 32,

      // Contacts
      'contacts_enabled': true,
      'contacts_allow_external_intents': false,

      // Intruder
      'intruder_enabled': true,
      'max_attempts_before_capture': 2,
      'capture_count_per_attempt': 2,
      'location_timeout_seconds': 5,
      'enable_screenshot_detection': true,
      'shake_sensitivity': 2.5,

      // Biometrics
      'biometrics_enabled': true,
      'biometrics_prompt_variant': 'after_first_unlock',
      'biometrics_paywall_variant': 'none',

      // Monetization
      'max_free_items': 50,
      'max_free_vaults': 1,
      'upsell_trigger_items_remaining': 10,
      'upsell_trigger_after_days': 3,
      'banner_enabled': true,
      'interstitial_enabled': true,
      'rewarded_enabled': true,
      'interstitial_min_interval_minutes': 10,

      // System
      'config_fetch_interval_minutes': 60,
      'config_minimum_fetch_interval': 15,
      'enable_realtime_config': true,
      'config_version': '1.0.0',
      'kill_switch_app_disabled': false,
    };
  }
}
