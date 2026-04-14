import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/domain/usecase/password_usecases.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/theme/app_theme.dart';

class EditPasswordScreen extends ConsumerStatefulWidget {
  final int passwordId;

  const EditPasswordScreen({super.key, required this.passwordId});

  @override
  ConsumerState<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends ConsumerState<EditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _obscurePassword = true;
  int _passwordStrength = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPassword() async {
    try {
      final getPasswordByIdUseCase = ref.read(getPasswordByIdUseCaseProvider);
      final password = await getPasswordByIdUseCase.execute(widget.passwordId);
      
      if (password != null) {
        setState(() {
          // In production, you'd decrypt the data here
          _titleController.text = 'Password ${password.id}';
          _usernameController.text = 'user${password.id}';
          _passwordController.text = '********';
          _urlController.text = '';
          _notesController.text = '';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load password', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  void _updateStrength(String password) {
    final generatePasswordUseCase = ref.read(generatePasswordUseCaseProvider);
    setState(() {
      _passwordStrength = generatePasswordUseCase.estimateStrength(password);
    });
  }

  Future<void> _copyPassword() async {
    try {
      final clipboardService = ref.read(clipboardTimeoutServiceProvider);
      await clipboardService.copyWithTimeout(_passwordController.text);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to copy password')),
        );
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // In production, you'd get the password entry and update it
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update password', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update password')),
        );
      }
    }
  }

  Future<void> _deletePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete Password', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this password?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final deletePasswordUseCase = ref.read(deletePasswordUseCaseProvider);
        await deletePasswordUseCase.execute(widget.passwordId);
        HapticFeedback.heavyImpact();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to delete password', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete password')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CupertinoActivityIndicator(color: AppTheme.systemOrange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Password'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.delete),
            onPressed: _deletePassword,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.checkmark),
            onPressed: _updatePassword,
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
                suffixIcon: IconButton(
                  icon: const Icon(CupertinoIcons.doc_on_doc),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _usernameController.text));
                    HapticFeedback.lightImpact();
                  },
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
                      icon: const Icon(CupertinoIcons.doc_on_doc),
                      onPressed: _copyPassword,
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
              onPressed: _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.systemOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
