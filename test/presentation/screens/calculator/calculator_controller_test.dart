import 'package:flutter_test/flutter_test.dart';
import 'package:cover/presentation/screens/calculator/calculator_controller.dart';

void main() {
  group('CalculatorController', () {
    late CalculatorController controller;

    setUp(() {
      controller = CalculatorController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('Digit Input', () {
      test('should display single digit', () {
        controller.onButtonPressed('5');
        expect(controller.state.display, equals('5'));
      });

      test('should concatenate digits', () {
        controller.onButtonPressed('1');
        controller.onButtonPressed('2');
        controller.onButtonPressed('3');
        expect(controller.state.display, equals('123'));
      });

      test('should replace 0 with new digit', () {
        controller.onButtonPressed('0');
        controller.onButtonPressed('5');
        expect(controller.state.display, equals('5'));
      });

      test('should handle multiple digits', () {
        for (int i = 0; i < 10; i++) {
          controller.onButtonPressed(i.toString());
        }
        expect(controller.state.display, equals('0123456789'));
      });
    });

    group('Decimal Point', () {
      test('should add decimal point', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('.');
        expect(controller.state.display, equals('5.'));
      });

      test('should not add multiple decimal points', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('.');
        controller.onButtonPressed('.');
        expect(controller.state.display, equals('5.'));
      });

      test('should handle decimal with multiple digits', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('.');
        controller.onButtonPressed('2');
        controller.onButtonPressed('5');
        expect(controller.state.display, equals('5.25'));
      });
    });

    group('Addition', () {
      test('should add two numbers', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('3');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('8'));
      });

      test('should chain additions', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('3');
        controller.onButtonPressed('+');
        controller.onButtonPressed('2');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('10'));
      });

      test('should handle decimal addition', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('.');
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('3');
        controller.onButtonPressed('.');
        controller.onButtonPressed('5');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('9'));
      });
    });

    group('Subtraction', () {
      test('should subtract two numbers', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('−');
        controller.onButtonPressed('3');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('2'));
      });

      test('should handle negative result', () {
        controller.onButtonPressed('3');
        controller.onButtonPressed('−');
        controller.onButtonPressed('5');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('-2'));
      });

      test('should chain subtractions', () {
        controller.onButtonPressed('10');
        controller.onButtonPressed('−');
        controller.onButtonPressed('3');
        controller.onButtonPressed('−');
        controller.onButtonPressed('2');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('5'));
      });
    });

    group('Multiplication', () {
      test('should multiply two numbers', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('×');
        controller.onButtonPressed('3');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('15'));
      });

      test('should handle multiplication by zero', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('×');
        controller.onButtonPressed('0');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('0'));
      });

      test('should handle decimal multiplication', () {
        controller.onButtonPressed('2');
        controller.onButtonPressed('.');
        controller.onButtonPressed('5');
        controller.onButtonPressed('×');
        controller.onButtonPressed('4');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('10'));
      });
    });

    group('Division', () {
      test('should divide two numbers', () {
        controller.onButtonPressed('6');
        controller.onButtonPressed('÷');
        controller.onButtonPressed('2');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('3'));
      });

      test('should show error on division by zero', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('÷');
        controller.onButtonPressed('0');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('Error'));
      });

      test('should handle decimal division', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('÷');
        controller.onButtonPressed('2');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('2.5'));
      });
    });

    group('Clear', () {
      test('should clear display on C', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('3');
        controller.onButtonPressed('C');
        expect(controller.state.display, equals('0'));
        expect(controller.state.previousCalculation, isEmpty);
        expect(controller.state.pendingOperation, isNull);
      });

      test('should clear after calculation', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('3');
        controller.onButtonPressed('=');
        controller.onButtonPressed('C');
        expect(controller.state.display, equals('0'));
        expect(controller.state.currentValue, isNull);
      });
    });

    group('Toggle Sign', () {
      test('should toggle positive to negative', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('±');
        expect(controller.state.display, equals('-5'));
      });

      test('should toggle negative to positive', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('±');
        controller.onButtonPressed('±');
        expect(controller.state.display, equals('5'));
      });

      test('should toggle zero', () {
        controller.onButtonPressed('0');
        controller.onButtonPressed('±');
        expect(controller.state.display, equals('0'));
      });

      test('should toggle decimal', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('.');
        controller.onButtonPressed('5');
        controller.onButtonPressed('±');
        expect(controller.state.display, equals('-5.5'));
      });
    });

    group('Percentage', () {
      test('should convert to percentage', () {
        controller.onButtonPressed('50');
        controller.onButtonPressed('%');
        expect(controller.state.display, equals('0.5'));
      });

      test('should handle decimal percentage', () {
        controller.onButtonPressed('25');
        controller.onButtonPressed('.');
        controller.onButtonPressed('5');
        controller.onButtonPressed('%');
        expect(controller.state.display, equals('0.255'));
      });

      test('should handle zero percentage', () {
        controller.onButtonPressed('0');
        controller.onButtonPressed('%');
        expect(controller.state.display, equals('0'));
      });
    });

    group('Complex Calculations', () {
      test('should handle operation chaining', () {
        controller.onButtonPressed('2');
        controller.onButtonPressed('+');
        controller.onButtonPressed('3');
        controller.onButtonPressed('×');
        controller.onButtonPressed('4');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('20'));
      });

      test('should maintain precedence in chained operations', () {
        controller.onButtonPressed('10');
        controller.onButtonPressed('−');
        controller.onButtonPressed('2');
        controller.onButtonPressed('×');
        controller.onButtonPressed('3');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('4'));
      });

      test('should handle multiple operations', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('5');
        controller.onButtonPressed('=');
        controller.onButtonPressed('×');
        controller.onButtonPressed('2');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('20'));
      });
    });

    group('State Management', () {
      test('should track previous calculation', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('3');
        expect(controller.state.previousCalculation, equals('5 +'));
      });

      test('should update previous calculation on equals', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('3');
        controller.onButtonPressed('=');
        expect(controller.state.previousCalculation, equals('5 + 3 ='));
      });

      test('should reset new input flag after operation', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        expect(controller.state.isNewInput, isTrue);
        controller.onButtonPressed('3');
        expect(controller.state.isNewInput, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle very large numbers', () {
        controller.onButtonPressed('999999999');
        controller.onButtonPressed('+');
        controller.onButtonPressed('1');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('1000000000'));
      });

      test('should handle decimal result formatting', () {
        controller.onButtonPressed('1');
        controller.onButtonPressed('÷');
        controller.onButtonPressed('3');
        controller.onButtonPressed('=');
        expect(controller.state.display, isNotEmpty);
      });

      test('should handle consecutive operators', () {
        controller.onButtonPressed('5');
        controller.onButtonPressed('+');
        controller.onButtonPressed('−');
        controller.onButtonPressed('3');
        controller.onButtonPressed('=');
        expect(controller.state.display, equals('2'));
      });
    });
  });
}
