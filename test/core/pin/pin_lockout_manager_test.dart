import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/pin/pin_lockout_manager.dart';

void main() {
  group('PinLockoutManager', () {
    late PinLockoutManager manager;

    setUp(() {
      manager = PinLockoutManager(
        maxAttempts: 3,
        lockoutDuration: const Duration(milliseconds: 100),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    group('Failed Attempts', () {
      test('should track failed attempts', () {
        manager.recordFailedAttempt();
        expect(manager.state.failedAttempts, equals(1));

        manager.recordFailedAttempt();
        expect(manager.state.failedAttempts, equals(2));
      });

      test('should lock out after max attempts', () {
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();

        expect(manager.isLocked(), isTrue);
        expect(manager.state.state, equals(LockoutState.locked));
      });

      test('should reset failed attempts on success', () {
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();
        manager.resetFailedAttempts();

        expect(manager.state.failedAttempts, equals(0));
        expect(manager.state.state, equals(LockoutState.unlocked));
      });
    });

    group('Lockout Behavior', () {
      test('should be unlocked initially', () {
        expect(manager.isLocked(), isFalse);
        expect(manager.state.state, equals(LockoutState.unlocked));
      });

      test('should lock after max attempts', () {
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();

        expect(manager.isLocked(), isTrue);
        expect(manager.state.state, equals(LockoutState.locked));
      });

      test('should unlock after lockout duration', () async {
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();

        expect(manager.isLocked(), isTrue);

        await Future.delayed(const Duration(milliseconds: 150));

        expect(manager.isLocked(), isFalse);
      });

      test('should show remaining lockout time', () async {
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();
        manager.recordFailedAttempt();

        expect(manager.isLocked(), isTrue);
        expect(manager.getRemainingLockoutTime(), isNotNull);

        await Future.delayed(const Duration(milliseconds: 50));

        final remaining = manager.getRemainingLockoutTime();
        expect(remaining!.inMilliseconds, lessThan(100));
        expect(remaining.inMilliseconds, greaterThan(0));
      });
    });

    group('Manual Lockout Control', () {
      test('should force lockout', () {
        manager.forceLockout();

        expect(manager.isLocked(), isTrue);
        expect(manager.state.state, equals(LockoutState.locked));
      });

      test('should unlock manually', () {
        manager.forceLockout();
        expect(manager.isLocked(), isTrue);

        manager.unlock();
        expect(manager.isLocked(), isFalse);
      });

      test('should unlock after forced lockout', () async {
        manager.forceLockout();

        await Future.delayed(const Duration(milliseconds: 150));

        expect(manager.isLocked(), isFalse);
      });
    });

    group('Custom Configuration', () {
      test('should use custom max attempts', () {
        final customManager = PinLockoutManager(
          maxAttempts: 5,
          lockoutDuration: const Duration(milliseconds: 100),
        );

        for (int i = 0; i < 4; i++) {
          customManager.recordFailedAttempt();
        }
        expect(customManager.isLocked(), isFalse);

        customManager.recordFailedAttempt();
        expect(customManager.isLocked(), isTrue);

        customManager.dispose();
      });

      test('should use custom lockout duration', () async {
        final customManager = PinLockoutManager(
          maxAttempts: 1,
          lockoutDuration: const Duration(milliseconds: 50),
        );

        customManager.recordFailedAttempt();
        expect(customManager.isLocked(), isTrue);

        await Future.delayed(const Duration(milliseconds: 75));
        expect(customManager.isLocked(), isFalse);

        customManager.dispose();
      });
    });
  });
}
