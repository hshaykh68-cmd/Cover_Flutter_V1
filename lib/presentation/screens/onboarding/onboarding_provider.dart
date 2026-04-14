import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cover/core/di/di_container.dart';

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
    state = state.copyWith(primaryPin: pin);
  }

  Future<void> setDecoyPin(String pin) async {
    final pinRepository = ref.read(pinRepositoryProvider);
    await pinRepository.setDecoyPin(pin);
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
}
