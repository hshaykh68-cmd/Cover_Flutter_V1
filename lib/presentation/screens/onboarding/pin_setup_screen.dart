import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:cover/presentation/screens/onboarding/onboarding_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;

  void _onNumberPressed(String number) {
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }

    HapticFeedback.selectionClick();

    if (!_isConfirming) {
      if (_pin.length < 4) {
        setState(() {
          _pin += number;
        });

        if (_pin.length == 4) {
          // Move to confirmation after brief delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isConfirming = true;
              });
            }
          });
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += number;
        });

        if (_confirmPin.length == 4) {
          _validatePin();
        }
      }
    }
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_hasError) {
        _hasError = false;
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      } else if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (_isConfirming && _confirmPin.isEmpty) {
        _isConfirming = false;
      }
    });
  }

  void _validatePin() {
    if (_pin == _confirmPin) {
      HapticFeedback.notificationFeedback(HapticFeedbackType.success);
      // Save PIN and navigate to next screen
      ref.read(onboardingProvider.notifier).setPrimaryPin(_pin);
      context.go('/onboarding/calculator-trick');
    } else {
      HapticFeedback.notificationFeedback(HapticFeedbackType.error);
      setState(() {
        _hasError = true;
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    _isConfirming ? 'Confirm Your PIN' : 'Set Your Secret PIN',
                    style: AppTheme.title2.copyWith(
                      color: AppTheme.label,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isConfirming
                        ? 'Enter the same PIN again'
                        : 'This PIN unlocks your real vault',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.secondaryLabel,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // PIN dots indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  final isActive = !_isConfirming
                      ? index < _pin.length
                      : index < _confirmPin.length;
                  final isError = _hasError && index == 3;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isError
                          ? AppTheme.systemRed
                          : isActive
                              ? AppTheme.systemBlue
                              : AppTheme.tertiaryBackground,
                      border: Border.all(
                        color: isActive || isError
                            ? Colors.transparent
                            : AppTheme.separator,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_hasError) ...[
              const SizedBox(height: 16),
              Text(
                'PINs did not match. Try again.',
                style: AppTheme.callout.copyWith(
                  color: AppTheme.systemRed,
                ),
              ),
            ],

            const Spacer(),

            // Custom numpad (NOT calculator style)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildNumpadRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _buildNumpadRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _buildNumpadRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  _buildNumpadBottomRow(),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> numbers) {
    return Row(
      children: numbers.map((number) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _NumpadButton(
              number: number,
              onPressed: () => _onNumberPressed(number),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumpadBottomRow() {
    return Row(
      children: [
        const Expanded(child: SizedBox()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _NumpadButton(
              number: '0',
              onPressed: () => _onNumberPressed('0'),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _DeleteButton(
              onPressed: _onDelete,
            ),
          ),
        ),
      ],
    );
  }
}

class _NumpadButton extends StatefulWidget {
  final String number;
  final VoidCallback onPressed;

  const _NumpadButton({
    required this.number,
    required this.onPressed,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.tertiaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  widget.number,
                  style: AppTheme.title1.copyWith(
                    color: AppTheme.label,
                    fontSize: 32,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _DeleteButton({required this.onPressed});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.tertiaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.backspace,
                  size: 28,
                  color: AppTheme.secondaryLabel,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
