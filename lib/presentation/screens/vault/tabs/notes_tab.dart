import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cover/domain/usecase/note_usecases.dart';
import 'package:cover/core/di/di_container.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Note> _notes = [];
  bool _isLoading = true;
  final Map<int, String> _decryptedTitles = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final getNotesUseCase = ref.read(getNotesUseCaseProvider);
      final notes = await getNotesUseCase.execute();
      
      // Decrypt titles
      final cryptoService = ref.read(cryptoServiceProvider);
      final vaultService = await ref.read(vaultServiceProvider.future);
      final encryptionKey = await vaultService.getEncryptionKey();
      
      final Map<int, String> decrypted = {};
      for (final note in notes) {
        try {
          final encryptedData = EncryptedData.fromBase64(note.encryptedTitle);
          final decryptedTitle = await cryptoService.decryptString(encryptedData, encryptionKey);
          decrypted[note.id] = decryptedTitle;
        } catch (e) {
          decrypted[note.id] = 'Unknown';
        }
      }
      
      setState(() {
        _notes = notes;
        _decryptedTitles = decrypted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      await _loadNotes();
      return;
    }
    try {
      final searchNotesUseCase = ref.read(searchNotesUseCaseProvider);
      final results = await searchNotesUseCase.execute(query);
      
      // Decrypt titles for search results
      final cryptoService = ref.read(cryptoServiceProvider);
      final vaultService = await ref.read(vaultServiceProvider.future);
      final encryptionKey = await vaultService.getEncryptionKey();
      
      final Map<int, String> decrypted = {};
      for (final note in results) {
        try {
          final encryptedData = EncryptedData.fromBase64(note.encryptedTitle);
          final decryptedTitle = await cryptoService.decryptString(encryptedData, encryptionKey);
          decrypted[note.id] = decryptedTitle;
        } catch (e) {
          decrypted[note.id] = 'Unknown';
        }
      }
      
      setState(() {
        _notes = results;
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
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  color: Colors.grey,
                ),
              ),
              onChanged: _searchNotes,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CupertinoActivityIndicator(),
                  )
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.doc_text,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notes yet',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first note',
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
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          return Card(
                            color: const Color(0xFF1C1C1E),
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: const Icon(
                                CupertinoIcons.doc_text,
                                color: CupertinoColors.systemBlue,
                              ),
                              title: Semantics(
                                label: 'calculator result',
                                child: ExcludeSemantics(
                                  child: Text(
                                    _decryptedTitles[note.id] ?? 'Unknown',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                'Created ${_formatDate(note.createdAt)}',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              trailing: const Icon(
                                CupertinoIcons.chevron_forward,
                                color: Colors.grey,
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
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

