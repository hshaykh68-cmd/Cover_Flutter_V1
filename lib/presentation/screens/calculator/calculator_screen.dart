import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cover/presentation/screens/calculator/calculator_controller.dart';
import 'package:cover/core/pin/pin_state_machine.dart';
import 'package:cover/core/vault/vault_service.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:go_router/go_router.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  void _onButtonPressed(String value) {
    _triggerHaptic(value);
    ref.read(calculatorControllerProvider.notifier).onButtonPressed(value);
    
    // Check for PIN pattern after button press
    _checkForPinPattern();
  }

  void _triggerHaptic(String value) {
    if (value == 'C') {
      HapticFeedback.heavyImpact();
    } else if (['=', '+', '−', '×', '÷'].contains(value)) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _checkForPinPattern() async {
    final state = ref.read(calculatorControllerProvider);
    final pinStateMachine = ref.read(pinStateMachineProvider.notifier);

    final matched = pinStateMachine.processDisplay(state.display);

    if (matched) {
      final pinInfo = pinStateMachine.state;
      if (pinInfo.state == PinEntryState.matched) {
        // SECURITY FIX: Validate the PIN before opening vault
        final vaultService = await ref.read(vaultServiceProvider.future);
        final namespace = pinInfo.vaultType == VaultType.decoy
            ? VaultNamespace.decoy
            : VaultNamespace.real;
        final isValid = await vaultService.verifyPin(pinInfo.pin!, namespace: namespace);

        if (!isValid) {
          // PIN pattern matched but PIN is incorrect - record failed attempt
          await ref.read(pinStateMachineProvider.notifier).recordFailedAttempt();
          return;
        }

        // Navigate to vault based on vault type
        _navigateToVault(pinInfo.vaultType);
      }
    }
  }

  void _navigateToVault(VaultType vaultType) {
    // Add haptic feedback for successful unlock
    HapticFeedback.notificationFeedback(HapticFeedbackType.success);

    // Navigate to vault with vault type in extra (not URL) to prevent leak
    context.go('/vault', extra: {'vaultType': vaultType.name});

    // Reset calculator after navigation
    ref.read(calculatorControllerProvider.notifier).onButtonPressed('C');
    ref.read(pinStateMachineProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorControllerProvider);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Display area
            Expanded(
              flex: isLandscape ? 1 : 2,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Previous calculation
                    if (state.previousCalculation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          state.previousCalculation,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    // Current display
                    Semantics(
                      label: 'Result display',
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            ref.read(calculatorControllerProvider.notifier).deleteLastDigit();
                          }
                        },
                        child: AutoSizeText(
                          state.display,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: state.display == '0' ? FontWeight.w300 : FontWeight.w200,
                            letterSpacing: -1.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          minFontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Button grid
            Expanded(
              flex: isLandscape ? 3 : 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (isLandscape) ...[
                      _buildButtonRow(['sin', 'cos', 'tan', 'π'], state),
                      const SizedBox(height: 12),
                      _buildButtonRow(['√', 'x²', 'log', 'ln'], state),
                      const SizedBox(height: 12),
                    ],
                    _buildButtonRow(['C', '±', '%', '÷'], state),
                    const SizedBox(height: 12),
                    _buildButtonRow(['7', '8', '9', '×'], state),
                    const SizedBox(height: 12),
                    _buildButtonRow(['4', '5', '6', '−'], state),
                    const SizedBox(height: 12),
                    _buildButtonRow(['1', '2', '3', '+'], state),
                    const SizedBox(height: 12),
                    _buildBottomRow(state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons, CalculatorState state) {
    return Expanded(
      child: Row(
        children: buttons.map((value) {
          final isAccent = ['÷', '×', '−', '+'].contains(value);
          final isSecondary = ['C', '±', '%'].contains(value);
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: _CalculatorButton(
                value: value,
                isAccent: isAccent,
                isSecondary: isSecondary,
                onPressed: _onButtonPressed,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomRow(CalculatorState state) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 6.0, right: 0),
              child: _CalculatorButton(
                value: '0',
                isWide: true,
                onPressed: _onButtonPressed,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: _CalculatorButton(
                value: '.',
                onPressed: _onButtonPressed,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 0, right: 6.0),
              child: _CalculatorButton(
                value: '=',
                isAccent: true,
                onPressed: _onButtonPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateFontSize(String text) {
    if (text.length <= 8) return 72;
    if (text.length <= 12) return 56;
    if (text.length <= 16) return 48;
    return 40;
  }
}

class _CalculatorButton extends StatefulWidget {
  final String value;
  final bool isAccent;
  final bool isSecondary;
  final bool isWide;
  final VoidCallback onPressed;

  const _CalculatorButton({
    required this.value,
    this.isAccent = false,
    this.isSecondary = false,
    this.isWide = false,
    required this.onPressed,
  });

  @override
  State<_CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<_CalculatorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80), // DESIGN-003: Button press scale duration
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn), // DESIGN-003: Button press curve
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Semantics(
            label: widget.value == 'C' ? 'Clear' : widget.value,
            button: true,
            child: GestureDetector(
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _animationController.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _animationController.reverse().whenComplete(() {
                  // Additional release animation handled by reverse
                });
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _animationController.reverse();
              },
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                decoration: BoxDecoration(
                  color: _isPressed ? _getPressedColor() : _getButtonColor(),
                  shape: widget.isWide ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: widget.isWide ? BorderRadius.circular(40) : null,
                ),
                child: Center(
                  child: Text(
                    widget.value,
                    style: TextStyle(
                      color: widget.isSecondary ? Colors.black : Colors.white,
                      fontSize: widget.isWide ? 32 : 28,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getButtonColor() {
    if (widget.isAccent) {
      return const Color(0xFFFF9500); // iOS orange
    }
    if (widget.isSecondary) {
      return const Color(0xFFA5A5A5); // iOS gray
    }
    return const Color(0xFF333333); // iOS dark gray
  }

  Color _getPressedColor() {
    if (widget.isAccent) {
      return const Color(0xFFFFAD3B); // iOS orange active state
    }
    if (widget.isSecondary) {
      return const Color(0xFF8E8E93); // Darker gray when pressed
    }
    return const Color(0xFF2C2C2E); // Darker dark gray when pressed
  }
}
