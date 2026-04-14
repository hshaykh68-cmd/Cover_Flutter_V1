import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/domain/repository/file_repository.dart';
import 'package:cover/domain/repository/note_repository.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/core/utils/logger.dart';

class StorageSettingsScreen extends ConsumerStatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  ConsumerState<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends ConsumerState<StorageSettingsScreen> {
  int _mediaCount = 0;
  int _fileCount = 0;
  int _noteCount = 0;
  int _totalSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get vault ID (simplified - in production you'd get the current active vault)
      const vaultId = 'default_vault';
      
      final mediaRepo = ref.read(mediaItemRepositoryProvider);
      final fileRepo = ref.read(fileRepositoryProvider);
      final noteRepo = ref.read(noteRepositoryProvider);

      final mediaItems = await mediaRepo.getMediaItemsByVault(vaultId);
      final files = await fileRepo.getFilesByVault(vaultId);
      final notes = await noteRepo.getNotesByVault(vaultId);

      // Calculate total size (simplified - in production you'd calculate actual file sizes)
      int totalSize = 0;
      for (final item in mediaItems) {
        totalSize += item.fileSize;
      }
      for (final file in files) {
        totalSize += file.fileSize;
      }

      setState(() {
        _mediaCount = mediaItems.length;
        _fileCount = files.length;
        _noteCount = notes.length;
        _totalSize = totalSize;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load storage info', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Storage'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CupertinoActivityIndicator(color: AppTheme.systemOrange),
            )
          : ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  CupertinoIcons.externaldrive_fill,
                  size: 64,
                  color: AppTheme.systemOrange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Storage Usage',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your vault storage',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  color: Colors.grey.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _formatSize(_totalSize),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.systemOrange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Storage Used',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildStorageItem(
                  icon: CupertinoIcons.photo,
                  title: 'Photos & Videos',
                  count: _mediaCount,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildStorageItem(
                  icon: CupertinoIcons.folder,
                  title: 'Files',
                  count: _fileCount,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _buildStorageItem(
                  icon: CupertinoIcons.doc_text,
                  title: 'Notes',
                  count: _noteCount,
                  color: Colors.purple,
                ),
                const SizedBox(height: 32),
                Card(
                  color: AppTheme.systemOrange.withValues(alpha: 0.1),
                  child: ListTile(
                    leading: const Icon(
                      CupertinoIcons.info_circle,
                      color: AppTheme.systemOrange,
                    ),
                    title: Text(
                      'All data is stored locally on your device',
                      style: TextStyle(
                        color: AppTheme.systemOrange.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStorageItem({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Card(
      color: Colors.grey.shade900,
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          count.toString(),
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
