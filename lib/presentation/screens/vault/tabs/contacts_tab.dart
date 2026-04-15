import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cover/presentation/screens/vault/contact/create_contact_screen.dart';
import 'package:cover/presentation/screens/vault/contact/edit_contact_screen.dart';
import 'package:cover/domain/usecase/contact_usecases.dart';
import 'package:cover/core/di/di_container.dart';

class ContactsTab extends ConsumerStatefulWidget {
  const ContactsTab({super.key});

  @override
  ConsumerState<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends ConsumerState<ContactsTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  bool _isLoading = true;
  final Map<int, String> _decryptedNames = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final getContactsUseCase = ref.read(getContactsUseCaseProvider);
      final contacts = await getContactsUseCase.execute();
      
      // Decrypt names
      final cryptoService = ref.read(cryptoServiceProvider);
      final vaultService = await ref.read(vaultServiceProvider.future);
      final encryptionKey = await vaultService.getEncryptionKey();
      
      final Map<int, String> decrypted = {};
      for (final contact in contacts) {
        try {
          final encryptedData = EncryptedData.fromBase64(contact.encryptedName);
          final decryptedName = await cryptoService.decryptString(encryptedData, encryptionKey);
          decrypted[contact.id] = decryptedName;
        } catch (e) {
          decrypted[contact.id] = 'Unknown';
        }
      }
      
      setState(() {
        _contacts = contacts;
        _decryptedNames = decrypted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchContacts(String query) async {
    if (query.isEmpty) {
      await _loadContacts();
      return;
    }
    try {
      final searchContactsUseCase = ref.read(searchContactsUseCaseProvider);
      final results = await searchContactsUseCase.execute(query);
      
      // Decrypt names for search results
      final cryptoService = ref.read(cryptoServiceProvider);
      final vaultService = await ref.read(vaultServiceProvider.future);
      final encryptionKey = await vaultService.getEncryptionKey();
      
      final Map<int, String> decrypted = {};
      for (final contact in results) {
        try {
          final encryptedData = EncryptedData.fromBase64(contact.encryptedName);
          final decryptedName = await cryptoService.decryptString(encryptedData, encryptionKey);
          decrypted[contact.id] = decryptedName;
        } catch (e) {
          decrypted[contact.id] = 'Unknown';
        }
      }
      
      setState(() {
        _contacts = results;
        _decryptedNames = decrypted;
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
              onChanged: _searchContacts,
              style: const TextStyle(color: Colors.white),
              placeholderStyle: TextStyle(color: Colors.white.withOpacity( 0.4)),
              itemColor: Colors.white.withOpacity( 0.4),
              backgroundColor: const Color(0xFF2C2C2E),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CupertinoActivityIndicator(),
                  )
                : _contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.person_2,
                              size: 64,
                              color: Colors.white.withOpacity(0.12),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No contacts yet',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first contact',
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
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return Card(
                            color: const Color(0xFF1C1C1E),
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: const Icon(
                                CupertinoIcons.person_circle,
                                color: CupertinoColors.systemBlue,
                                size: 36,
                              ),
                              title: Semantics(
                                label: 'calculator result',
                                child: ExcludeSemantics(
                                  child: Text(
                                    _decryptedNames[contact.id] ?? 'Unknown',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                'Created ${_formatDate(contact.createdAt)}',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              trailing: const Icon(
                                CupertinoIcons.chevron_forward,
                                color: Colors.grey,
                              ),
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                final result = await context.push('/vault/contact/edit/${contact.id}');
                                if (result == true) {
                                  _loadContacts();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          HapticFeedback.lightImpact();
          final result = await context.push('/vault/contact/create');
          if (result == true) {
            _loadContacts();
          }
        },
        backgroundColor: CupertinoColors.systemBlue,
        child: const Icon(CupertinoIcons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
