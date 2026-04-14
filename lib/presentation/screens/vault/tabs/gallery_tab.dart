import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cover/core/theme/app_theme.dart';
import 'package:cover/core/di/di_container.dart';
import 'package:cover/domain/model/media_item.dart';

class GalleryTab extends ConsumerStatefulWidget {
  const GalleryTab({super.key});

  @override
  ConsumerState<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends ConsumerState<GalleryTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  List<MediaItem> _mediaItems = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMediaItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMediaItems() async {
    setState(() => _isLoading = true);
    try {
      final vaultService = ref.read(vaultServiceProvider);
      final vaultId = await vaultService.getVaultId(VaultNamespace.real);
      
      if (vaultId != null) {
        final mediaItemRepository = await ref.read(mediaItemRepositoryProvider.future);
        final items = await mediaItemRepository.getMediaItemsByVault(vaultId);
        setState(() {
          _mediaItems = items;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CupertinoActivityIndicator(),
            )
          : _mediaItems.isNotEmpty
              ? GridView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _mediaItems.length,
                  itemBuilder: (context, index) {
                    final item = _mediaItems[index];
                    return Card(
                      color: Colors.grey.shade900,
                      margin: const EdgeInsets.only(bottom: 8),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Icon(
                          item.type == 'video' ? CupertinoIcons.videocam : CupertinoIcons.photo,
                          color: AppTheme.systemOrange,
                        ),
                        title: Semantics(
                          label: 'calculator result',
                          child: ExcludeSemantics(
                            child: Text(
                              item.type == 'video' ? 'Video ${index + 1}' : 'Photo ${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        trailing: const Icon(
                          CupertinoIcons.ellipsis,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                        },
                      ),
                    );
                  },
                )
              : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.photo_on_rectangle,
            size: 72,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Photos Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import photos to keep them private.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          _buildImportButton(),
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    return CupertinoButton(
      color: CupertinoColors.systemBlue,
      onPressed: () {
        // TODO: Implement import functionality
      },
      child: const Text('Import Photos'),
    );
  }
}
