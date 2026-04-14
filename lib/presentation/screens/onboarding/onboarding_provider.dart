import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/core/vault/vault_service.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/user_repository.dart';
import 'package:cover/domain/repository/pin_repository.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingState {
  final String? primaryPin;
  final String? decoyPin;
  final bool isComplete;

  OnboardingState({
    this.primaryPin,
    this.decoyPin,
    this.isComplete = false,
  });

  OnboardingState copyWith({
    String? primaryPin,
    String? decoyPin,
    bool? isComplete,
  }) {
    return OnboardingState(
      primaryPin: primaryPin ?? this.primaryPin,
      decoyPin: decoyPin ?? this.decoyPin,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref ref;

  OnboardingNotifier(this.ref) : super(OnboardingState());

  Future<void> setPrimaryPin(String pin) async {
    final pinRepository = ref.read(pinRepositoryProvider);
    await pinRepository.setPrimaryPin(pin);

    // SECURITY FIX: Also create User record with hashed PIN in SQLCipher
    await _createUserWithHashedPin(pin, VaultNamespace.real);

    state = state.copyWith(primaryPin: pin);
  }

  Future<void> setDecoyPin(String pin) async {
    final pinRepository = ref.read(pinRepositoryProvider);
    await pinRepository.setDecoyPin(pin);

    // SECURITY FIX: Also create User record with hashed PIN in SQLCipher
    await _createUserWithHashedPin(pin, VaultNamespace.decoy);

    state = state.copyWith(decoyPin: pin);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    state = state.copyWith(isComplete: true);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  /// Creates a User record with hashed PIN in the SQLCipher database
  /// This ensures the secure VaultService.verifyPin() system works correctly
  Future<void> _createUserWithHashedPin(String pin, VaultNamespace namespace) async {
    try {
      final vaultService = await ref.read(vaultServiceProvider.future);
      final userRepository = await ref.read(userRepositoryProvider.future);
      final cryptoService = ref.read(cryptoServiceProvider);

      // Ensure vault exists for this namespace
      final vaultId = await vaultService.ensureVaultExists(namespace);

      // Check if user already exists for this vault
      final existingUser = await userRepository.getUserByVaultId(vaultId);
      if (existingUser != null) {
        // User exists, update PIN
        final salt = cryptoService.generateRandomKey(length: 16);
        final pinHash = await cryptoService.hashPin(pin, salt);
        final saltBase64 = cryptoService.bytesToBase64(salt);
        await userRepository.updateUserPin(existingUser.id, pinHash, saltBase64);
      } else {
        // Create new user with hashed PIN
        final salt = cryptoService.generateRandomKey(length: 16);
        final pinHash = await cryptoService.hashPin(pin, salt);
        final saltBase64 = cryptoService.bytesToBase64(salt);

        final userCompanion = UsersCompanion(
          vaultId: Value(vaultId),
          pinHash: Value(pinHash),
          pinSalt: Value(saltBase64),
        );
        await userRepository.createUser(userCompanion);
      }
    } catch (e) {
      // Log error but don't fail onboarding - PinRepository still has the PIN
      // This maintains backward compatibility during transition
      print('Failed to create user with hashed PIN: $e');
    }
  }
}
