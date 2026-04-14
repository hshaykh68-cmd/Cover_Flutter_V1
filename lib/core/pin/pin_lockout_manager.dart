import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/core/intruder/intruder_detection_service.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/utils/logger.dart';

enum LockoutState {
  unlocked,
  locked,
}

class LockoutInfo {
  final LockoutState state;
  final DateTime? lockoutStartTime;
  final Duration? remainingTime;
  final int failedAttempts;
  final int maxAttempts;

  const LockoutInfo({
    required this.state,
    this.lockoutStartTime,
    this.remainingTime,
    required this.failedAttempts,
    required this.maxAttempts,
  });

  LockoutInfo copyWith({
    LockoutState? state,
    DateTime? lockoutStartTime,
    Duration? remainingTime,
    int? failedAttempts,
    int? maxAttempts,
  }) {
    return LockoutInfo(
      state: state ?? this.state,
      lockoutStartTime: lockoutStartTime ?? this.lockoutStartTime,
      remainingTime: remainingTime ?? this.remainingTime,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
  }
}

class PinLockoutManager extends StateNotifier<LockoutInfo> {
  final int maxAttempts;
  final SecureKeyStorage _secureStorage;
  final Duration lockoutDuration;
  Timer? _lockoutTimer;
  IntruderDetectionService? _intruderDetectionService;

  PinLockoutManager({
    this.maxAttempts = 3,
    required SecureKeyStorage secureStorage,
    this.lockoutDuration = const Duration(minutes: 15),
    IntruderDetectionService? intruderDetectionService,
  })  : _secureStorage = secureStorage,
        super(const LockoutInfo(
          state: LockoutState.unlocked,
          failedAttempts: 0,
          maxAttempts: 3,
        )) {
    _intruderDetectionService = intruderDetectionService;
    _loadPersistedState();
  }

  /// Set the intruder detection service (for DI)
  void setIntruderDetectionService(IntruderDetectionService service) {
    _intruderDetectionService = service;
  }

  Future<void> _loadPersistedState() async {
    try {
      final attempts = await _secureStorage.retrieveString('lockout_attempts');
      final lockoutTime = await _secureStorage.retrieveString('lockout_start');
      if (attempts != null && lockoutTime != null) {
        final n = int.tryParse(attempts) ?? 0;
        final t = DateTime.tryParse(lockoutTime);
        if (n >= maxAttempts && t != null) {
          await _lockout(fromTime: t);
        } else {
          state = state.copyWith(failedAttempts: n);
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to load persisted lockout state', e, st);
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  /// Records a failed PIN attempt
  Future<void> recordFailedAttempt({String? vaultId}) async {
    final newAttempts = state.failedAttempts + 1;
    
    // Record with intruder detection service
    if (_intruderDetectionService != null && _intruderDetectionService!.isEnabled) {
      final shouldCapture = await _intruderDetectionService!.recordWrongAttempt(vaultId: vaultId);
      
      if (shouldCapture) {
        // Fire-and-forget — do NOT await, keeps UI responsive
        unawaited(
          _intruderDetectionService!.captureIntruderEvidence(
            vaultId: vaultId,
            eventType: 'wrong_pin',
          ),
        );
      }
    }
    
    if (newAttempts >= maxAttempts) {
      await _lockout(vaultId: vaultId);
    } else {
      state = state.copyWith(
        failedAttempts: newAttempts,
      );
      await _secureStorage.storeString('lockout_attempts', newAttempts.toString());
      AppLogger.warning('Failed PIN attempt: $newAttempts/$maxAttempts');
    }
  }

  /// Resets failed attempts (called on successful PIN entry)
  Future<void> resetFailedAttempts() async {
    state = state.copyWith(
      failedAttempts: 0,
      state: LockoutState.unlocked,
    );
    _lockoutTimer?.cancel();
    
    // Clear persisted values
    await _secureStorage.deleteKey('lockout_attempts');
    await _secureStorage.deleteKey('lockout_start');
    
    // Reset intruder attempt counter
    if (_intruderDetectionService != null) {
      await _intruderDetectionService!.resetAttemptCounter();
    }
    
    AppLogger.debug('Failed attempts reset');
  }

  /// Checks if the app is currently locked out
  bool isLocked() {
    _checkLockoutExpiry();
    return state.state == LockoutState.locked;
  }

  /// Gets the remaining lockout time
  Duration? getRemainingLockoutTime() {
    _checkLockoutExpiry();
    return state.remainingTime;
  }

  /// Forces a lockout (for manual lockout or testing)
  Future<void> forceLockout({String? vaultId}) async {
    await _lockout(vaultId: vaultId);
  }

  /// Unlocks the vault (for testing or admin override)
  Future<void> unlock() async {
    _lockoutTimer?.cancel();
    state = state.copyWith(
      state: LockoutState.unlocked,
      failedAttempts: 0,
      remainingTime: null,
      lockoutStartTime: null,
    );
    
    // Clear persisted values
    await _secureStorage.deleteKey('lockout_attempts');
    await _secureStorage.deleteKey('lockout_start');
  }

  Future<void> _lockout({String? vaultId, DateTime? fromTime}) async {
    _lockoutTimer?.cancel();
    final startTime = fromTime ?? DateTime.now();
    
    state = state.copyWith(
      state: LockoutState.locked,
      failedAttempts: maxAttempts,
      lockoutStartTime: startTime,
      remainingTime: lockoutDuration,
    );
    
    await _secureStorage.storeString('lockout_attempts', maxAttempts.toString());
    await _secureStorage.storeString('lockout_start', startTime.toIso8601String());
    
    AppLogger.warning('Vault locked for ${lockoutDuration.inMinutes} minutes');
    
    // Start timer to auto-unlock
    _lockoutTimer = Timer(lockoutDuration, () {
      unlock();
      AppLogger.debug('Lockout period expired');
    });
  }

  void _checkLockoutExpiry() {
    if (state.state == LockoutState.locked && state.lockoutStartTime != null) {
      final elapsed = DateTime.now().difference(state.lockoutStartTime!);
      
      if (elapsed >= lockoutDuration) {
        unlock();
      } else {
        final remaining = lockoutDuration - elapsed;
        state = state.copyWith(remainingTime: remaining);
      }
    }
  }
}
