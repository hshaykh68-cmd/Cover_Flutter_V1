import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/domain/repository/remote_config_repository.dart';

@GenerateMocks([RemoteConfigRepository])
import 'app_config_test.mocks.dart';

void main() {
  group('AppConfig', () {
    late AppConfig appConfig;
    late MockRemoteConfigRepository mockRemoteConfigRepository;

    setUp(() {
      mockRemoteConfigRepository = MockRemoteConfigRepository();
      appConfig = AppConfig(mockRemoteConfigRepository);
    });

    group('Security Config', () {
      test('should return encryption algorithm', () {
        when(mockRemoteConfigRepository.getString('encryption_algorithm', 'AES-256-GCM'))
            .thenReturn('AES-256-GCM');

        expect(appConfig.encryptionAlgorithm, equals('AES-256-GCM'));
      });

      test('should return key derivation iterations', () {
        when(mockRemoteConfigRepository.getInt('key_derivation_iterations', 100000))
            .thenReturn(100000);

        expect(appConfig.keyDerivationIterations, equals(100000));
      });

      test('should return min PIN length', () {
        when(mockRemoteConfigRepository.getInt('min_pin_length', 4))
            .thenReturn(4);

        expect(appConfig.minPinLength, equals(4));
      });

      test('should return max PIN length', () {
        when(mockRemoteConfigRepository.getInt('max_pin_length', 12))
            .thenReturn(12);

        expect(appConfig.maxPinLength, equals(12));
      });

      test('should return lock on background setting', () {
        when(mockRemoteConfigRepository.getBool('lock_on_background', true))
            .thenReturn(true);

        expect(appConfig.lockOnBackground, isTrue);
      });

      test('should return auto lock inactivity seconds', () {
        when(mockRemoteConfigRepository.getInt('auto_lock_inactivity_seconds', 30))
            .thenReturn(30);

        expect(appConfig.autoLockInactivitySeconds, equals(30));
      });
    });

    group('Calculator Config', () {
      test('should return PIN pattern', () {
        when(mockRemoteConfigRepository.getString('pin_pattern', '{pin}+0='))
            .thenReturn('{pin}+0=');

        expect(appConfig.pinPattern, equals('{pin}+0='));
      });

      test('should return decoy PIN pattern', () {
        when(mockRemoteConfigRepository.getString('decoy_pin_pattern', '{pin}+1='))
            .thenReturn('{pin}+1=');

        expect(appConfig.decoyPinPattern, equals('{pin}+1='));
      });

      test('should return advanced calculator enabled', () {
        when(mockRemoteConfigRepository.getBool('enable_advanced_calculator', true))
            .thenReturn(true);

        expect(appConfig.enableAdvancedCalculator, isTrue);
      });

      test('should return calculator style', () {
        when(mockRemoteConfigRepository.getString('calculator_style', 'ios'))
            .thenReturn('ios');

        expect(appConfig.calculatorStyle, equals('ios'));
      });
    });

    group('Navigation/UI Config', () {
      test('should return bottom nav style', () {
        when(mockRemoteConfigRepository.getString('bottom_nav_style', 'labeled'))
            .thenReturn('labeled');

        expect(appConfig.bottomNavStyle, equals('labeled'));
      });

      test('should return animation duration', () {
        when(mockRemoteConfigRepository.getInt('animation_duration_ms', 300))
            .thenReturn(300);

        expect(appConfig.animationDurationMs, equals(300));
      });

      test('should return haptic feedback enabled', () {
        when(mockRemoteConfigRepository.getBool('enable_haptic_feedback', true))
            .thenReturn(true);

        expect(appConfig.enableHapticFeedback, isTrue);
      });

      test('should return vault grid columns', () {
        when(mockRemoteConfigRepository.getInt('vault_grid_columns', 3))
            .thenReturn(3);

        expect(appConfig.vaultGridColumns, equals(3));
      });

      test('should return gallery tab enabled', () {
        when(mockRemoteConfigRepository.getBool('tabs_enabled_gallery', true))
            .thenReturn(true);

        expect(appConfig.galleryTabEnabled, isTrue);
      });

      test('should return files tab enabled', () {
        when(mockRemoteConfigRepository.getBool('tabs_enabled_files', true))
            .thenReturn(true);

        expect(appConfig.filesTabEnabled, isTrue);
      });

      test('should return notes tab enabled', () {
        when(mockRemoteConfigRepository.getBool('tabs_enabled_notes', true))
            .thenReturn(true);

        expect(appConfig.notesTabEnabled, isTrue);
      });

      test('should return passwords tab enabled', () {
        when(mockRemoteConfigRepository.getBool('tabs_enabled_passwords', true))
            .thenReturn(true);

        expect(appConfig.passwordsTabEnabled, isTrue);
      });

      test('should return contacts tab enabled', () {
        when(mockRemoteConfigRepository.getBool('tabs_enabled_contacts', true))
            .thenReturn(true);

        expect(appConfig.contactsTabEnabled, isTrue);
      });
    });

    group('Media Config', () {
      test('should return thumbnail quality', () {
        when(mockRemoteConfigRepository.getInt('thumbnail_quality', 80))
            .thenReturn(80);

        expect(appConfig.thumbnailQuality, equals(80));
      });

      test('should return max import batch size', () {
        when(mockRemoteConfigRepository.getInt('max_import_batch_size', 100))
            .thenReturn(100);

        expect(appConfig.maxImportBatchSize, equals(100));
      });
    });

    group('Monetization Config', () {
      test('should return max free items', () {
        when(mockRemoteConfigRepository.getInt('max_free_items', 50))
            .thenReturn(50);

        expect(appConfig.maxFreeItems, equals(50));
      });

      test('should return max free vaults', () {
        when(mockRemoteConfigRepository.getInt('max_free_vaults', 1))
            .thenReturn(1);

        expect(appConfig.maxFreeVaults, equals(1));
      });

      test('should return upsell trigger items remaining', () {
        when(mockRemoteConfigRepository.getInt('upsell_trigger_items_remaining', 10))
            .thenReturn(10);

        expect(appConfig.upsellTriggerItemsRemaining, equals(10));
      });

      test('should return upsell trigger after days', () {
        when(mockRemoteConfigRepository.getInt('upsell_trigger_after_days', 3))
            .thenReturn(3);

        expect(appConfig.upsellTriggerAfterDays, equals(3));
      });

      test('should return banner enabled', () {
        when(mockRemoteConfigRepository.getBool('banner_enabled', true))
            .thenReturn(true);

        expect(appConfig.bannerEnabled, isTrue);
      });

      test('should return interstitial enabled', () {
        when(mockRemoteConfigRepository.getBool('interstitial_enabled', true))
            .thenReturn(true);

        expect(appConfig.interstitialEnabled, isTrue);
      });

      test('should return rewarded enabled', () {
        when(mockRemoteConfigRepository.getBool('rewarded_enabled', true))
            .thenReturn(true);

        expect(appConfig.rewardedEnabled, isTrue);
      });
    });

    group('System Config', () {
      test('should return config version', () {
        when(mockRemoteConfigRepository.getString('config_version', '1.0.0'))
            .thenReturn('1.0.0');

        expect(appConfig.configVersion, equals('1.0.0'));
      });

      test('should return kill switch disabled', () {
        when(mockRemoteConfigRepository.getBool('kill_switch_app_disabled', false))
            .thenReturn(false);

        expect(appConfig.killSwitchAppDisabled, isFalse);
      });

      test('should return is app disabled based on kill switch', () {
        when(mockRemoteConfigRepository.getBool('kill_switch_app_disabled', false))
            .thenReturn(false);

        expect(appConfig.isAppDisabled, isFalse);
      });

      test('should return is app disabled when kill switch is active', () {
        when(mockRemoteConfigRepository.getBool('kill_switch_app_disabled', false))
            .thenReturn(true);

        expect(appConfig.isAppDisabled, isTrue);
      });
    });

    group('Intruder Config', () {
      test('should return intruder enabled', () {
        when(mockRemoteConfigRepository.getBool('intruder_enabled', true))
            .thenReturn(true);

        expect(appConfig.intruderEnabled, isTrue);
      });

      test('should return max attempts before capture', () {
        when(mockRemoteConfigRepository.getInt('max_attempts_before_capture', 2))
            .thenReturn(2);

        expect(appConfig.maxAttemptsBeforeCapture, equals(2));
      });

      test('should return capture count per attempt', () {
        when(mockRemoteConfigRepository.getInt('capture_count_per_attempt', 2))
            .thenReturn(2);

        expect(appConfig.captureCountPerAttempt, equals(2));
      });

      test('should return screenshot detection enabled', () {
        when(mockRemoteConfigRepository.getBool('enable_screenshot_detection', true))
            .thenReturn(true);

        expect(appConfig.enableScreenshotDetection, isTrue);
      });
    });

    group('Biometrics Config', () {
      test('should return biometrics enabled', () {
        when(mockRemoteConfigRepository.getBool('biometrics_enabled', true))
            .thenReturn(true);

        expect(appConfig.biometricsEnabled, isTrue);
      });

      test('should return biometrics prompt variant', () {
        when(mockRemoteConfigRepository.getString('biometrics_prompt_variant', 'after_first_unlock'))
            .thenReturn('after_first_unlock');

        expect(appConfig.biometricsPromptVariant, equals('after_first_unlock'));
      });
    });
  });
}
