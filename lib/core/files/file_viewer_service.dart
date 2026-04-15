import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/file_repository.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';

/// Result of loading a file
class FileLoadResult {
  final bool success;
  final dynamic fileData; // Uint8List for supported types, String for temp file path
  final String? error;
  final bool requiresExport;

  FileLoadResult({
    required this.success,
    this.fileData,
    this.error,
    this.requiresExport = false,
  });
}

/// File viewer service interface
abstract class FileViewerService {
  /// Load a file for viewing
  Future<FileLoadResult> loadFile(int fileId);

  /// Export a file to temp directory and open with system app
  Future<bool> exportAndOpenFile(int fileId);

  /// Clean up temp files
  Future<void> cleanupTempFiles();

  /// Check if file type is supported for in-app viewing
  bool isSupportedType(String mimeType);
}

/// File viewer service implementation
class FileViewerServiceImpl implements FileViewerService {
  final SecureFileStorage _secureFileStorage;
  final FileRepository _fileRepository;
  
  // Track temp files for cleanup
  final Set<File> _tempFiles = {};

  // Supported MIME types for in-app viewing
  static const _supportedMimeTypes = {
    // Images
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/bmp',
    'image/tiff',
    'image/tif',
    'image/x-icon',
    'image/vnd.microsoft.icon',
    'image/svg+xml',
    'image/heic',
    'image/heif',
    'image/x-heic',
    'image/x-heif',
    'image/avif',
    'image/apng',
    'image/vnd.wap.wbmp',
    'image/x-png',
    'image/x-bmp',
    'image/x-tiff',
    
    // Text/Code files
    'text/plain',
    'text/html',
    'text/xml',
    'text/css',
    'text/javascript',
    'application/json',
    'application/xml',
    'text/markdown',
    'text/x-markdown',
    'text/x-c',
    'text/x-csrc',
    'text/x-c++',
    'text/x-c++src',
    'text/x-chdr',
    'text/x-c++hdr',
    'text/x-java-source',
    'text/x-python',
    'text/x-python-script',
    'text/x-perl',
    'text/x-perl-script',
    'text/x-php',
    'text/x-php-source',
    'text/x-ruby',
    'text/x-ruby-script',
    'text/x-go',
    'text/x-golang',
    'text/x-rust',
    'text/x-swift',
    'text/x-typescript',
    'text/x-yaml',
    'text/x-yml',
    'application/x-yaml',
    'text/x-sql',
    'text/x-shellscript',
    'text/x-sh',
    'application/x-sh',
    'text/x-bash',
    'application/x-bash',
    'text/x-powershell',
    'text/x-vbscript',
    'text/x-csharp',
    'text/x-scala',
    'text/x-haskell',
    'text/x-erlang',
    'text/x-elixir',
    'text/x-lisp',
    'text/x-scheme',
    'text/x-ocaml',
    'text/x-fsharp',
    'text/x-r',
    'text/x-rscript',
    'text/x-matlab',
    'text/x-julia',
    'text/x-lua',
    'text/x-tcl',
    'text/x-groovy',
    'text/x-dart',
    'text/x-swift',
    'text/x-objective-c',
    'text/x-objective-c++',
    'text/x-asm',
    'text/x-nasm',
    'text/x-masm',
    'text/x-makefile',
    'text/x-cmake',
    'text/x-dockerfile',
    'text/x-docker',
    'text/x-gradle',
    'text/x-maven',
    'text/x-ant',
    'text/x-nix',
    'text/x-terraform',
    'text/x-hcl',
    'text/x-protobuf',
    'text/x-thrift',
    'text/x-graphql',
    'text/x-graphqls',
    'text/x-scss',
    'text/x-less',
    'text/x-sass',
    'text/x-stylus',
    'text/x-coffeescript',
    'text/x-typescript-jsx',
    'text/x-javascript-jsx',
    'text/x-vue',
    'text/x-svelte',
    'text/x-pug',
    'text/x-haml',
    'text/x-slim',
    'text/x-erb',
    'text/x-ejs',
    'text/x-twig',
    'text/x-mustache',
    'text/x-handlebars',
    'text/x-jinja',
    'text/x-blade',
    'text/x-php-html',
    'text/x-latex',
    'text/x-tex',
    'text/x-bibtex',
    'text/x-rst',
    'text/x-adoc',
    'text/x-asciidoc',
    'text/x-org',
    'text/x-toml',
    'application/toml',
    'text/x-ini',
    'text/x-properties',
    'text/x-conf',
    'text/x-config',
    'text/x-csv',
    'text/x-tsv',
    'text/x-log',
    'text/x-diff',
    'text/x-patch',
    'application/x-patch',
    'text/x-rtf',
    'application/rtf',
    
    // Audio files (for display purposes, playback handled by system)
    'audio/mpeg',
    'audio/mp3',
    'audio/x-mpeg',
    'audio/x-mp3',
    'audio/mp4',
    'audio/m4a',
    'audio/x-m4a',
    'audio/wav',
    'audio/x-wav',
    'audio/wave',
    'audio/x-wave',
    'audio/ogg',
    'audio/x-ogg',
    'audio/opus',
    'audio/flac',
    'audio/x-flac',
    'audio/aac',
    'audio/x-aac',
    'audio/aiff',
    'audio/x-aiff',
    'audio/aif',
    'audio/x-aif',
    'audio/wma',
    'audio/x-wma',
    'audio/x-ms-wma',
    'audio/3gpp',
    'audio/3gpp2',
    'audio/amr',
    'audio/x-amr',
    'audio/x-midi',
    'audio/midi',
    'audio/x-mid',
    
    // Video files (for display purposes, playback handled by system)
    'video/mp4',
    'video/x-mp4',
    'video/mpeg',
    'video/x-mpeg',
    'video/mpg',
    'video/x-mpg',
    'video/quicktime',
    'video/x-quicktime',
    'video/mov',
    'video/x-mov',
    'video/webm',
    'video/x-webm',
    'video/x-matroska',
    'video/x-mkv',
    'video/avi',
    'video/x-avi',
    'video/x-msvideo',
    'video/x-flv',
    'video/flv',
    'video/x-flv',
    'video/wmv',
    'video/x-wmv',
    'video/x-ms-wmv',
    'video/3gpp',
    'video/3gpp2',
    'video/x-3gpp',
    'video/x-3gpp2',
    'video/m4v',
    'video/x-m4v',
    
    // PDF
    'application/pdf',
    'application/x-pdf',
    
    // Fonts (for display purposes)
    'font/ttf',
    'font/otf',
    'font/woff',
    'font/woff2',
    'application/x-font-ttf',
    'application/x-font-otf',
    'application/x-font-woff',
    'application/x-font-woff2',
    
    // Archives (for metadata display only)
    'application/zip',
    'application/x-zip',
    'application/x-zip-compressed',
    'application/x-7z-compressed',
    'application/x-rar-compressed',
    'application/x-tar',
    'application/x-gtar',
    'application/x-gzip',
    'application/gzip',
    'application/x-bzip',
    'application/x-bzip2',
    'application/x-compress',
    'application/x-lzma',
    'application/x-xz',
    'application/zstd',
    
    // Other common formats
    'application/epub+zip',
    'application/x-mobipocket-ebook',
    'application/vnd.amazon.ebook',
  };

  FileViewerServiceImpl(
    this._secureFileStorage,
    this._fileRepository,
  );

  @override
  Future<FileLoadResult> loadFile(int fileId) async {
    try {
      // Get file item
      final fileItem = await _fileRepository.getFileById(fileId);
      if (fileItem == null) {
        return FileLoadResult(
          success: false,
          error: 'File not found',
        );
      }

      // Retrieve encrypted file
      final fileData = await _secureFileStorage.retrieveFile(fileItem.encryptedFilePath);
      if (fileData == null) {
        return FileLoadResult(
          success: false,
          error: 'Could not retrieve file data',
        );
      }

      // Check if type is supported for in-app viewing
      if (isSupportedType(fileItem.mimeType)) {
        return FileLoadResult(
          success: true,
          fileData: fileData,
          requiresExport: false,
        );
      }

      // Unsupported type - return data for export
      return FileLoadResult(
        success: true,
        fileData: fileData,
        requiresExport: true,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load file $fileId', e, stackTrace);
      return FileLoadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<bool> exportAndOpenFile(int fileId) async {
    try {
      // Get file item
      final fileItem = await _fileRepository.getFileById(fileId);
      if (fileItem == null) {
        AppLogger.error('File not found: $fileId');
        return false;
      }

      // Retrieve encrypted file
      final fileData = await _secureFileStorage.retrieveFile(fileItem.encryptedFilePath);
      if (fileData == null) {
        AppLogger.error('Could not retrieve file data for $fileId');
        return false;
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = fileItem.originalFileName;
      final tempFilePath = p.join(tempDir.path, 'cover_export_${DateTime.now().millisecondsSinceEpoch}_$fileName');

      // Write to temp file
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(fileData);
      
      // Track for cleanup
      _tempFiles.add(tempFile);

      AppLogger.info('Exported file to temp: $tempFilePath');

      // Open with system app
      final result = await OpenFilex.open(tempFilePath);

      // Schedule cleanup after delay (gives system time to open)
      Future.delayed(const Duration(minutes: 5), () {
        _cleanupTempFile(tempFile);
      });

      return result.type == ResultType.done || result.type == ResultType.permissionGranted;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export and open file $fileId', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> cleanupTempFiles() async {
    for (final tempFile in _tempFiles) {
      await _cleanupTempFile(tempFile);
    }
    _tempFiles.clear();
    AppLogger.debug('Cleaned up all temp files');
  }

  @override
  bool isSupportedType(String mimeType) {
    return _supportedMimeTypes.contains(mimeType);
  }

  Future<void> _cleanupTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        AppLogger.debug('Cleaned up temp file: ${file.path}');
      }
      _tempFiles.remove(file);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup temp file', e, stackTrace);
    }
  }
}

/// In-app file viewer widget for supported types
class FileViewerWidget extends StatefulWidget {
  final int fileId;
  final FileViewerService fileViewerService;
  final VoidCallback? onClosed;

  const FileViewerWidget({
    super.key,
    required this.fileId,
    required this.fileViewerService,
    this.onClosed,
  });

  @override
  State<FileViewerWidget> createState() => _FileViewerWidgetState();
}

class _FileViewerWidgetState extends State<FileViewerWidget> {
  Uint8List? _fileData;
  bool _isLoading = true;
  String? _error;
  String? _mimeType;
  String? _tempFilePath;
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isVideoInitialized = false;
  bool _isAudioPlaying = false;
  Duration? _audioDuration;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  Future<void> _loadFile() async {
    final result = await widget.fileViewerService.loadFile(widget.fileId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _fileData = result.fileData as Uint8List;
        } else {
          _error = result.error;
        }
      });
    }
  }

  Future<void> _loadMimeType() async {
    // MIME type will be determined from file data or extension
    // For now, we'll detect it from the file data when needed
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.white),
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
              'Failed to load file',
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

    if (_fileData == null) {
      return const SizedBox.shrink();
    }

    // Detect file type from data
    final fileType = _detectFileType(_fileData!);

    // Display based on detected file type
    switch (fileType) {
      case FileType.image:
        return _buildImageViewer();
      case FileType.pdf:
        return _buildPdfViewer();
      case FileType.audio:
        return _buildAudioPlayer();
      case FileType.video:
        return _buildVideoPlayer();
      case FileType.text:
        return _buildTextViewer();
      case FileType.archive:
        return _buildArchiveViewer();
      case FontType.font:
        return _buildFontViewer();
      case FileType.document:
        return _buildDocumentViewer();
      default:
        return _buildUnsupportedViewer();
    }
  }

  FileType _detectFileType(Uint8List data) {
    // Check for image signatures
    if (data.length >= 4) {
      // JPEG: FF D8 FF
      if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
        return FileType.image;
      }
      // PNG: 89 50 4E 47
      if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) {
        return FileType.image;
      }
      // GIF: 47 49 46 38
      if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38) {
        return FileType.image;
      }
      // WebP: 52 49 46 46 ... 57 45 42 50
      if (data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
          data.length >= 12 && data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) {
        return FileType.image;
      }
      // PDF: 25 50 44 46 (%PDF)
      if (data[0] == 0x25 && data[1] == 0x50 && data[2] == 0x44 && data[3] == 0x46) {
        return FileType.pdf;
      }
      // ZIP (also used for docx, xlsx, etc.): 50 4B 03 04 or 50 4B 05 06 or 50 4B 07 08
      if (data[0] == 0x50 && data[1] == 0x4B &&
          (data[2] == 0x03 || data[2] == 0x05 || data[2] == 0x07)) {
        return FileType.archive;
      }
      // RAR: 52 61 72 21
      if (data[0] == 0x52 && data[1] == 0x61 && data[2] == 0x72 && data[3] == 0x21) {
        return FileType.archive;
      }
      // 7Z: 37 7A BC AF
      if (data[0] == 0x37 && data[1] == 0x7A && data[2] == 0xBC && data[3] == 0xAF) {
        return FileType.archive;
      }
      // MP3: ID3 tag or FF FB
      if (data.length >= 3) {
        if (data[0] == 0x49 && data[1] == 0x44 && data[2] == 0x33) { // ID3
          return FileType.audio;
        }
        if (data[0] == 0xFF && (data[1] & 0xE0) == 0xE0) { // MP3 frame
          return FileType.audio;
        }
      }
      // WAV: 52 49 46 46 ... 57 41 56 45
      if (data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
          data.length >= 12 && data[8] == 0x57 && data[9] == 0x41 && data[10] == 0x56 && data[11] == 0x45) {
        return FileType.audio;
      }
      // OGG: 4F 67 67 53
      if (data[0] == 0x4F && data[1] == 0x67 && data[2] == 0x67 && data[3] == 0x53) {
        return FileType.audio;
      }
      // FLAC: 66 4C 61 43
      if (data[0] == 0x66 && data[1] == 0x4C && data[2] == 0x61 && data[3] == 0x43) {
        return FileType.audio;
      }
      // MP4: 00 00 00 .. 66 74 79 70 or 66 74 79 70 at position 4
      if (data.length >= 12) {
        if (data[4] == 0x66 && data[5] == 0x74 && data[6] == 0x79 && data[7] == 0x70) {
          // Check for video or audio
          final majorBrand = String.fromCharCodes(data.sublist(8, 12));
          if (majorBrand == 'isom' || majorBrand == 'mp42' || majorBrand == 'mp41') {
            return FileType.video;
          }
          if (majorBrand == 'M4A ') {
            return FileType.audio;
          }
        }
      }
      // AVI: 52 49 46 46 ... 41 56 49 20
      if (data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
          data.length >= 12 && data[8] == 0x41 && data[9] == 0x56 && data[10] == 0x49 && data[11] == 0x20) {
        return FileType.video;
      }
      // WebM: 1A 45 DF A3
      if (data[0] == 0x1A && data[1] == 0x45 && data[2] == 0xDF && data[3] == 0xA3) {
        return FileType.video;
      }
      // Font: OTF: 4F 54 54 4F, TTF: 00 01 00 00 or 74 74 63 66
      if (data[0] == 0x4F && data[1] == 0x54 && data[2] == 0x54 && data[3] == 0x4F) {
        return FontType.font;
      }
      if (data[0] == 0x00 && data[1] == 0x01 && data[2] == 0x00 && data[3] == 0x00) {
        return FontType.font;
      }
      if (data[0] == 0x74 && data[1] == 0x74 && data[2] == 0x63 && data[3] == 0x66) {
        return FontType.font;
      }
      // WOFF: 77 4F 46 46
      if (data[0] == 0x77 && data[1] == 0x4F && data[2] == 0x46 && data[3] == 0x46) {
        return FontType.font;
      }
    }

    // Try to detect as text
    try {
      final text = String.fromCharCodes(data);
      // Check if it's valid UTF-8 and mostly printable ASCII
      final printableCount = text.codeUnits.where((c) => c >= 32 && c <= 126 || c == 10 || c == 13 || c == 9).length;
      if (printableCount > text.length * 0.7) {
        return FileType.text;
      }
    } catch (e) {
      // Not valid text
    }

    return FileType.unknown;
  }

  Widget _buildImageViewer() {
    return Image.memory(
      _fileData!,
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

  Widget _buildPdfViewer() {
    return FutureBuilder<String>(
      future: _writeToTempFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CupertinoActivityIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildUnsupportedViewer();
        }

        _tempFilePath = snapshot.data;

        return PDFView(
          filePath: _tempFilePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: false,
          onError: (error) {
            return Center(
              child: Text(
                'Failed to load PDF: $error',
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          },
          onPageError: (page, error) {
            return Center(
              child: Text(
                'Error on page $page: $error',
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAudioPlayer() {
    return FutureBuilder<String>(
      future: _writeToTempFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CupertinoActivityIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildUnsupportedViewer();
        }

        _tempFilePath = snapshot.data;

        return _AudioPlayerWidget(
          filePath: _tempFilePath!,
          onPlayerCreated: (player) {
            _audioPlayer = player;
          },
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder<String>(
      future: _writeToTempFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CupertinoActivityIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildUnsupportedViewer();
        }

        _tempFilePath = snapshot.data;

        return _VideoPlayerWidget(
          filePath: _tempFilePath!,
          onControllerCreated: (controller) {
            _videoController = controller;
          },
        );
      },
    );
  }

  Widget _buildTextViewer() {
    try {
      final text = String.fromCharCodes(_fileData!);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.text_snippet, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to display text',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildArchiveViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_zip, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            'Archive file (${_fileData!.length} bytes)',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Archives must be exported to view contents',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final success = await widget.fileViewerService.exportAndOpenFile(widget.fileId);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to open file')),
                );
              }
            },
            child: const Text('Export and Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildFontViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.font_download, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            'Font file (${_fileData!.length} bytes)',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Fonts must be installed to use',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final success = await widget.fileViewerService.exportAndOpenFile(widget.fileId);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to open file')),
                );
              }
            },
            child: const Text('Export Font'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            'Document file (${_fileData!.length} bytes)',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'This document format requires export for viewing',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final success = await widget.fileViewerService.exportAndOpenFile(widget.fileId);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to open file')),
                );
              }
            },
            child: const Text('Export and Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            'File type not supported for in-app viewing',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final success = await widget.fileViewerService.exportAndOpenFile(widget.fileId);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to open file')),
                );
              }
            },
            child: const Text('Open with System App'),
          ),
        ],
      ),
    );
  }

  Future<String> _writeToTempFile() async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_file_${DateTime.now().millisecondsSinceEpoch}.tmp');
    await tempFile.writeAsBytes(_fileData!);
    return tempFile.path;
  }
}

enum FileType {
  image,
  pdf,
  audio,
  video,
  text,
  archive,
  document,
  unknown,
}

enum FontType {
  font,
}

/// Audio player widget
class _AudioPlayerWidget extends StatefulWidget {
  final String filePath;
  final Function(AudioPlayer)? onPlayerCreated;

  const _AudioPlayerWidget({
    required this.filePath,
    this.onPlayerCreated,
  });

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration? _duration;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    widget.onPlayerCreated?.call(_audioPlayer);
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSourceDeviceFile(File(widget.filePath));
      _audioPlayer.getDuration().then((value) {
        if (mounted) {
          setState(() {
            _duration = value;
          });
        }
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audiotrack, color: Colors.white, size: 64),
          const SizedBox(height: 24),
          if (_duration != null)
            Text(
              '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / '
              '${_duration!.inMinutes}:${(_duration!.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white),
            ),
          const SizedBox(height: 16),
          Slider(
            value: _duration != null ? _position.inSeconds.toDouble() : 0,
            max: _duration != null ? _duration!.inSeconds.toDouble() : 1,
            onChanged: (value) {
              _seek(Duration(seconds: value.toInt()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.grey,
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePlayPause,
            color: Colors.white,
            iconSize: 48,
          ),
        ],
      ),
    );
  }
}

/// Video player widget
class _VideoPlayerWidget extends StatefulWidget {
  final String filePath;
  final Function(VideoPlayerController)? onControllerCreated;

  const _VideoPlayerWidget({
    required this.filePath,
    this.onControllerCreated,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath));
    widget.onControllerCreated?.call(_controller);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white.withOpacity(0.8),
                size: 64,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
      ],
    );
  }
}
