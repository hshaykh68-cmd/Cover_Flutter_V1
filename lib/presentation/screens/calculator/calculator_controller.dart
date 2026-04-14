import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalculatorState {
  final String display;
  final String previousCalculation;
  final double? currentValue;
  final String? pendingOperation;
  final bool isNewInput;
  final bool isResultDisplayed;

  const CalculatorState({
    this.display = '0',
    this.previousCalculation = '',
    this.currentValue,
    this.pendingOperation,
    this.isNewInput = true,
    this.isResultDisplayed = false,
  });

  CalculatorState copyWith({
    String? display,
    String? previousCalculation,
    double? currentValue,
    String? pendingOperation,
    bool? isNewInput,
    bool? isResultDisplayed,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      previousCalculation: previousCalculation ?? this.previousCalculation,
      currentValue: currentValue ?? this.currentValue,
      pendingOperation: pendingOperation ?? this.pendingOperation,
      isNewInput: isNewInput ?? this.isNewInput,
      isResultDisplayed: isResultDisplayed ?? this.isResultDisplayed,
    );
  }
}

class CalculatorController extends StateNotifier<CalculatorState> {
  CalculatorController() : super(const CalculatorState());

  void onButtonPressed(String value) {
    if (_isDigit(value)) {
      _handleDigit(value);
    } else if (_isOperator(value)) {
      _handleOperator(value);
    } else if (value == '=') {
      _handleEquals();
    } else if (value == 'C') {
      _handleClear();
    } else if (value == '±') {
      _handleToggleSign();
    } else if (value == '%') {
      _handlePercentage();
    } else if (value == '.') {
      _handleDecimal();
    }
  }

  bool _isDigit(String value) {
    return RegExp(r'^[0-9]$').hasMatch(value);
  }

  bool _isOperator(String value) {
    return ['+', '−', '×', '÷'].contains(value);
  }

  void _handleDigit(String digit) {
    String newDisplay;
    if (state.isNewInput) {
      newDisplay = digit;
    } else {
      newDisplay = state.display == '0' ? digit : state.display + digit;
    }
  isResultDisplayed: false,
    
    state = state.copyWith(
      display: newDisplay,
      isNewInput: false,
    );
  }

  void _handleOperator(String operator) {
    final currentValue = double.tryParse(state.display);
    if (currentValue == null) return;

    if (state.pendingOperation != null) {
      // Calculate previous operation first
      _calculateResult();
    }

    state = state.copyWith(
      currentValue: currentValue,
      pendingOperation: operator,
      previousCalculation: '${_formatNumber(currentValue)} $operator',
      isNewInput: true,
    );
  }

  void _handleEquals() {
    if (state.pendingOperation == null) return;
    _calculateResult();
  }

  void _calculateResult() {
    final currentValue = double.tryParse(state.display);
    if (currentValue == null || state.currentValue == null || state.pendingOperation == null) {
      return;
    }

    double result;
    switch (state.pendingOperation) {
      case '+':
        result = state.currentValue! + currentValue;
        break;
      case '−':
        result = state.currentValue! - currentValue;
        break;
      case '×':
        result = state.currentValue! * currentValue;
        break;
      case '÷':
        if (currentValue == 0) {
          state = state.copyWith(
            display: 'Error',
            isNewInput: true,
          );
          return;
        }
        result = state.currentValue! / currentValue;
        break;
      default:
        return;
    }

    state = state.copyWith(
      display: _formatNumber(result),
      isResultDisplayed: true,
      previousCalculation: '${_formatNumber(state.currentValue!)} ${state.pendingOperation} ${_formatNumber(currentValue)} =',
      currentValue: result,
      pendingOperation: null,
      isNewInput: true,
    );
  }

  void _handleClear() {
    state = const CalculatorState();
  }

  void _handleToggleSign() {
    final value = double.tryParse(state.display);
    if (value == null) return;

    final newValue = -value;
    state = state.copyWith(
      display: _formatNumber(newValue),
    );
  }

  void _handlePercentage() {
    final value = double.tryParse(state.display);
    if (value == null) return;

    final newValue = value / 100;
    state = state.copyWith(
      display: _formatNumber(newValue),
    );
  }

  void _handleDecimal() {
    if (state.display.contains('.')) return;

    state = state.copyWith(
      display: state.display + '.',
      isNewInput: false,
    );
  }

  void deleteLastDigit() {
    if (state.display.length <= 1 || state.display == 'Error') {
      state = state.copyWith(display: '0');
      return;
    }

    String newDisplay = state.display.substring(0, state.display.length - 1);
    if (newDisplay.isEmpty || newDisplay == '-') {
      newDisplay = '0';
    }

    state = state.copyWith(
      display: newDisplay,
    );
  }

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    
    // Remove trailing zeros after decimal point
    String formatted = value.toString();
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
    }
    
    return formatted;
  }
}

final calculatorControllerProvider = StateNotifierProvider<CalculatorController, CalculatorState>((ref) {
  return CalculatorController();
});
