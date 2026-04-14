import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:image/image.dart' as img;

/// Result of loading media
class MediaLoadResult {
  final bool success;
  final dynamic mediaData; // Uint8List for images, VideoPlayerController for videos
  final String? error;

  MediaLoadResult({
    required this.success,
    this.mediaData,
    this.error,
  });
}

/// Secure media viewer interface
abstract class SecureMediaViewer {
  /// Load and decrypt media to memory
  Future<MediaLoadResult> loadMedia(int mediaItemId);

  /// Unload media and clear from memory
  void unloadMedia(int mediaItemId);

  /// Get media type for an item
  Future<String?> getMediaType(int mediaItemId);

  /// Get media metadata
  Future<Map<String, dynamic>?> getMediaMetadata(int mediaItemId);
}

/// Secure media viewer implementation
class SecureMediaViewerImpl implements SecureMediaViewer {
  final SecureFileStorage _secureFileStorage;
  final MediaItemRepository _mediaItemRepository;
  
  // Keep track of loaded media in memory
  final Map<int, dynamic> _loadedMedia = {};

  SecureMediaViewerImpl(
    this._secureFileStorage,
    this._mediaItemRepository,
  );

  @override
  Future<MediaLoadResult> loadMedia(int mediaItemId) async {
    try {
      // Get media item
      final mediaItem = await _mediaItemRepository.getMediaItemById(mediaItemId);
      if (mediaItem == null) {
        return MediaLoadResult(
          success: false,
          error: 'Media item not found',
        );
      }

      // Check if already loaded
      if (_loadedMedia.containsKey(mediaItemId)) {
        return MediaLoadResult(
          success: true,
          mediaData: _loadedMedia[mediaItemId],
        );
      }

      // Retrieve encrypted file
      final fileData = await _secureFileStorage.retrieveFile(mediaItem.encryptedFilePath);
      if (fileData == null) {
        return MediaLoadResult(
          success: false,
          error: 'Could not retrieve media file',
        );
      }

      // Load based on type
      if (mediaItem.type == 'photo') {
        return await _loadImage(mediaItemId, fileData);
      } else if (mediaItem.type == 'video') {
        return await _loadVideo(mediaItemId, fileData, mediaItem);
      } else {
        return MediaLoadResult(
          success: false,
          error: 'Unsupported media type: ${mediaItem.type}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load media $mediaItemId', e, stackTrace);
      return MediaLoadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  void unloadMedia(int mediaItemId) {
    final mediaData = _loadedMedia[mediaItemId];
    
    if (mediaData is VideoPlayerController) {
      mediaData.dispose();
    }
    
    _loadedMedia.remove(mediaItemId);
    AppLogger.debug('Unloaded media $mediaItemId from memory');
  }

  @override
  Future<String?> getMediaType(int mediaItemId) async {
    final mediaItem = await _mediaItemRepository.getMediaItemById(mediaItemId);
    return mediaItem?.type;
  }

  @override
  Future<Map<String, dynamic>?> getMediaMetadata(int mediaItemId) async {
    final mediaItem = await _mediaItemRepository.getMediaItemById(mediaItemId);
    if (mediaItem == null) return null;

    return {
      'type': mediaItem.type,
      'fileSize': mediaItem.fileSize,
      'mimeType': mediaItem.mimeType,
      'width': mediaItem.width,
      'height': mediaItem.height,
      'duration': mediaItem.duration,
      'originalFileName': mediaItem.originalFileName,
      'createdAt': mediaItem.createdAt,
    };
  }

  Future<MediaLoadResult> _loadImage(int mediaItemId, Uint8List fileData) async {
    try {
      // Decode image to verify it's valid
      final image = img.decodeImage(fileData);
      if (image == null) {
        return MediaLoadResult(
          success: false,
          error: 'Invalid image data',
        );
      }

      // Store in memory (never write to disk)
      _loadedMedia[mediaItemId] = fileData;

      AppLogger.info('Loaded image $mediaItemId to memory (${fileData.length} bytes)');

      return MediaLoadResult(
        success: true,
        mediaData: fileData,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load image', e, stackTrace);
      return MediaLoadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<MediaLoadResult> _loadVideo(
    int mediaItemId,
    Uint8List fileData,
    dynamic mediaItem,
  ) async {
    try {
      // Write to temporary file (required by video_player)
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_video_$mediaItemId.mp4');
      await tempFile.writeAsBytes(fileData);

      // Create video controller
      final controller = VideoPlayerController.file(tempFile);
      await controller.initialize();

      // Store controller in memory
      _loadedMedia[mediaItemId] = controller;

      // Schedule cleanup of temp file after controller is disposed
      controller.addListener(() {
        if (!controller.value.isPlaying && controller.value.position >= controller.value.duration) {
          // Video ended, clean up temp file
          _cleanupTempFile(tempFile);
        }
      });

      AppLogger.info('Loaded video $mediaItemId to memory (${fileData.length} bytes)');

      return MediaLoadResult(
        success: true,
        mediaData: controller,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load video', e, stackTrace);
      return MediaLoadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _cleanupTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        AppLogger.debug('Cleaned up temp file: ${file.path}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup temp file', e, stackTrace);
    }
  }

  /// Clean up all loaded media
  void cleanupAll() {
    for (final mediaItemId in _loadedMedia.keys) {
      unloadMedia(mediaItemId);
    }
    AppLogger.debug('Cleaned up all loaded media');
  }
}

/// Secure image viewer widget
class SecureImageViewer extends StatefulWidget {
  final int mediaItemId;
  final SecureMediaViewer mediaViewer;
  final VoidCallback? onDisposed;

  const SecureImageViewer({
    super.key,
    required this.mediaItemId,
    required this.mediaViewer,
    this.onDisposed,
  });

  @override
  State<SecureImageViewer> createState() => _SecureImageViewerState();
}

class _SecureImageViewerState extends State<SecureImageViewer> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final result = await widget.mediaViewer.loadMedia(widget.mediaItemId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _imageData = result.mediaData as Uint8List;
        } else {
          _error = result.error;
        }
      });
    }
  }

  @override
  void dispose() {
    widget.mediaViewer.unloadMedia(widget.mediaItemId);
    widget.onDisposed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }

    if (_imageData == null) {
      return const SizedBox.shrink();
    }

    return Image.memory(
      _imageData!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to display image',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Secure video viewer widget
class SecureVideoViewer extends StatefulWidget {
  final int mediaItemId;
  final SecureMediaViewer mediaViewer;
  final VoidCallback? onDisposed;

  const SecureVideoViewer({
    super.key,
    required this.mediaItemId,
    required this.mediaViewer,
    this.onDisposed,
  });

  @override
  State<SecureVideoViewer> createState() => _SecureVideoViewerState();
}

class _SecureVideoViewerState extends State<SecureVideoViewer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final result = await widget.mediaViewer.loadMedia(widget.mediaItemId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _controller = result.mediaData as VideoPlayerController;
          _isInitialized = true;
        } else {
          _error = result.error;
        }
      });
    }
  }

  @override
  void dispose() {
    widget.mediaViewer.unloadMedia(widget.mediaItemId);
    widget.onDisposed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    }

    if (_controller == null || !_isInitialized) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}

/// Auto-playing secure video viewer with controls
class SecureVideoPlayerWithControls extends StatefulWidget {
  final int mediaItemId;
  final SecureMediaViewer mediaViewer;
  final VoidCallback? onDisposed;

  const SecureVideoPlayerWithControls({
    super.key,
    required this.mediaItemId,
    required this.mediaViewer,
    this.onDisposed,
  });

  @override
  State<SecureVideoPlayerWithControls> createState() => _SecureVideoPlayerWithControlsState();
}

class _SecureVideoPlayerWithControlsState extends State<SecureVideoPlayerWithControls> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final result = await widget.mediaViewer.loadMedia(widget.mediaItemId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _controller = result.mediaData as VideoPlayerController;
          _isInitialized = true;
        } else {
          _error = result.error;
        }
      });
    }
  }

  @override
  void dispose() {
    widget.mediaViewer.unloadMedia(widget.mediaItemId);
    widget.onDisposed?.call();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    if (_controller == null || !_isInitialized) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        // Play/Pause button overlay
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white.withValues(alpha: 0.8),
                size: 64,
              ),
            ),
          ),
        ),
        // Progress indicator
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white.withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }
}
