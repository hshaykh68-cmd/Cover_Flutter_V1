import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cover/core/config/feature_gating.dart';
import 'package:cover/domain/usecase/feature_gating_usecases.dart';

@GenerateMocks([FeatureGating])
import 'feature_gating_usecases_test.mocks.dart';

void main() {
  group('Feature Gating Use Cases', () {
    late MockFeatureGating mockFeatureGating;

    setUp(() {
      mockFeatureGating = MockFeatureGating();
    });

    group('IsTabEnabledUseCase', () {
      test('should return true for gallery tab when enabled', () {
        when(mockFeatureGating.isGalleryEnabled).thenReturn(true);
        final useCase = IsTabEnabledUseCase(mockFeatureGating);

        final result = useCase('gallery');

        expect(result, isTrue);
      });

      test('should return false for gallery tab when disabled', () {
        when(mockFeatureGating.isGalleryEnabled).thenReturn(false);
        final useCase = IsTabEnabledUseCase(mockFeatureGating);

        final result = useCase('gallery');

        expect(result, isFalse);
      });

      test('should return true for files tab when enabled', () {
        when(mockFeatureGating.isFilesEnabled).thenReturn(true);
        final useCase = IsTabEnabledUseCase(mockFeatureGating);

        final result = useCase('files');

        expect(result, isTrue);
      });

      test('should return true for notes tab when enabled', () {
        when(mockFeatureGating.isNotesEnabled).thenReturn(true);
        final useCase = IsTabEnabledUseCase(mockFeatureGating);

        final result = useCase('notes');

        expect(result, isTrue);
      });

      test('should return true for passwords tab when enabled', () {
        when(mockFeatureGating.isPasswordsEnabled).thenReturn(true);
        final useCase = IsTabEnabledUseCase(mockFeatureGating);

        final result = useCase('passwords');

        expect(result, isTrue);
      });

      test('should return true for contacts tab when enabled', () {
        when(mockFeatureGating.isContactsEnabled).thenReturn(true);
        final useCase = IsTabEnabledUseCase(mockFeatureGating);

        final result = useCase('contacts');

        expect(result, isTrue);
      });

      test('should return false for unknown tab', () {
        final useCase = IsTabEnabledUseCase(mockFeatureGating);

        final result = useCase('unknown');

        expect(result, isFalse);
      });

      test('should be case-insensitive', () {
        when(mockFeatureGating.isGalleryEnabled).thenReturn(true);
        final useCase = IsTabEnabledUseCase(mockFeatureGating);

        final result = useCase('GALLERY');

        expect(result, isTrue);
      });
    });

    group('IsIntruderDetectionEnabledUseCase', () {
      test('should return true when intruder detection is enabled', () {
        when(mockFeatureGating.isIntruderDetectionEnabled).thenReturn(true);
        final useCase = IsIntruderDetectionEnabledUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isTrue);
      });

      test('should return false when intruder detection is disabled', () {
        when(mockFeatureGating.isIntruderDetectionEnabled).thenReturn(false);
        final useCase = IsIntruderDetectionEnabledUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isFalse);
      });
    });

    group('IsBiometricsEnabledUseCase', () {
      test('should return true when biometrics is enabled', () {
        when(mockFeatureGating.isBiometricsEnabled).thenReturn(true);
        final useCase = IsBiometricsEnabledUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isTrue);
      });

      test('should return false when biometrics is disabled', () {
        when(mockFeatureGating.isBiometricsEnabled).thenReturn(false);
        final useCase = IsBiometricsEnabledUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isFalse);
      });
    });

    group('ShouldPromptBiometricsUseCase', () {
      test('should return true when prompt on first unlock is enabled', () {
        when(mockFeatureGating.shouldPromptBiometricsOnFirstUnlock).thenReturn(true);
        final useCase = ShouldPromptBiometricsUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isTrue);
      });

      test('should return false when prompt on first unlock is disabled', () {
        when(mockFeatureGating.shouldPromptBiometricsOnFirstUnlock).thenReturn(false);
        final useCase = ShouldPromptBiometricsUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isFalse);
      });
    });

    group('AreAdsEnabledUseCase', () {
      test('should return true when ads are enabled', () {
        when(mockFeatureGating.areAdsEnabled).thenReturn(true);
        final useCase = AreAdsEnabledUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isTrue);
      });

      test('should return false when ads are disabled', () {
        when(mockFeatureGating.areAdsEnabled).thenReturn(false);
        final useCase = AreAdsEnabledUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isFalse);
      });
    });

    group('IsAppDisabledUseCase', () {
      test('should return true when kill switch is active', () {
        when(mockFeatureGating.isAppDisabled).thenReturn(true);
        final useCase = IsAppDisabledUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isTrue);
      });

      test('should return false when kill switch is not active', () {
        when(mockFeatureGating.isAppDisabled).thenReturn(false);
        final useCase = IsAppDisabledUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isFalse);
      });
    });

    group('GetDisabledFeaturesUseCase', () {
      test('should return list of disabled features', () {
        when(mockFeatureGating.getDisabledFeatures()).thenReturn(['Gallery', 'Notes']);
        final useCase = GetDisabledFeaturesUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, equals(['Gallery', 'Notes']));
      });

      test('should return empty list when all features are enabled', () {
        when(mockFeatureGating.getDisabledFeatures()).thenReturn([]);
        final useCase = GetDisabledFeaturesUseCase(mockFeatureGating);

        final result = useCase();

        expect(result, isEmpty);
      });
    });
  });
}
