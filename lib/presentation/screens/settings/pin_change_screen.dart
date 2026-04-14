import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/core/pin/pin_state_machine.dart';
import 'package:cover/core/vault/vault_service.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/di/di_container.dart';

class PinChangeScreen extends ConsumerStatefulWidget {
  const PinChangeScreen({super.key});

  @override
  ConsumerState<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends ConsumerState<PinChangeScreen> {
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  final FocusNode _currentPinFocus = FocusNode();
  final FocusNode _newPinFocus = FocusNode();
  final FocusNode _confirmPinFocus = FocusNode();

  bool _isLoading = false;
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _currentPinFocus.dispose();
    _newPinFocus.dispose();
    _confirmPinFocus.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    // Validation
    if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (newPin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    if (newPin != confirmPin) {
      _showError('New PIN and confirmation do not match');
      return;
    }

    if (currentPin == newPin) {
      _showError('New PIN must be different from current PIN');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vaultService = ref.read(vaultServiceProvider);
      final cryptoService = ref.read(cryptoServiceProvider);
      final secureStorage = ref.read(secureKeyStorageProvider);

      // Verify current PIN
      final isCurrentPinValid = await vaultService.verifyPin(currentPin);
      if (!isCurrentPinValid) {
        _showError('Current PIN is incorrect');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Change PIN
      await vaultService.changePin(currentPin, newPin);

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to change PIN', e, stackTrace);
      _showError('Failed to change PIN. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.notificationFeedback(HapticFeedbackType.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Change PIN'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                CupertinoIcons.lock,
                size: 64,
                color: AppTheme.systemOrange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Change Your PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current PIN and create a new one',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildPinField(
                controller: _currentPinController,
                focusNode: _currentPinFocus,
                label: 'Current PIN',
                obscure: _obscureCurrentPin,
                onToggle: () {
                  setState(() {
                    _obscureCurrentPin = !_obscureCurrentPin;
                  });
                },
                onSubmitted: () {
                  _newPinFocus.requestFocus();
                },
              ),
              const SizedBox(height: 16),
              _buildPinField(
                controller: _newPinController,
                focusNode: _newPinFocus,
                label: 'New PIN',
                obscure: _obscureNewPin,
                onToggle: () {
                  setState(() {
                    _obscureNewPin = !_obscureNewPin;
                  });
                },
                onSubmitted: () {
                  _confirmPinFocus.requestFocus();
                },
              ),
              const SizedBox(height: 16),
              _buildPinField(
                controller: _confirmPinController,
                focusNode: _confirmPinFocus,
                label: 'Confirm New PIN',
                obscure: _obscureConfirmPin,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPin = !_obscureConfirmPin;
                  });
                },
                onSubmitted: _changePin,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.systemOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CupertinoActivityIndicator(
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Change PIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required VoidCallback onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      maxLength: 12,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            color: Colors.grey.shade400,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            onToggle();
          },
        ),
        counterStyle: TextStyle(color: Colors.grey.shade600),
      ),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
