import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/domain/usecase/password_usecases.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/core/password/clipboard_timeout_service.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/theme/app_theme.dart';

class CreatePasswordScreen extends ConsumerStatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  ConsumerState<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends ConsumerState<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _useGenerator = true;
  int _passwordLength = 16;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final generatePasswordUseCase = ref.read(generatePasswordUseCaseProvider);
    final password = generatePasswordUseCase.execute(length: _passwordLength);
    setState(() {
      _passwordController.text = password;
      _passwordStrength = generatePasswordUseCase.estimateStrength(password);
    });
    HapticFeedback.lightImpact();
  }

  void _updateStrength(String password) {
    final generatePasswordUseCase = ref.read(generatePasswordUseCaseProvider);
    setState(() {
      _passwordStrength = generatePasswordUseCase.estimateStrength(password);
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 40) return Colors.red;
    if (_passwordStrength < 70) return AppTheme.systemOrange;
    return Colors.green;
  }

  String _getStrengthLabel() {
    if (_passwordStrength < 40) return 'Weak';
    if (_passwordStrength < 70) return 'Medium';
    return 'Strong';
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final createPasswordUseCase = ref.read(createPasswordUseCaseProvider);
      await createPasswordUseCase.execute(
        title: _titleController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        url: _urlController.text.isEmpty ? null : _urlController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create password', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('New Password'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.checkmark),
            onPressed: _savePassword,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Username / Email',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                        HapticFeedback.lightImpact();
                      },
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.refresh),
                      onPressed: _generatePassword,
                    ),
                  ],
                ),
              ),
              onChanged: _updateStrength,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _passwordStrength / 100,
                      color: _getStrengthColor(),
                      backgroundColor: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStrengthLabel(),
                    style: TextStyle(
                      color: _getStrengthColor(),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Password Length: $_passwordLength',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            Slider(
              value: _passwordLength.toDouble(),
              min: 8,
              max: 32,
              divisions: 24,
              label: '$_passwordLength',
              activeColor: AppTheme.systemOrange,
              onChanged: (value) {
                setState(() => _passwordLength = value.toInt());
                if (_useGenerator) {
                  _generatePassword();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'URL (optional)',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.systemOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Password'),
            ),
          ],
        ),
      ),
    );
  }
}
