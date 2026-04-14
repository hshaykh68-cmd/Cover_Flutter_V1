import 'dart:math';

enum VaultType {
  real,
  decoy,
  none,
}

class PinPatternMatch {
  final VaultType vaultType;
  final String pin;

  const PinPatternMatch({
    required this.vaultType,
    required this.pin,
  });
}

class PinPatternDetector {
  final String _realVaultPattern;
  final String _decoyVaultPattern;

  // TODO: BUG-013 - Patterns should be fetched from Firebase Remote Config at runtime
  // instead of being hard-coded in the binary to prevent decompilation.
  // Implement Firebase Remote Config integration to fetch these patterns dynamically.
  // Also consider allowing users to configure custom unlock sequences.
  // Enable ProGuard/R8 obfuscation: flutter build apk --obfuscate --split-debug-info=./debug_info/
  PinPatternDetector({
    String realVaultPattern = '{pin}+0=',
    String decoyVaultPattern = '{pin}+1=',
  })  : _realVaultPattern = realVaultPattern,
        _decoyVaultPattern = decoyVaultPattern;

  /// Detects if the calculator display matches a PIN pattern
  /// 
  /// Returns a PinPatternMatch if a pattern is detected, null otherwise
  PinPatternMatch? detectPattern(String display) {
    // Try to match real vault pattern
    final realMatch = _matchPattern(display, _realVaultPattern);
    if (realMatch != null) {
      return PinPatternMatch(
        vaultType: VaultType.real,
        pin: realMatch,
      );
    }

    // Try to match decoy vault pattern
    final decoyMatch = _matchPattern(display, _decoyVaultPattern);
    if (decoyMatch != null) {
      return PinPatternMatch(
        vaultType: VaultType.decoy,
        pin: decoyMatch,
      );
    }

    return null;
  }

  /// Attempts to match a pattern against the display
  /// 
  /// Returns the extracted PIN if matched, null otherwise
  String? _matchPattern(String display, String pattern) {
    // Step 1: Split on the placeholder
    final parts = pattern.split('{pin}');
    
    // Step 2: Escape each static part individually
    String escapeRegex(String s) =>
        s.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');
    
    final escapedPrefix = escapeRegex(parts[0]);
    final escapedSuffix = parts.length > 1 ? escapeRegex(parts[1]) : '';
    
    // Step 3: Compose with the capture group intact
    final regex = RegExp('^$escapedPrefix(\\d{4,12})$escapedSuffix\$');
    final match = regex.firstMatch(display);
    return match?.group(1);
  }

  /// Validates if a PIN is valid
  /// 
  /// PIN must be 4-12 digits (configurable via Remote Config)
  bool isValidPin(String pin, {int minLength = 4, int maxLength = 12}) {
    if (pin.isEmpty) return false;
    if (pin.length < minLength) return false;
    if (pin.length > maxLength) return false;
    
    // Check if all characters are digits
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  /// Generates a random PIN for testing or setup
  String generateRandomPin({int length = 4}) {
    final random = Random.secure();
    final pin = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      pin.write(random.nextInt(10));
    }
    
    return pin.toString();
  }
}
