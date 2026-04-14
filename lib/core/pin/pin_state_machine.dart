import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/core/pin/pin_pattern_detector.dart';
import 'package:cover/core/pin/pin_lockout_manager.dart';
import 'package:cover/core/utils/logger.dart';

enum PinEntryState {
  idle,
  entering,
  matched,
  failed,
}

class PinStateInfo {
  final PinEntryState state;
  final VaultType vaultType;
  final String? pin;
  final String display;

  const PinStateInfo({
    required this.state,
    required this.vaultType,
    this.pin,
    required this.display,
  });

  PinStateInfo copyWith({
    PinEntryState? state,
    VaultType? vaultType,
    String? pin,
    String? display,
  }) {
    return PinStateInfo(
      state: state ?? this.state,
      vaultType: vaultType ?? this.vaultType,
      pin: pin ?? this.pin,
      display: display ?? this.display,
    );
  }
}

class PinStateMachine extends StateNotifier<PinStateInfo> {
  final PinPatternDetector _detector;
  final PinLockoutManager _lockoutManager;

  PinStateMachine({
    PinPatternDetector? detector,
    PinLockoutManager? lockoutManager,
  })  : _detector = detector ?? PinPatternDetector(),
        _lockoutManager = lockoutManager ?? PinLockoutManager(),
        super(const PinStateInfo(
          state: PinEntryState.idle,
          vaultType: VaultType.none,
          display: '0',
        ));

  /// Processes a calculator display update
  /// 
  /// Returns true if a PIN pattern was detected, false otherwise
  bool processDisplay(String display) {
    // Check if locked out
    if (_lockoutManager.isLocked()) {
      AppLogger.warning('Vault is locked out');
      state = state.copyWith(
        state: PinEntryState.failed,
        display: display,
      );
      return false;
    }

    // Detect PIN pattern
    final match = _detector.detectPattern(display);
    
    if (match != null) {
      // Pattern detected
      if (_detector.isValidPin(match.pin)) {
        state = state.copyWith(
          state: PinEntryState.matched,
          vaultType: match.vaultType,
          pin: match.pin,
          display: display,
        );
        
        // Reset failed attempts on successful match
        _lockoutManager.resetFailedAttempts();
        
        AppLogger.info('PIN pattern detected: ${match.vaultType} vault');
        return true;
      } else {
        // Invalid PIN length
        AppLogger.warning('Invalid PIN detected: ${match.pin}');
        state = state.copyWith(
          state: PinEntryState.failed,
          display: display,
        );
        return false;
      }
    } else {
      // No pattern detected, update display
      state = state.copyWith(
        state: PinEntryState.entering,
        display: display,
      );
      return false;
    }
  }

  /// Records a failed PIN attempt
  Future<void> recordFailedAttempt({String? vaultId}) async {
    await _lockoutManager.recordFailedAttempt(vaultId: vaultId);
    state = state.copyWith(state: PinEntryState.failed);
  }

  /// Resets the state machine to idle
  void reset() {
    state = state.copyWith(
      state: PinEntryState.idle,
      vaultType: VaultType.none,
      pin: null,
      display: '0',
    );
  }

  /// Gets the current lockout info
  LockoutInfo getLockoutInfo() {
    return _lockoutManager.state;
  }

  /// Checks if the vault is locked out
  bool isLocked() {
    return _lockoutManager.isLocked();
  }

  /// Gets the remaining lockout time
  Duration? getRemainingLockoutTime() {
    return _lockoutManager.getRemainingLockoutTime();
  }

  /// Forces a lockout (for testing)
  void forceLockout() {
    _lockoutManager.forceLockout();
  }

  /// Unlocks the vault (for testing)
  void unlock() {
    _lockoutManager.unlock();
  }
}

// Provider for PIN state machine
final pinStateMachineProvider = StateNotifierProvider<PinStateMachine, PinStateInfo>((ref) {
  return PinStateMachine();
});

// Provider for lockout manager (separate for direct access if needed)
final pinLockoutManagerProvider = Provider<PinLockoutManager>((ref) {
  final stateMachine = ref.watch(pinStateMachineProvider.notifier);
  // Access the lockout manager through the state machine
  // This is a workaround since we can't directly expose it
  return stateMachine._lockoutManager;
});
