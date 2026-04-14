import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/config/feature_gating.dart';

@GenerateMocks([AppConfig])
import 'feature_gating_test.mocks.dart';

void main() {
  group('FeatureGating', () {
    late FeatureGating featureGating;
    late MockAppConfig mockAppConfig;

    setUp(() {
      mockAppConfig = MockAppConfig();
      featureGating = FeatureGating(mockAppConfig);
    });

    group('Security Features', () {
      test('should return lock on background setting', () {
        when(mockAppConfig.lockOnBackground).thenReturn(true);

        expect(featureGating.lockOnBackground, isTrue);
      });

      test('should return deny screenshots setting', () {
        when(mockAppConfig.denyScreenshotsAndroid).thenReturn(true);

        expect(featureGating.denyScreenshots, isTrue);
      });

      test('should return blur app switcher setting', () {
        when(mockAppConfig.blurAppSwitcherIos).thenReturn(true);

        expect(featureGating.blurAppSwitcher, isTrue);
      });
    });

    group('Tab Features', () {
      test('should return gallery tab enabled', () {
        when(mockAppConfig.galleryTabEnabled).thenReturn(true);

        expect(featureGating.isGalleryEnabled, isTrue);
      });

      test('should return files tab enabled', () {
        when(mockAppConfig.filesTabEnabled).thenReturn(true);

        expect(featureGating.isFilesEnabled, isTrue);
      });

      test('should return notes tab enabled', () {
        when(mockAppConfig.notesTabEnabled).thenReturn(true);

        expect(featureGating.isNotesEnabled, isTrue);
      });

      test('should return passwords tab enabled', () {
        when(mockAppConfig.passwordsTabEnabled).thenReturn(true);

        expect(featureGating.isPasswordsEnabled, isTrue);
      });

      test('should return contacts tab enabled', () {
        when(mockAppConfig.contactsTabEnabled).thenReturn(true);

        expect(featureGating.isContactsEnabled, isTrue);
      });

      test('should return true when any tab is enabled', () {
        when(mockAppConfig.galleryTabEnabled).thenReturn(true);
        when(mockAppConfig.filesTabEnabled).thenReturn(false);
        when(mockAppConfig.notesTabEnabled).thenReturn(false);
        when(mockAppConfig.passwordsTabEnabled).thenReturn(false);
        when(mockAppConfig.contactsTabEnabled).thenReturn(false);

        expect(featureGating.isAnyTabEnabled, isTrue);
      });

      test('should return false when no tabs are enabled', () {
        when(mockAppConfig.galleryTabEnabled).thenReturn(false);
        when(mockAppConfig.filesTabEnabled).thenReturn(false);
        when(mockAppConfig.notesTabEnabled).thenReturn(false);
        when(mockAppConfig.passwordsTabEnabled).thenReturn(false);
        when(mockAppConfig.contactsTabEnabled).thenReturn(false);

        expect(featureGating.isAnyTabEnabled, isFalse);
      });
    });

    group('Content Features', () {
      test('should return notes feature enabled', () {
        when(mockAppConfig.notesEnabled).thenReturn(true);

        expect(featureGating.isNotesFeatureEnabled, isTrue);
      });

      test('should return passwords feature enabled', () {
        when(mockAppConfig.passwordsEnabled).thenReturn(true);

        expect(featureGating.isPasswordsFeatureEnabled, isTrue);
      });

      test('should return contacts feature enabled', () {
        when(mockAppConfig.contactsEnabled).thenReturn(true);

        expect(featureGating.isContactsFeatureEnabled, isTrue);
      });
    });

    group('Intruder Defense Features', () {
      test('should return intruder detection enabled', () {
        when(mockAppConfig.intruderEnabled).thenReturn(true);

        expect(featureGating.isIntruderDetectionEnabled, isTrue);
      });

      test('should return screenshot detection enabled', () {
        when(mockAppConfig.enableScreenshotDetection).thenReturn(true);

        expect(featureGating.isScreenshotDetectionEnabled, isTrue);
      });

      test('should return location capture enabled when timeout > 0', () {
        when(mockAppConfig.locationTimeoutSeconds).thenReturn(5);

        expect(featureGating.isLocationCaptureEnabled, isTrue);
      });

      test('should return location capture disabled when timeout is 0', () {
        when(mockAppConfig.locationTimeoutSeconds).thenReturn(0);

        expect(featureGating.isLocationCaptureEnabled, isFalse);
      });
    });

    group('Biometrics Features', () {
      test('should return biometrics enabled', () {
        when(mockAppConfig.biometricsEnabled).thenReturn(true);

        expect(featureGating.isBiometricsEnabled, isTrue);
      });

      test('should return true when biometrics prompt variant is after_first_unlock', () {
        when(mockAppConfig.biometricsPromptVariant).thenReturn('after_first_unlock');

        expect(featureGating.shouldPromptBiometricsOnFirstUnlock, isTrue);
      });

      test('should return false when biometrics prompt variant is not after_first_unlock', () {
        when(mockAppConfig.biometricsPromptVariant).thenReturn('immediate');

        expect(featureGating.shouldPromptBiometricsOnFirstUnlock, isFalse);
      });

      test('should return true when biometrics is paywalled', () {
        when(mockAppConfig.biometricsPaywallVariant).thenReturn('premium_only');

        expect(featureGating.isBiometricsPaywalled, isTrue);
      });

      test('should return false when biometrics is not paywalled', () {
        when(mockAppConfig.biometricsPaywallVariant).thenReturn('none');

        expect(featureGating.isBiometricsPaywalled, isFalse);
      });
    });

    group('Monetization Features', () {
      test('should return ads enabled when any ad type is enabled', () {
        when(mockAppConfig.bannerEnabled).thenReturn(true);
        when(mockAppConfig.interstitialEnabled).thenReturn(false);
        when(mockAppConfig.rewardedEnabled).thenReturn(false);

        expect(featureGating.areAdsEnabled, isTrue);
      });

      test('should return ads enabled when all ad types are enabled', () {
        when(mockAppConfig.bannerEnabled).thenReturn(true);
        when(mockAppConfig.interstitialEnabled).thenReturn(true);
        when(mockAppConfig.rewardedEnabled).thenReturn(true);

        expect(featureGating.areAdsEnabled, isTrue);
      });

      test('should return ads disabled when no ad types are enabled', () {
        when(mockAppConfig.bannerEnabled).thenReturn(false);
        when(mockAppConfig.interstitialEnabled).thenReturn(false);
        when(mockAppConfig.rewardedEnabled).thenReturn(false);

        expect(featureGating.areAdsEnabled, isFalse);
      });

      test('should return banner ad enabled', () {
        when(mockAppConfig.bannerEnabled).thenReturn(true);

        expect(featureGating.isBannerAdEnabled, isTrue);
      });

      test('should return interstitial ad enabled', () {
        when(mockAppConfig.interstitialEnabled).thenReturn(true);

        expect(featureGating.isInterstitialAdEnabled, isTrue);
      });

      test('should return rewarded ad enabled', () {
        when(mockAppConfig.rewardedEnabled).thenReturn(true);

        expect(featureGating.isRewardedAdEnabled, isTrue);
      });
    });

    group('System Features', () {
      test('should return haptic feedback enabled', () {
        when(mockAppConfig.enableHapticFeedback).thenReturn(true);

        expect(featureGating.isHapticFeedbackEnabled, isTrue);
      });

      test('should return tutorial enabled', () {
        when(mockAppConfig.showTutorialOnFirstLaunch).thenReturn(true);

        expect(featureGating.isTutorialEnabled, isTrue);
      });

      test('should return realtime config enabled', () {
        when(mockAppConfig.enableRealtimeConfig).thenReturn(true);

        expect(featureGating.isRealtimeConfigEnabled, isTrue);
      });

      test('should return app disabled when kill switch is active', () {
        when(mockAppConfig.isAppDisabled).thenReturn(true);

        expect(featureGating.isAppDisabled, isTrue);
      });
    });

    group('Import/Export Features', () {
      test('should return max import batch size', () {
        when(mockAppConfig.maxImportBatchSize).thenReturn(100);

        expect(featureGating.maxImportBatchSize, equals(100));
      });

      test('should return thumbnail quality', () {
        when(mockAppConfig.thumbnailQuality).thenReturn(80);

        expect(featureGating.thumbnailQuality, equals(80));
      });
    });

    group('Get Disabled Features', () {
      test('should return list of disabled features', () {
        when(mockAppConfig.galleryTabEnabled).thenReturn(false);
        when(mockAppConfig.filesTabEnabled).thenReturn(true);
        when(mockAppConfig.notesTabEnabled).thenReturn(false);
        when(mockAppConfig.passwordsTabEnabled).thenReturn(true);
        when(mockAppConfig.contactsTabEnabled).thenReturn(false);
        when(mockAppConfig.intruderEnabled).thenReturn(false);
        when(mockAppConfig.biometricsEnabled).thenReturn(true);

        final disabled = featureGating.getDisabledFeatures();

        expect(disabled, contains('Gallery'));
        expect(disabled, contains('Notes'));
        expect(disabled, contains('Contacts'));
        expect(disabled, contains('Intruder Detection'));
        expect(disabled, isNot(contains('Files')));
        expect(disabled, isNot(contains('Passwords')));
        expect(disabled, isNot(contains('Biometrics')));
      });

      test('should return empty list when all features are enabled', () {
        when(mockAppConfig.galleryTabEnabled).thenReturn(true);
        when(mockAppConfig.filesTabEnabled).thenReturn(true);
        when(mockAppConfig.notesTabEnabled).thenReturn(true);
        when(mockAppConfig.passwordsTabEnabled).thenReturn(true);
        when(mockAppConfig.contactsTabEnabled).thenReturn(true);
        when(mockAppConfig.intruderEnabled).thenReturn(true);
        when(mockAppConfig.biometricsEnabled).thenReturn(true);

        final disabled = featureGating.getDisabledFeatures();

        expect(disabled, isEmpty);
      });
    });
  });
}
