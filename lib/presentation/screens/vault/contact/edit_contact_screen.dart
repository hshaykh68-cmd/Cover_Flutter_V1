import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/domain/usecase/contact_usecases.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:cover/core/theme/app_theme.dart';

class EditContactScreen extends ConsumerStatefulWidget {
  final int contactId;

  const EditContactScreen({super.key, required this.contactId});

  @override
  ConsumerState<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends ConsumerState<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadContact() async {
    try {
      final getContactByIdUseCase = ref.read(getContactByIdUseCaseProvider);
      final contact = await getContactByIdUseCase.execute(widget.contactId);
      
      if (contact != null) {
        setState(() {
          // In production, you'd decrypt the data here
          _nameController.text = 'Contact ${contact.id}';
          _phoneController.text = '+1234567890';
          _emailController.text = 'contact${contact.id}@example.com';
          _addressController.text = '';
          _notesController.text = '';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load contact', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _callContact() async {
    final appConfig = ref.read(appConfigProvider);
    if (!appConfig.contactsAllowExternalIntents) {
      _showExternalIntentWarning('call');
      return;
    }

    try {
      // In production, you'd use the actual encrypted phone number and encryption key
      final callContactUseCase = ref.read(callContactUseCaseProvider);
      // await callContactUseCase.execute(encryptedPhone, encryptionKey);
      
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate call')),
        );
      }
    }
  }

  Future<void> _smsContact() async {
    final appConfig = ref.read(appConfigProvider);
    if (!appConfig.contactsAllowExternalIntents) {
      _showExternalIntentWarning('SMS');
      return;
    }

    try {
      // In production, you'd use the actual encrypted phone number and encryption key
      final smsContactUseCase = ref.read(smsContactUseCaseProvider);
      // await smsContactUseCase.execute(encryptedPhone, encryptionKey);
      
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate SMS')),
        );
      }
    }
  }

  Future<void> _emailContact() async {
    final appConfig = ref.read(appConfigProvider);
    if (!appConfig.contactsAllowExternalIntents) {
      _showExternalIntentWarning('email');
      return;
    }

    try {
      // In production, you'd use the actual encrypted email and encryption key
      final emailContactUseCase = ref.read(emailContactUseCaseProvider);
      // await emailContactUseCase.execute(encryptedEmail, encryptionKey);
      
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate email')),
        );
      }
    }
  }

  void _showExternalIntentWarning(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('External Action Disabled', style: TextStyle(color: Colors.white)),
        content: Text(
          'External $action actions are disabled for security. This may be enabled in settings.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // In production, you'd get the contact entry and update it
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update contact', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update contact')),
        );
      }
    }
  }

  Future<void> _deleteContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete Contact', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this contact?',
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
        final deleteContactUseCase = ref.read(deleteContactUseCaseProvider);
        await deleteContactUseCase.execute(widget.contactId);
        HapticFeedback.heavyImpact();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to delete contact', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete contact')),
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
        title: const Text('Edit Contact'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.delete),
            onPressed: _deleteContact,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.checkmark),
            onPressed: _updateContact,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.systemOrange,
                child: Text(
                  _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: CupertinoIcons.phone,
                  label: 'Call',
                  onTap: _callContact,
                ),
                _ActionButton(
                  icon: CupertinoIcons.chat_bubble,
                  label: 'SMS',
                  onTap: _smsContact,
                ),
                _ActionButton(
                  icon: CupertinoIcons.mail,
                  label: 'Email',
                  onTap: _emailContact,
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
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
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
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
                    Clipboard.setData(ClipboardData(text: _phoneController.text));
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email (optional)',
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
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Address (optional)',
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
              onPressed: _updateContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.systemOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.systemOrange),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
