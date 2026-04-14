import 'package:flutter_test/flutter_test.dart';
import 'package:cover/core/pin/pin_pattern_detector.dart';

void main() {
  group('PinPatternDetector', () {
    late PinPatternDetector detector;

    setUp(() {
      detector = PinPatternDetector();
    });

    group('Pattern Detection', () {
      test('should detect real vault pattern', () {
        final match = detector.detectPattern('1234+0=');
        
        expect(match, isNotNull);
        expect(match!.vaultType, equals(VaultType.real));
        expect(match.pin, equals('1234'));
      });

      test('should detect decoy vault pattern', () {
        final match = detector.detectPattern('1234+1=');
        
        expect(match, isNotNull);
        expect(match!.vaultType, equals(VaultType.decoy));
        expect(match.pin, equals('1234'));
      });

      test('should not detect invalid patterns', () {
        expect(detector.detectPattern('1234+2='), isNull);
        expect(detector.detectPattern('1234+'), isNull);
        expect(detector.detectPattern('1234='), isNull);
        expect(detector.detectPattern('1234'), isNull);
      });

      test('should detect patterns with different PIN lengths', () {
        final match1 = detector.detectPattern('1+0=');
        expect(match1, isNotNull);
        expect(match1!.pin, equals('1'));

        final match2 = detector.detectPattern('123456789012+0=');
        expect(match2, isNotNull);
        expect(match2!.pin, equals('123456789012'));
      });

      test('should handle custom patterns', () {
        final customDetector = PinPatternDetector(
          realVaultPattern: '{pin}*5=',
          decoyVaultPattern: '{pin}*6=',
        );

        final match1 = customDetector.detectPattern('1234*5=');
        expect(match1, isNotNull);
        expect(match1!.vaultType, equals(VaultType.real));

        final match2 = customDetector.detectPattern('1234*6=');
        expect(match2, isNotNull);
        expect(match2!.vaultType, equals(VaultType.decoy));
      });
    });

    group('PIN Validation', () {
      test('should validate valid PINs', () {
        expect(detector.isValidPin('1234'), isTrue);
        expect(detector.isValidPin('123456'), isTrue);
        expect(detector.isValidPin('123456789012'), isTrue);
      });

      test('should reject empty PINs', () {
        expect(detector.isValidPin(''), isFalse);
      });

      test('should reject PINs below minimum length', () {
        expect(detector.isValidPin('123'), isFalse);
        expect(detector.isValidPin('12'), isFalse);
        expect(detector.isValidPin('1'), isFalse);
      });

      test('should reject PINs above maximum length', () {
        expect(detector.isValidPin('1234567890123'), isFalse);
      });

      test('should reject non-digit PINs', () {
        expect(detector.isValidPin('123a'), isFalse);
        expect(detector.isValidPin('abcd'), isFalse);
        expect(detector.isValidPin('12 34'), isFalse);
      });

      test('should validate with custom length constraints', () {
        expect(detector.isValidPin('1234', minLength: 4, maxLength: 6), isTrue);
        expect(detector.isValidPin('123456', minLength: 4, maxLength: 6), isTrue);
        expect(detector.isValidPin('123', minLength: 4, maxLength: 6), isFalse);
        expect(detector.isValidPin('1234567', minLength: 4, maxLength: 6), isFalse);
      });
    });

    group('Random PIN Generation', () {
      test('should generate PIN with default length', () {
        final pin = detector.generateRandomPin();
        expect(pin.length, equals(4));
        expect(detector.isValidPin(pin), isTrue);
      });

      test('should generate PIN with custom length', () {
        final pin = detector.generateRandomPin(length: 6);
        expect(pin.length, equals(6));
        expect(detector.isValidPin(pin), isTrue);
      });

      test('should generate different PINs', () {
        final pins = <String>{};
        for (int i = 0; i < 100; i++) {
          pins.add(detector.generateRandomPin());
        }
        expect(pins.length, greaterThan(1));
      });

      test('should generate valid PINs', () {
        for (int i = 0; i < 100; i++) {
          final pin = detector.generateRandomPin();
          expect(detector.isValidPin(pin), isTrue);
        }
      });
    });
  });
}
