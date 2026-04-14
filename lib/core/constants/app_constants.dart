class AppConstants {
  // App Info
  static const String appName = 'Cover';
  static const String appVersion = '1.0.0';
  
  // Security
  static const int minPinLength = 4;
  static const int maxPinLength = 12;
  static const int defaultPinAttempts = 3;
  static const int defaultLockoutMinutes = 15;
  
  // Encryption
  static const String encryptionAlgorithm = 'AES-256-GCM';
  static const int defaultKeyDerivationIterations = 100000;
  
  // Storage
  static const String databaseName = 'cover.db';
  static const int databaseVersion = 1;
  
  // Remote Config
  static const int configFetchIntervalMinutes = 60;
  static const int configMinimumFetchInterval = 15;
  
  // Analytics
  static const bool analyticsEnabled = true;
  
  // UI
  static const int vaultGridColumns = 3;
  static const int animationDurationMs = 300;
  
  // Monetization
  static const int maxFreeItems = 50;
  static const int maxFreeVaults = 1;
  static const int upsellTriggerItemsRemaining = 10;
  static const int upsellTriggerAfterDays = 3;
}
