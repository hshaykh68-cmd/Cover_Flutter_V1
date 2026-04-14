import 'package:cover/core/config/feature_gating.dart';

/// Use case to check if a specific tab is enabled
class IsTabEnabledUseCase {
  final FeatureGating _featureGating;

  IsTabEnabledUseCase(this._featureGating);

  bool call(String tabName) {
    switch (tabName.toLowerCase()) {
      case 'gallery':
        return _featureGating.isGalleryEnabled;
      case 'files':
        return _featureGating.isFilesEnabled;
      case 'notes':
        return _featureGating.isNotesEnabled;
      case 'passwords':
        return _featureGating.isPasswordsEnabled;
      case 'contacts':
        return _featureGating.isContactsEnabled;
      default:
        return false;
    }
  }
}

/// Use case to check if intruder detection is enabled
class IsIntruderDetectionEnabledUseCase {
  final FeatureGating _featureGating;

  IsIntruderDetectionEnabledUseCase(this._featureGating);

  bool call() => _featureGating.isIntruderDetectionEnabled;
}

/// Use case to check if biometrics is enabled
class IsBiometricsEnabledUseCase {
  final FeatureGating _featureGating;

  IsBiometricsEnabledUseCase(this._featureGating);

  bool call() => _featureGating.isBiometricsEnabled;
}

/// Use case to check if biometrics should prompt on first unlock
class ShouldPromptBiometricsUseCase {
  final FeatureGating _featureGating;

  ShouldPromptBiometricsUseCase(this._featureGating);

  bool call() => _featureGating.shouldPromptBiometricsOnFirstUnlock;
}

/// Use case to check if ads are enabled
class AreAdsEnabledUseCase {
  final FeatureGating _featureGating;

  AreAdsEnabledUseCase(this._featureGating);

  bool call() => _featureGating.areAdsEnabled;
}

/// Use case to check if the app is disabled via kill switch
class IsAppDisabledUseCase {
  final FeatureGating _featureGating;

  IsAppDisabledUseCase(this._featureGating);

  bool call() => _featureGating.isAppDisabled;
}

/// Use case to get list of disabled features
class GetDisabledFeaturesUseCase {
  final FeatureGating _featureGating;

  GetDisabledFeaturesUseCase(this._featureGating);

  List<String> call() => _featureGating.getDisabledFeatures();
}
