import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:cover/presentation/screens/onboarding/onboarding_provider.dart';

class CalculatorTrickScreen extends ConsumerStatefulWidget {
  const CalculatorTrickScreen({super.key});

  @override
  ConsumerState<CalculatorTrickScreen> createState() =>
      _CalculatorTrickScreenState();
}

class _CalculatorTrickScreenState extends ConsumerState<CalculatorTrickScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  late Animation<double> _displayOpacity;
  String _demoDisplay = '';
  int _demoStep = 0;
  bool _showTryItButton = false;

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _displayOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _demoController, curve: Curves.easeInOut),
    );

    // Start the demo animation after a brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _runDemoAnimation();
      }
    });
  }

  @override
  void dispose() {
    _demoController.dispose();
    super.dispose();
  }

  Future<void> _runDemoAnimation() async {
    final primaryPin = ref.read(onboardingProvider).primaryPin ?? '1234';

    // Simulate typing PIN
    for (int i = 0; i < primaryPin.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _demoDisplay += primaryPin[i];
        });
        HapticFeedback.selectionClick();
      }
    }

    // Type +0=
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _demoDisplay += '+';
      });
      HapticFeedback.selectionClick();
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _demoDisplay += '0';
      });
      HapticFeedback.selectionClick();
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _demoDisplay += '=';
      });
      HapticFeedback.mediumImpact();
    }

    // Show vault opening animation
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      await _demoController.forward();
      HapticFeedback.notificationFeedback(HapticFeedbackType.success);
    }

    // Show "Try it yourself" button
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showTryItButton = true;
      });
    }
  }

  void _handleTryIt() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.go('/onboarding/decoy-pin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Title
              Text(
                'The Calculator Trick',
                style: AppTheme.title2.copyWith(
                  color: AppTheme.label,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Animated demo area
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Calculator display simulation
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: AnimatedBuilder(
                            animation: _demoController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 1.0 - _displayOpacity.value,
                                child: Text(
                                  _demoDisplay,
                                  style: AppTheme.largeTitle.copyWith(
                                    color: AppTheme.label,
                                    fontSize: 48,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Vault icon that appears after demo
                      AnimatedBuilder(
                        animation: _demoController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _displayOpacity.value,
                            child: Transform.scale(
                              scale: 0.5 + (_displayOpacity.value * 0.5),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.systemBlue.withOpacity(0.3),
                                      AppTheme.systemPurple.withOpacity(0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.systemBlue.withOpacity(0.6),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_open,
                                  size: 50,
                                  color: AppTheme.systemBlue,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Explainer text
              Text(
                'Type your PIN followed by +0= to unlock your vault. To everyone else, it just looks like you\'re using a calculator.',
                style: AppTheme.body.copyWith(
                  color: AppTheme.secondaryLabel,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Try it button
              AnimatedOpacity(
                opacity: _showTryItButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _showTryItButton ? _handleTryIt : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.systemBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Try it yourself',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
