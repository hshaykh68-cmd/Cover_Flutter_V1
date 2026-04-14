import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/crypto/crypto_service_impl.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/secure_storage/secure_key_storage_impl.dart';
import 'package:cover/core/constants/app_constants.dart';
import 'package:cover/core/pin/pin_state_machine.dart';
import 'package:cover/core/vault/vault_service.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/config/feature_gating.dart';
import 'package:cover/core/config/limits_enforcement.dart';
import 'package:cover/data/local/database/app_database.dart';
import 'package:cover/data/local/database/daos/vault_dao.dart';
import 'package:cover/data/local/database/daos/media_item_dao.dart';
import 'package:cover/data/local/database/daos/note_dao.dart';
import 'package:cover/data/local/database/daos/password_dao.dart';
import 'package:cover/data/local/database/daos/contact_dao.dart';
import 'package:cover/data/local/database/daos/intruder_log_dao.dart';
import 'package:cover/data/local/database/daos/user_dao.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/vault_repository.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/domain/repository/note_repository.dart';
import 'package:cover/domain/repository/password_repository.dart';
import 'package:cover/domain/repository/contact_repository.dart';
import 'package:cover/domain/repository/intruder_log_repository.dart';
import 'package:cover/domain/repository/user_repository.dart';
import 'package:cover/domain/repository/remote_config_repository.dart';
import 'package:cover/domain/repository/file_repository.dart';
import 'package:cover/domain/usecase/feature_gating_usecases.dart';
import 'package:cover/domain/usecase/limits_enforcement_usecases.dart';
import 'package:cover/domain/usecase/intruder_log_usecases.dart';
import 'package:cover/domain/usecase/media_item_usecases.dart';
import 'package:cover/domain/usecase/note_usecases.dart';
import 'package:cover/domain/usecase/user_usecases.dart';
import 'package:cover/domain/usecase/vault_usecases.dart';
import 'package:cover/domain/usecase/password_usecases.dart';
import 'package:cover/domain/usecase/contact_usecases.dart';
import 'package:cover/core/media/media_import_service.dart';
import 'package:cover/core/media/thumbnail_service.dart';
import 'package:cover/core/media/secure_media_viewer.dart';
import 'package:cover/core/intruder/intruder_detection_service.dart';
import 'package:cover/core/intruder/intruder_camera_capture_service.dart';
import 'package:cover/core/intruder/intruder_location_capture_service.dart';
import 'package:cover/core/emergency/emergency_close_service.dart';
import 'package:cover/core/biometrics/biometrics_service.dart';
import 'package:cover/core/billing/subscription_service.dart';
import 'package:cover/core/billing/regional_pricing_service.dart';
import 'package:cover/core/files/file_import_service.dart';
import 'package:cover/core/files/file_viewer_service.dart';
import 'package:cover/core/files/export_hardening_service.dart';
import 'package:cover/core/password/password_generator_service.dart';
import 'package:cover/core/password/clipboard_timeout_service.dart';
import 'package:cover/data/repository/vault_repository_impl.dart';
import 'package:cover/data/repository/media_item_repository_impl.dart';
import 'package:cover/data/repository/note_repository_impl.dart';
import 'package:cover/data/repository/password_repository_impl.dart';
import 'package:cover/data/repository/contact_repository_impl.dart';
import 'package:cover/data/repository/intruder_log_repository_impl.dart';
import 'package:cover/data/repository/user_repository_impl.dart';
import 'package:cover/data/repository/remote_config_repository_impl.dart';
import 'package:cover/data/repository/file_repository_impl.dart';
import 'package:cover/data/local/database/daos/file_dao.dart';
import 'package:cover/presentation/screens/vault/vault_shell_screen.dart';
import 'package:cover/presentation/navigation/app_router.dart';

// This file will contain all dependency injection setup
// It will be populated as we implement each phase

part 'di_container.g.dart';

// Crypto Service Provider
@Riverpod(keepAlive: true)
CryptoService cryptoService(CryptoServiceRef ref) {
  return CryptoServiceImpl(
    pbkdf2Iterations: AppConstants.defaultKeyDerivationIterations,
    keyLength: 32,
    saltLength: 16,
  );
}

// Secure Key Storage Provider
@Riverpod(keepAlive: true)
SecureKeyStorage secureKeyStorage(SecureKeyStorageRef ref) {
  return SecureKeyStorageImpl(
    defaultOptions: SecureStorageOptions.masterKey,
  );
}

// Database Factory Provider
@Riverpod(keepAlive: true)
AppDatabaseFactory appDatabaseFactory(AppDatabaseFactoryRef ref) {
  final cryptoService = ref.watch(cryptoServiceProvider);
  final secureStorage = ref.watch(secureKeyStorageProvider);
  
  return AppDatabaseFactory(
    cryptoService: cryptoService,
    secureStorage: secureStorage,
  );
}

// Database Provider
@Riverpod(keepAlive: true)
Future<AppDatabase> appDatabase(AppDatabaseRef ref) async {
  final factory = ref.watch(appDatabaseFactoryProvider);
  return await factory.create();
}

// DAO Providers
@Riverpod(keepAlive: true)
Future<VaultDao> vaultDao(VaultDaoRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return VaultDao(db);
}

@Riverpod(keepAlive: true)
Future<MediaItemDao> mediaItemDao(MediaItemDaoRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return MediaItemDao(db);
}

@Riverpod(keepAlive: true)
Future<NoteDao> noteDao(NoteDaoRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return NoteDao(db);
}

@Riverpod(keepAlive: true)
Future<PasswordDao> passwordDao(PasswordDaoRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return PasswordDao(db);
}

@Riverpod(keepAlive: true)
Future<ContactDao> contactDao(ContactDaoRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return ContactDao(db);
}

@Riverpod(keepAlive: true)
Future<IntruderLogDao> intruderLogDao(IntruderLogDaoRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return IntruderLogDao(db);
}

@Riverpod(keepAlive: true)
Future<UserDao> userDao(UserDaoRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return UserDao(db);
}

// Repository Providers
@Riverpod(keepAlive: true)
Future<VaultRepository> vaultRepository(VaultRepositoryRef ref) async {
  final dao = await ref.watch(vaultDaoProvider.future);
  return VaultRepositoryImpl(dao);
}

@Riverpod(keepAlive: true)
Future<MediaItemRepository> mediaItemRepository(MediaItemRepositoryRef ref) async {
  final dao = await ref.watch(mediaItemDaoProvider.future);
  return MediaItemRepositoryImpl(dao);
}

@Riverpod(keepAlive: true)
Future<FileRepository> fileRepository(FileRepositoryRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return FileRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
Future<NoteRepository> noteRepository(NoteRepositoryRef ref) async {
  final dao = await ref.watch(noteDaoProvider.future);
  return NoteRepositoryImpl(dao);
}

@Riverpod(keepAlive: true)
Future<PasswordRepository> passwordRepository(PasswordRepositoryRef ref) async {
  final dao = await ref.watch(passwordDaoProvider.future);
  return PasswordRepositoryImpl(dao);
}

@Riverpod(keepAlive: true)
Future<ContactRepository> contactRepository(ContactRepositoryRef ref) async {
  final dao = await ref.watch(contactDaoProvider.future);
  return ContactRepositoryImpl(dao);
}

@Riverpod(keepAlive: true)
Future<IntruderLogRepository> intruderLogRepository(IntruderLogRepositoryRef ref) async {
  final dao = await ref.watch(intruderLogDaoProvider.future);
  return IntruderLogRepositoryImpl(dao);
}

@Riverpod(keepAlive: true)
Future<UserRepository> userRepository(UserRepositoryRef ref) async {
  final dao = await ref.watch(userDaoProvider.future);
  return UserRepositoryImpl(dao);
}

// Firebase Remote Config Provider
@Riverpod(keepAlive: true)
FirebaseRemoteConfig firebaseRemoteConfig(FirebaseRemoteConfigRef ref) {
  return FirebaseRemoteConfig.instance;
}

// Remote Config Repository Provider
@Riverpod(keepAlive: true)
RemoteConfigRepository remoteConfigRepository(RemoteConfigRepositoryRef ref) {
  final remoteConfig = ref.watch(firebaseRemoteConfigProvider);
  return RemoteConfigRepositoryImpl(remoteConfig);
}

// App Config Provider
@Riverpod(keepAlive: true)
AppConfig appConfig(AppConfigRef ref) {
  final remoteConfigRepository = ref.watch(remoteConfigRepositoryProvider);
  return AppConfig(remoteConfigRepository);
}

// Feature Gating Provider
@Riverpod(keepAlive: true)
FeatureGating featureGating(FeatureGatingRef ref) {
  final appConfig = ref.watch(appConfigProvider);
  return FeatureGating(appConfig);
}

// Limits Enforcement Provider
@Riverpod(keepAlive: true)
Future<LimitsEnforcement> limitsEnforcement(LimitsEnforcementRef ref) async {
  final appConfig = ref.watch(appConfigProvider);
  final vaultRepository = await ref.watch(vaultRepositoryProvider.future);
  final mediaItemRepository = await ref.watch(mediaItemRepositoryProvider.future);
  return LimitsEnforcement(appConfig, vaultRepository, mediaItemRepository);
}

// Feature Gating Use Case Providers
@Riverpod(keepAlive: true)
IsTabEnabledUseCase isTabEnabledUseCase(IsTabEnabledUseCaseRef ref) {
  final featureGating = ref.watch(featureGatingProvider);
  return IsTabEnabledUseCase(featureGating);
}

@Riverpod(keepAlive: true)
IsIntruderDetectionEnabledUseCase isIntruderDetectionEnabledUseCase(
    IsIntruderDetectionEnabledUseCaseRef ref) {
  final featureGating = ref.watch(featureGatingProvider);
  return IsIntruderDetectionEnabledUseCase(featureGating);
}

@Riverpod(keepAlive: true)
IsBiometricsEnabledUseCase isBiometricsEnabledUseCase(
    IsBiometricsEnabledUseCaseRef ref) {
  final featureGating = ref.watch(featureGatingProvider);
  return IsBiometricsEnabledUseCase(featureGating);
}

@Riverpod(keepAlive: true)
ShouldPromptBiometricsUseCase shouldPromptBiometricsUseCase(
    ShouldPromptBiometricsUseCaseRef ref) {
  final featureGating = ref.watch(featureGatingProvider);
  return ShouldPromptBiometricsUseCase(featureGating);
}

@Riverpod(keepAlive: true)
AreAdsEnabledUseCase areAdsEnabledUseCase(AreAdsEnabledUseCaseRef ref) {
  final featureGating = ref.watch(featureGatingProvider);
  return AreAdsEnabledUseCase(featureGating);
}

@Riverpod(keepAlive: true)
IsAppDisabledUseCase isAppDisabledUseCase(IsAppDisabledUseCaseRef ref) {
  final featureGating = ref.watch(featureGatingProvider);
  return IsAppDisabledUseCase(featureGating);
}

@Riverpod(keepAlive: true)
GetDisabledFeaturesUseCase getDisabledFeaturesUseCase(
    GetDisabledFeaturesUseCaseRef ref) {
  final featureGating = ref.watch(featureGatingProvider);
  return GetDisabledFeaturesUseCase(featureGating);
}

// Limits Enforcement Use Case Providers
@Riverpod(keepAlive: true)
Future<CanAddItemsUseCase> canAddItemsUseCase(CanAddItemsUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return CanAddItemsUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<CanCreateVaultUseCase> canCreateVaultUseCase(CanCreateVaultUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return CanCreateVaultUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<GetItemsRemainingUseCase> getItemsRemainingUseCase(
    GetItemsRemainingUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return GetItemsRemainingUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<GetVaultsRemainingUseCase> getVaultsRemainingUseCase(
    GetVaultsRemainingUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return GetVaultsRemainingUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<ShouldShowPaywallForItemsUseCase> shouldShowPaywallForItemsUseCase(
    ShouldShowPaywallForItemsUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return ShouldShowPaywallForItemsUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<ShouldShowPaywallForVaultsUseCase> shouldShowPaywallForVaultsUseCase(
    ShouldShowPaywallForVaultsUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return ShouldShowPaywallForVaultsUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<IsApproachingItemLimitUseCase> isApproachingItemLimitUseCase(
    IsApproachingItemLimitUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return IsApproachingItemLimitUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<IsAtItemLimitUseCase> isAtItemLimitUseCase(IsAtItemLimitUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return IsAtItemLimitUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<IsAtVaultLimitUseCase> isAtVaultLimitUseCase(IsAtVaultLimitUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return IsAtVaultLimitUseCase(limitsEnforcement);
}

@Riverpod(keepAlive: true)
Future<GetUsageStatsUseCase> getUsageStatsUseCase(GetUsageStatsUseCaseRef ref) async {
  final limitsEnforcement = await ref.watch(limitsEnforcementProvider.future);
  return GetUsageStatsUseCase(limitsEnforcement);
}

// Media Import Service Provider
@Riverpod(keepAlive: true)
Future<MediaImportService> mediaImportService(MediaImportServiceRef ref) async {
  final secureFileStorage = await ref.watch(secureFileStorageProvider.future);
  final mediaItemRepository = await ref.watch(mediaItemRepositoryProvider.future);
  final vaultRepository = await ref.watch(vaultRepositoryProvider.future);
  final appConfig = ref.watch(appConfigProvider);
  return MediaImportServiceImpl(
    secureFileStorage,
    mediaItemRepository,
    vaultRepository,
    appConfig,
  );
}

// Thumbnail Service Provider
@Riverpod(keepAlive: true)
Future<ThumbnailService> thumbnailService(ThumbnailServiceRef ref) async {
  final secureFileStorage = await ref.watch(secureFileStorageProvider.future);
  final mediaItemRepository = await ref.watch(mediaItemRepositoryProvider.future);
  final appConfig = ref.watch(appConfigProvider);
  return ThumbnailServiceImpl(
    secureFileStorage,
    mediaItemRepository,
    appConfig,
  );
}

// Secure Media Viewer Provider
@Riverpod(keepAlive: true)
Future<SecureMediaViewer> secureMediaViewer(SecureMediaViewerRef ref) async {
  final secureFileStorage = await ref.watch(secureFileStorageProvider.future);
  final mediaItemRepository = await ref.watch(mediaItemRepositoryProvider.future);
  return SecureMediaViewerImpl(
    secureFileStorage,
    mediaItemRepository,
  );
}

// File Import Service Provider
@Riverpod(keepAlive: true)
Future<FileImportService> fileImportService(FileImportServiceRef ref) async {
  final secureFileStorage = await ref.watch(secureFileStorageProvider.future);
  final fileRepository = await ref.watch(fileRepositoryProvider.future);
  final vaultRepository = await ref.watch(vaultRepositoryProvider.future);
  final appConfig = ref.watch(appConfigProvider);
  return FileImportServiceImpl(
    secureFileStorage,
    fileRepository,
    vaultRepository,
    appConfig,
  );
}

// File Viewer Service Provider
@Riverpod(keepAlive: true)
Future<FileViewerService> fileViewerService(FileViewerServiceRef ref) async {
  final secureFileStorage = await ref.watch(secureFileStorageProvider.future);
  final fileRepository = await ref.watch(fileRepositoryProvider.future);
  return FileViewerServiceImpl(
    secureFileStorage,
    fileRepository,
  );
}

// Export Hardening Service Provider
@Riverpod(keepAlive: true)
Future<ExportHardeningService> exportHardeningService(ExportHardeningServiceRef ref) async {
  final secureFileStorage = await ref.watch(secureFileStorageProvider.future);
  final fileRepository = await ref.watch(fileRepositoryProvider.future);
  return ExportHardeningServiceImpl(
    secureFileStorage,
    fileRepository,
  );
}

// Secure File Storage Provider
@Riverpod(keepAlive: true)
Future<SecureFileStorage> secureFileStorage(SecureFileStorageRef ref) async {
  final cryptoService = ref.watch(cryptoServiceProvider);
  final vaultRepository = await ref.watch(vaultRepositoryProvider.future);
  final secureKeyStorage = ref.watch(secureKeyStorageProvider);
  return SecureFileStorageImpl(cryptoService, vaultRepository, secureKeyStorage);
}

// Vault Service Provider
@Riverpod(keepAlive: true)
Future<VaultService> vaultService(VaultServiceRef ref) async {
  final vaultRepository = await ref.watch(vaultRepositoryProvider.future);
  final userRepository = await ref.watch(userRepositoryProvider.future);
  final cryptoService = ref.watch(cryptoServiceProvider);
  return VaultService(vaultRepository, userRepository, cryptoService);
}

// PIN State Machine Provider
@Riverpod(keepAlive: true)
PinStateMachine pinStateMachine(PinStateMachineRef ref) {
  return PinStateMachine();
}

// PIN Lockout Manager Provider
@Riverpod(keepAlive: true)
PinLockoutManager pinLockoutManager(PinLockoutManagerRef ref) {
  final secureStorage = ref.watch(secureKeyStorageProvider);
  return PinLockoutManager(secureStorage: secureStorage);
}

// Intruder Camera Capture Service Provider
@Riverpod(keepAlive: true)
Future<IntruderCameraCaptureService> intruderCameraCaptureService(
    IntruderCameraCaptureServiceRef ref) async {
  final cryptoService = ref.watch(cryptoServiceProvider);
  final secureFileStorage = await ref.watch(secureFileStorageProvider.future);
  return IntruderCameraCaptureServiceImpl(
    cryptoService: cryptoService,
    secureFileStorage: secureFileStorage,
  );
}

// Intruder Location Capture Service Provider
@Riverpod(keepAlive: true)
IntruderLocationCaptureService intruderLocationCaptureService(
    IntruderLocationCaptureServiceRef ref) {
  final cryptoService = ref.watch(cryptoServiceProvider);
  return IntruderLocationCaptureServiceImpl(
    cryptoService: cryptoService,
  );
}

// Intruder Detection Service Provider
@Riverpod(keepAlive: true)
Future<IntruderDetectionService> intruderDetectionService(
    IntruderDetectionServiceRef ref) async {
  final intruderLogRepository = await ref.watch(intruderLogRepositoryProvider.future);
  final cryptoService = ref.watch(cryptoServiceProvider);
  final secureFileStorage = await ref.watch(secureFileStorageProvider.future);
  final secureKeyStorage = ref.watch(secureKeyStorageProvider);
  final cameraCaptureService = await ref.watch(intruderCameraCaptureServiceProvider.future);
  final locationCaptureService = ref.watch(intruderLocationCaptureServiceProvider);
  final appConfig = ref.watch(appConfigProvider);
  
  return IntruderDetectionServiceImpl(
    intruderLogRepository: intruderLogRepository,
    cryptoService: cryptoService,
    secureFileStorage: secureFileStorage,
    secureKeyStorage: secureKeyStorage,
    cameraCaptureService: cameraCaptureService,
    locationCaptureService: locationCaptureService,
    maxAttemptsBeforeCapture: appConfig.maxAttemptsBeforeCapture,
    captureCountPerAttempt: appConfig.captureCountPerAttempt,
  );
}

// Emergency Close Service Provider
@Riverpod(keepAlive: true)
EmergencyCloseService emergencyCloseService(EmergencyCloseServiceRef ref) {
  final appConfig = ref.watch(appConfigProvider);
  return EmergencyCloseServiceImpl(
    appConfig: appConfig,
    sensitivity: appConfig.shakeSensitivity,
  );
}

// Biometrics Service Provider
@Riverpod(keepAlive: true)
BiometricsService biometricsService(BiometricsServiceRef ref) {
  final appConfig = ref.watch(appConfigProvider);
  final localAuth = LocalAuthentication();
  return BiometricsServiceImpl(
    localAuth: localAuth,
    appConfig: appConfig,
  );
}

// Subscription Service Provider
@Riverpod(keepAlive: true)
SubscriptionService subscriptionService(SubscriptionServiceRef ref) {
  final appConfig = ref.watch(appConfigProvider);
  final regionalPricingService = ref.watch(regionalPricingServiceProvider);
  final firestoreRepository = ref.watch(subscriptionFirestoreRepositoryProvider);
  final purchaseVerifier = ref.watch(purchaseVerifierProvider);
  final auth = FirebaseAuth.instance;
  return SubscriptionServiceImpl(
    appConfig: appConfig,
    regionalPricingService: regionalPricingService,
    firestoreRepository: firestoreRepository,
    purchaseVerifier: purchaseVerifier,
    auth: auth,
  );
}

// Regional Pricing Service Provider
@Riverpod(keepAlive: true)
RegionalPricingService regionalPricingService(RegionalPricingServiceRef ref) {
  final appConfig = ref.watch(appConfigProvider);
  return RegionalPricingService(appConfig: appConfig);
}

// Subscription Firestore Repository Provider
@Riverpod(keepAlive: true)
SubscriptionFirestoreRepository subscriptionFirestoreRepository(SubscriptionFirestoreRepositoryRef ref) {
  return SubscriptionFirestoreRepository();
}

// Purchase Verifier Provider
@Riverpod(keepAlive: true)
PurchaseVerifier purchaseVerifier(PurchaseVerifierRef ref) {
  final appConfig = ref.watch(appConfigProvider);
  return PurchaseVerifier(appConfig: appConfig);
}

// Subscription Lifecycle Manager Provider
@Riverpod(keepAlive: true)
SubscriptionLifecycleManager subscriptionLifecycleManager(SubscriptionLifecycleManagerRef ref) {
  final firestoreRepository = ref.watch(subscriptionFirestoreRepositoryProvider);
  final appConfig = ref.watch(appConfigProvider);
  return SubscriptionLifecycleManager(
    firestoreRepository: firestoreRepository,
    appConfig: appConfig,
  );
}

// Password Generator Service Provider
@Riverpod(keepAlive: true)
PasswordGeneratorService passwordGeneratorService(PasswordGeneratorServiceRef ref) {
  final appConfig = ref.watch(appConfigProvider);
  return PasswordGeneratorServiceImpl(appConfig);
}

// Clipboard Timeout Service Provider
@Riverpod(keepAlive: true)
ClipboardTimeoutService clipboardTimeoutService(ClipboardTimeoutServiceRef ref) {
  final appConfig = ref.watch(appConfigProvider);
  return ClipboardTimeoutServiceImpl(appConfig);
}

// Password Use Case Providers
@Riverpod(keepAlive: true)
Future<CreatePasswordUseCase> createPasswordUseCase(CreatePasswordUseCaseRef ref) async {
  return CreatePasswordUseCase(
    await ref.watch(passwordRepositoryProvider.future),
    ref.watch(cryptoServiceProvider),
    await ref.watch(vaultServiceProvider.future),
  );
}

@Riverpod(keepAlive: true)
Future<UpdatePasswordUseCase> updatePasswordUseCase(UpdatePasswordUseCaseRef ref) async {
  return UpdatePasswordUseCase(
    await ref.watch(passwordRepositoryProvider.future),
    ref.watch(cryptoServiceProvider),
    await ref.watch(vaultServiceProvider.future),
  );
}

@Riverpod(keepAlive: true)
Future<DeletePasswordUseCase> deletePasswordUseCase(DeletePasswordUseCaseRef ref) async {
  return DeletePasswordUseCase(await ref.watch(passwordRepositoryProvider.future));
}

@Riverpod(keepAlive: true)
Future<GetPasswordsUseCase> getPasswordsUseCase(GetPasswordsUseCaseRef ref) async {
  return GetPasswordsUseCase(
    await ref.watch(passwordRepositoryProvider.future),
    await ref.watch(vaultServiceProvider.future),
  );
}

@Riverpod(keepAlive: true)
Future<GetPasswordByIdUseCase> getPasswordByIdUseCase(GetPasswordByIdUseCaseRef ref) async {
  return GetPasswordByIdUseCase(await ref.watch(passwordRepositoryProvider.future));
}

@Riverpod(keepAlive: true)
CopyPasswordToClipboardUseCase copyPasswordToClipboardUseCase(CopyPasswordToClipboardUseCaseRef ref) {
  return CopyPasswordToClipboardUseCase(ref.watch(clipboardTimeoutServiceProvider));
}

@Riverpod(keepAlive: true)
GeneratePasswordUseCase generatePasswordUseCase(GeneratePasswordUseCaseRef ref) {
  return GeneratePasswordUseCase(ref.watch(passwordGeneratorServiceProvider));
}

@Riverpod(keepAlive: true)
Future<SearchPasswordsUseCase> searchPasswordsUseCase(SearchPasswordsUseCaseRef ref) async {
  return SearchPasswordsUseCase(
    await ref.watch(passwordRepositoryProvider.future),
    await ref.watch(vaultServiceProvider.future),
  );
}

@Riverpod(keepAlive: true)
Future<GetPasswordsByFolderUseCase> getPasswordsByFolderUseCase(GetPasswordsByFolderUseCaseRef ref) async {
  return GetPasswordsByFolderUseCase(
    await ref.watch(passwordRepositoryProvider.future),
    await ref.watch(vaultServiceProvider.future),
    ref.watch(cryptoServiceProvider),
  );
}

// Contact Use Case Providers
@Riverpod(keepAlive: true)
Future<CreateContactUseCase> createContactUseCase(CreateContactUseCaseRef ref) async {
  return CreateContactUseCase(
    await ref.watch(contactRepositoryProvider.future),
    ref.watch(cryptoServiceProvider),
    await ref.watch(vaultServiceProvider.future),
  );
}

@Riverpod(keepAlive: true)
Future<UpdateContactUseCase> updateContactUseCase(UpdateContactUseCaseRef ref) async {
  return UpdateContactUseCase(await ref.watch(contactRepositoryProvider.future));
}

@Riverpod(keepAlive: true)
Future<DeleteContactUseCase> deleteContactUseCase(DeleteContactUseCaseRef ref) async {
  return DeleteContactUseCase(await ref.watch(contactRepositoryProvider.future));
}

@Riverpod(keepAlive: true)
Future<GetContactsUseCase> getContactsUseCase(GetContactsUseCaseRef ref) async {
  return GetContactsUseCase(
    await ref.watch(contactRepositoryProvider.future),
    await ref.watch(vaultServiceProvider.future),
  );
}

@Riverpod(keepAlive: true)
Future<GetContactByIdUseCase> getContactByIdUseCase(GetContactByIdUseCaseRef ref) async {
  return GetContactByIdUseCase(await ref.watch(contactRepositoryProvider.future));
}

@Riverpod(keepAlive: true)
CallContactUseCase callContactUseCase(CallContactUseCaseRef ref) {
  return CallContactUseCase(ref.watch(cryptoServiceProvider));
}

@Riverpod(keepAlive: true)
SmsContactUseCase smsContactUseCase(SmsContactUseCaseRef ref) {
  return SmsContactUseCase(ref.watch(cryptoServiceProvider));
}

@Riverpod(keepAlive: true)
EmailContactUseCase emailContactUseCase(EmailContactUseCaseRef ref) {
  return EmailContactUseCase(ref.watch(cryptoServiceProvider));
}

@Riverpod(keepAlive: true)
Future<SearchContactsUseCase> searchContactsUseCase(SearchContactsUseCaseRef ref) async {
  return SearchContactsUseCase(
    await ref.watch(contactRepositoryProvider.future),
    await ref.watch(vaultServiceProvider.future),
  );
}

@Riverpod(keepAlive: true)
Future<GetContactsByFolderUseCase> getContactsByFolderUseCase(GetContactsByFolderUseCaseRef ref) async {
  return GetContactsByFolderUseCase(
    await ref.watch(contactRepositoryProvider.future),
    await ref.watch(vaultServiceProvider.future),
    ref.watch(cryptoServiceProvider),
  );
}

// Vault Tab State Provider - manages current tab in vault shell
@Riverpod(keepAlive: true)
class VaultTabState extends _$VaultTabState {
  @override
  VaultTab build() {
    return VaultTab.vault;
  }

  void setTab(VaultTab tab) {
    state = tab;
  }
}

// Vault Stats Provider - fetches real stats from repositories
@Riverpod(keepAlive: true)
Future<VaultStats> vaultStats(VaultStatsRef ref) async {
  final vaultService = await ref.watch(vaultServiceProvider.future);
  final vaultRepository = await ref.watch(vaultRepositoryProvider.future);
  final noteRepository = await ref.watch(noteRepositoryProvider.future);
  final passwordRepository = await ref.watch(passwordRepositoryProvider.future);
  final contactRepository = await ref.watch(contactRepositoryProvider.future);
  final fileRepository = await ref.watch(fileRepositoryProvider.future);
  final mediaItemRepository = await ref.watch(mediaItemRepositoryProvider.future);

  final vaultId = await vaultService.getVaultId(VaultNamespace.real);
  if (vaultId == null) {
    return VaultStats(
      totalItems: 0,
      storageUsed: 0,
      vaultCount: 0,
      photosCount: 0,
      filesCount: 0,
      notesCount: 0,
      passwordsCount: 0,
      contactsCount: 0,
    );
  }

  final vaults = await vaultRepository.getAllVaults();
  final vaultCount = vaults.length;

  final notesCount = await noteRepository.getNoteCount(vaultId);
  final passwordsCount = await passwordRepository.getPasswordCount(vaultId);
  final contactsCount = await contactRepository.getContactCount(vaultId);
  final filesCount = await fileRepository.getFileCount(vaultId);
  final mediaCount = await mediaItemRepository.getMediaItemCount(vaultId);

  final totalItems = notesCount + passwordsCount + contactsCount + filesCount + mediaCount;

  // Calculate storage used (simplified - in production would sum actual file sizes)
  final storageUsed = 0; // Will be implemented when file size tracking is added

  return VaultStats(
    totalItems: totalItems,
    storageUsed: storageUsed,
    vaultCount: vaultCount,
    photosCount: mediaCount,
    filesCount: filesCount,
    notesCount: notesCount,
    passwordsCount: passwordsCount,
    contactsCount: contactsCount,
  );
}

// Vault Stats data class
class VaultStats {
  final int totalItems;
  final int storageUsed;
  final int vaultCount;
  final int photosCount;
  final int filesCount;
  final int notesCount;
  final int passwordsCount;
  final int contactsCount;

  VaultStats({
    required this.totalItems,
    required this.storageUsed,
    required this.vaultCount,
    required this.photosCount,
    required this.filesCount,
    required this.notesCount,
    required this.passwordsCount,
    required this.contactsCount,
  });
}

@Riverpod(keepAlive: true)
class DiContainer extends _$DiContainer {
  @override
  void build() {
    // Initialize dependencies here
  }
}

// Firebase App Provider - initializes in background
@Riverpod(keepAlive: true)
Future<FirebaseApp> firebaseApp(FirebaseAppRef ref) async {
  try {
    final app = await Firebase.initializeApp();
    AppLogger.info('Firebase initialized successfully');
    return app;
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize Firebase', e, stackTrace);
    rethrow;
  }
}

// Firebase Auth Provider - only signs in anonymously if no current user
@Riverpod(keepAlive: true)
Future<FirebaseAuth> firebaseAuth(FirebaseAuthRef ref) async {
  await ref.watch(firebaseAppProvider.future);
  
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      AppLogger.info('Firebase Auth initialized (anonymous)');
    } else {
      AppLogger.info('Firebase Auth already signed in');
    }
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize Firebase Auth', e, stackTrace);
  }
  
  return FirebaseAuth.instance;
}
