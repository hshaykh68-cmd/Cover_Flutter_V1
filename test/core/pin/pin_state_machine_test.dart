import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/pin/pin_state_machine.dart';

void main() {
  group('PinStateMachine', () {
    late PinStateMachine stateMachine;

    setUp(() {
      stateMachine = PinStateMachine();
    });

    tearDown(() {
      stateMachine.dispose();
    });

    group('Pattern Detection', () {
      test('should detect real vault pattern', () {
        final matched = stateMachine.processDisplay('1234+0=');
        
        expect(matched, isTrue);
        expect(stateMachine.state.vaultType, equals(VaultType.real));
        expect(stateMachine.state.pin, equals('1234'));
      });

      test('should detect decoy vault pattern', () {
        final matched = stateMachine.processDisplay('1234+1=');
        
        expect(matched, isTrue);
        expect(stateMachine.state.vaultType, equals(VaultType.decoy));
        expect(stateMachine.state.pin, equals('1234'));
      });

      test('should not detect invalid patterns', () {
        final matched1 = stateMachine.processDisplay('1234+2=');
        expect(matched1, isFalse);

        final matched2 = stateMachine.processDisplay('1234+');
        expect(matched2, isFalse);

        final matched3 = stateMachine.processDisplay('1234');
        expect(matched3, isFalse);
      });

      test('should track display updates', () {
        stateMachine.processDisplay('5');
        expect(stateMachine.state.display, equals('5'));

        stateMachine.processDisplay('53');
        expect(stateMachine.state.display, equals('53'));
      });

      test('should reset state', () {
        stateMachine.processDisplay('1234+0=');
        expect(stateMachine.state.state, equals(PinEntryState.matched));

        stateMachine.reset();
        expect(stateMachine.state.state, equals(PinEntryState.idle));
        expect(stateMachine.state.vaultType, equals(VaultType.none));
        expect(stateMachine.state.pin, isNull);
        expect(stateMachine.state.display, equals('0'));
      });
    });

    group('Lockout Integration', () {
      test('should respect lockout state', () {
        stateMachine.forceLockout();
        expect(stateMachine.isLocked(), isTrue);

        final matched = stateMachine.processDisplay('1234+0=');
        expect(matched, isFalse);
        expect(stateMachine.state.state, equals(PinEntryState.failed));
      });

      test('should unlock after lockout expires', () async {
        stateMachine.forceLockout();
        expect(stateMachine.isLocked(), isTrue);

        await Future.delayed(const Duration(milliseconds: 150));

        expect(stateMachine.isLocked(), isFalse);

        final matched = stateMachine.processDisplay('1234+0=');
        expect(matched, isTrue);
      });

      test('should reset failed attempts on successful match', () {
        stateMachine.forceLockout();
        stateMachine.unlock();
        stateMachine.recordFailedAttempt();

        stateMachine.processDisplay('1234+0=');
        expect(stateMachine.getLockoutInfo().failedAttempts, equals(0));
      });
    });

    group('Lockout Control', () {
      test('should force lockout', () {
        stateMachine.forceLockout();
        expect(stateMachine.isLocked(), isTrue);
      });

      test('should unlock', () {
        stateMachine.forceLockout();
        expect(stateMachine.isLocked(), isTrue);

        stateMachine.unlock();
        expect(stateMachine.isLocked(), isFalse);
      });

      test('should get remaining lockout time', () async {
        stateMachine.forceLockout();
        
        final remaining = stateMachine.getRemainingLockoutTime();
        expect(remaining, isNotNull);

        await Future.delayed(const Duration(milliseconds: 50));
        
        final remainingAfter = stateMachine.getRemainingLockoutTime();
        expect(remainingAfter!.inMilliseconds, lessThan(remaining!.inMilliseconds));
      });
    });

    group('Failed Attempts', () {
      test('should record failed attempts', () {
        stateMachine.recordFailedAttempt();
        expect(stateMachine.getLockoutInfo().failedAttempts, equals(1));

        stateMachine.recordFailedAttempt();
        expect(stateMachine.getLockoutInfo().failedAttempts, equals(2));
      });

      test('should lock out after max attempts', () {
        stateMachine.recordFailedAttempt();
        stateMachine.recordFailedAttempt();
        stateMachine.recordFailedAttempt();

        expect(stateMachine.isLocked(), isTrue);
      });
    });

    group('Custom Configuration', () {
      test('should use custom lockout manager', () {
        final customLockoutManager = PinLockoutManager(
          maxAttempts: 5,
          lockoutDuration: const Duration(milliseconds: 100),
        );

        final customStateMachine = PinStateMachine(
          lockoutManager: customLockoutManager,
        );

        for (int i = 0; i < 4; i++) {
          customStateMachine.recordFailedAttempt();
        }
        expect(customStateMachine.isLocked(), isFalse);

        customStateMachine.recordFailedAttempt();
        expect(customStateMachine.isLocked(), isTrue);

        customStateMachine.dispose();
      });

      test('should use custom pattern detector', () {
        final customDetector = PinPatternDetector(
          realVaultPattern: '{pin}*5=',
          decoyVaultPattern: '{pin}*6=',
        );

        final customStateMachine = PinStateMachine(
          detector: customDetector,
        );

        final matched = customStateMachine.processDisplay('1234*5=');
        expect(matched, isTrue);
        expect(customStateMachine.state.vaultType, equals(VaultType.real));

        customStateMachine.dispose();
      });
    });
  });
}
