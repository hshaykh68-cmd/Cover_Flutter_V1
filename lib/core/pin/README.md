# PIN Pattern Detection

## Overview

The PIN Pattern Detection module provides secure PIN-based vault unlocking through calculator pattern matching. Users enter their PIN disguised as a calculator equation, and the system detects the pattern to unlock the appropriate vault (real or decoy).

## Components

### PinPatternDetector

Pattern parser that detects PIN patterns in calculator display strings.

**Key Features:**
- Configurable PIN patterns (default: `{pin}+0=` for real vault, `{pin}+1=` for decoy vault)
- Regex-based pattern matching
- PIN validation (4-12 digits, configurable)
- Random PIN generation for testing/setup

### PinLockoutManager

Manages lockout behavior after failed PIN attempts.

**Key Features:**
- Configurable max attempts (default: 3)
- Configurable lockout duration (default: 15 minutes)
- Automatic lockout after max attempts
- Auto-unlock after lockout period expires
- Failed attempt tracking
- Manual lockout/unlock for testing

### PinStateMachine

State machine that tracks PIN entry and coordinates with lockout manager.

**Key Features:**
- Tracks PIN entry state (idle, entering, matched, failed)
- Coordinates pattern detection with lockout manager
- Resets failed attempts on successful match
- Lockout state awareness
- Vault type detection (real vs decoy)

## PIN Patterns

### Default Patterns

- **Real Vault**: `{pin}+0=` (e.g., `1234+0=`)
- **Decoy Vault**: `{pin}+1=` (e.g., `1234+1=`)

### Pattern Format

Patterns use the `{pin}` placeholder which is replaced with a regex for digits. The pattern must match the entire calculator display.

**Examples:**
- `{pin}+0=` matches `1234+0=`
- `{pin}*5=` matches `5678*5=`
- `{pin}-9=` matches `4321-9=`

## Usage

### Detecting PIN Pattern

```dart
final detector = PinPatternDetector();
final match = detector.detectPattern('1234+0=');

if (match != null) {
  print('Vault: ${match.vaultType}'); // VaultType.real
  print('PIN: ${match.pin}'); // 1234
}
```

### Using State Machine

```dart
final stateMachine = ref.watch(pinStateMachineProvider.notifier);
final matched = stateMachine.processDisplay('1234+0=');

if (matched && stateMachine.state.vaultType == VaultType.real) {
  // Unlock real vault
}
```

### Checking Lockout Status

```dart
final stateMachine = ref.watch(pinStateMachineProvider.notifier);

if (stateMachine.isLocked()) {
  final remaining = stateMachine.getRemainingLockoutTime();
  print('Locked for ${remaining?.inMinutes} minutes');
}
```

### Recording Failed Attempt

```dart
final stateMachine = ref.watch(pinStateMachineProvider.notifier);
stateMachine.recordFailedAttempt();
```

## Security Properties

1. **Pattern-Based Detection**: PIN entry disguised as calculator operations
2. **Lockout Protection**: Automatic lockout after failed attempts
3. **Configurable Limits**: Max attempts and lockout duration configurable via Remote Config
4. **Vault Differentiation**: Separate patterns for real and decoy vaults
5. **No Visual Tell**: Calculator functions normally during PIN entry

## Testing

Unit tests are located in:
- `test/core/pin/pin_pattern_detector_test.dart`
- `test/core/pin/pin_lockout_manager_test.dart`
- `test/core/pin/pin_state_machine_test.dart`

**Test Coverage:**
- Pattern detection for real and decoy vaults
- Invalid pattern handling
- PIN validation
- Random PIN generation
- Lockout behavior
- Failed attempt tracking
- State machine transitions
- Lockout expiry

## Dependencies

- `crypto_service` - For PIN hashing (future implementation)
- Riverpod - For state management

## DI Integration

The PIN detection modules are wired up in `lib/core/di/di_container.dart`:

```dart
@Riverpod(keepAlive: true)
PinStateMachine pinStateMachine(PinStateMachineRef ref) {
  return PinStateMachine();
}
```

## Remote Config Integration

The following parameters are intended to be controlled via Firebase Remote Config:

```json
{
  "pin_pattern": "{pin}+0=",
  "decoy_pin_pattern": "{pin}+1=",
  "max_pin_attempts_before_lockout": 3,
  "lockout_duration_minutes": 15,
  "min_pin_length": 4,
  "max_pin_length": 12
}
```

## Future Enhancements

- PIN hashing and storage
- Biometric unlock integration
- Pattern customization via Remote Config
- Intruder detection integration
- Failed attempt logging
