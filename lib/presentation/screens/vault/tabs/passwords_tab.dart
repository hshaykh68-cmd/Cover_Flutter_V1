import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:encrypt/encrypt.dart';
import 'package:intl/intl.dart';
import 'package:cover/presentation/screens/vault/password/create_password_screen.dart';
import 'package:cover/presentation/screens/vault/password/edit_password_screen.dart';
import 'package:cover/domain/usecase/password_usecases.dart';
import 'package:cover/core/di/di_container.dart';

class PasswordsTab extends ConsumerStatefulWidget {
  const PasswordsTab({super.key});

  @override
  ConsumerState<PasswordsTab> createState() => _PasswordsTabState();
}

class _PasswordsTabState extends ConsumerState<PasswordsTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Password> _passwords = [];
  bool _isLoading = true;
  final Map<int, String> _decryptedTitles = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPasswords() async {
    setState(() => _isLoading = true);
    try {
      final getPasswordsUseCase = ref.read(getPasswordsUseCaseProvider);
      final passwords = await getPasswordsUseCase.execute();
      
      // Decrypt titles
      final cryptoService = ref.read(cryptoServiceProvider);
      final vaultService = await ref.read(vaultServiceProvider.future);
      final encryptionKey = await vaultService.getEncryptionKey();
      
      final Map<int, String> decrypted = {};
      for (final password in passwords) {
        try {
          final encryptedData = EncryptedData.fromBase64(password.encryptedTitle);
          final decryptedTitle = await cryptoService.decryptString(encryptedData, encryptionKey);
          decrypted[password.id] = decryptedTitle;
        } catch (e) {
          decrypted[password.id] = 'Unknown';
        }
      }
      
      setState(() {
        _passwords = passwords;
        _decryptedTitles = decrypted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPasswords(String query) async {
    if (query.isEmpty) {
      await _loadPasswords();
      return;
    }
    try {
      final searchPasswordsUseCase = ref.read(searchPasswordsUseCaseProvider);
      final results = await searchPasswordsUseCase.execute(query);
      
      // Decrypt titles for search results
      final cryptoService = ref.read(cryptoServiceProvider);
      final vaultService = await ref.read(vaultServiceProvider.future);
      final encryptionKey = await vaultService.getEncryptionKey();
      
      final Map<int, String> decrypted = {};
      for (final password in results) {
        try {
          final encryptedData = EncryptedData.fromBase64(password.encryptedTitle);
          final decryptedTitle = await cryptoService.decryptString(encryptedData, encryptionKey);
          decrypted[password.id] = decryptedTitle;
        } catch (e) {
          decrypted[password.id] = 'Unknown';
        }
      }
      
      setState(() {
        _passwords = results;
        _decryptedTitles = decrypted;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: _searchPasswords,
              style: const TextStyle(color: Colors.white),
              placeholderStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              itemColor: Colors.white.withValues(alpha: 0.4),
              backgroundColor: const Color(0xFF2C2C2E),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CupertinoActivityIndicator(),
                  )
                : _passwords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.lock_slash,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No passwords yet',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first password',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _passwords.length,
                        itemBuilder: (context, index) {
                          final password = _passwords[index];
                          return Card(
                            color: const Color(0xFF1C1C1E),
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: const Icon(
                                CupertinoIcons.lock,
                                color: CupertinoColors.systemBlue,
                              ),
                              title: Semantics(
                                label: 'calculator result',
                                child: ExcludeSemantics(
                                  child: Text(
                                    _decryptedTitles[password.id] ?? 'Unknown',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                'Created ${_formatDate(password.createdAt)}',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              trailing: const Icon(
                                CupertinoIcons.chevron_forward,
                                color: Colors.grey,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final result = await context.push('/vault/password/edit/${password.id}');
                                if (result == true) {
                                  _loadPasswords();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
