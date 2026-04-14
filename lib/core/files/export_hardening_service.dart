import 'dart:typed_data';
import 'dart:io';
import 'package:cover/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/file_repository.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Result of export operation
class ExportResult {
  final bool success;
  final String? tempFilePath;
  final String? error;

  ExportResult({
    required this.success,
    this.tempFilePath,
    this.error,
  });
}

/// Export confirmation result
class ExportConfirmation {
  final bool confirmed;
  final bool rememberChoice;

  ExportConfirmation({
    required this.confirmed,
    this.rememberChoice = false,
  });
}

/// Export hardening service interface
abstract class ExportHardeningService {
  /// Export a file to temp directory with confirmation
  Future<ExportResult> exportWithConfirmation(
    int fileId,
    BuildContext context, {
    bool requireConfirmation = true,
  });

  /// Share a file with confirmation
  Future<bool> shareWithConfirmation(
    int fileId,
    BuildContext context, {
    bool requireConfirmation = true,
  });

  /// Clean up all temp files
  Future<void> cleanupAllTempFiles();

  /// Clean up a specific temp file
  Future<void> cleanupTempFile(String filePath);

  /// Get list of active temp files
  Future<List<String>> getActiveTempFiles();

  /// Check if temp file cleanup is needed
  Future<bool> needsCleanup();
}

/// Export hardening service implementation
class ExportHardeningServiceImpl implements ExportHardeningService {
  final SecureFileStorage _secureFileStorage;
  final FileRepository _fileRepository;
  
  // Track temp files for cleanup
  final Map<String, File> _tempFiles = {};
  final Map<String, DateTime> _tempFileTimestamps = {};
  
  // Maximum temp file age before auto-cleanup (30 minutes)
  static const _maxTempFileAge = Duration(minutes: 30);
  
  // Maximum number of temp files allowed
  static const _maxTempFiles = 50;

  ExportHardeningServiceImpl(
    this._secureFileStorage,
    this._fileRepository,
  );

  @override
  Future<ExportResult> exportWithConfirmation(
    int fileId,
    BuildContext context, {
    bool requireConfirmation = true,
  }) async {
    try {
      // Get file item
      final fileItem = await _fileRepository.getFileById(fileId);
      if (fileItem == null) {
        return ExportResult(
          success: false,
          error: 'File not found',
        );
      }

      // Show confirmation dialog if required
      if (requireConfirmation) {
        final confirmation = await _showExportConfirmation(
          context,
          fileItem.originalFileName,
        );
        
        if (!confirmation.confirmed) {
          return ExportResult(
            success: false,
            error: 'Export cancelled by user',
          );
        }
      }

      // Check temp file limit
      if (_tempFiles.length >= _maxTempFiles) {
        await _cleanupOldestFiles();
      }

      // Retrieve encrypted file
      final fileData = await _secureFileStorage.retrieveFile(fileItem.encryptedFilePath);
      if (fileData == null) {
        return ExportResult(
          success: false,
          error: 'Could not retrieve file data',
        );
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = fileItem.originalFileName;
      final tempFilePath = p.join(tempDir.path, 'cover_export_${DateTime.now().millisecondsSinceEpoch}_$fileName');

      // Write to temp file
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(fileData);
      
      // Track for cleanup
      _tempFiles[tempFilePath] = tempFile;
      _tempFileTimestamps[tempFilePath] = DateTime.now();

      AppLogger.info('Exported file to temp: $tempFilePath');

      return ExportResult(
        success: true,
        tempFilePath: tempFilePath,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export file $fileId', e, stackTrace);
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<bool> shareWithConfirmation(
    int fileId,
    BuildContext context, {
    bool requireConfirmation = true,
  }) async {
    try {
      // Export to temp file first
      final exportResult = await exportWithConfirmation(
        fileId,
        context,
        requireConfirmation: requireConfirmation,
      );

      if (!exportResult.success || exportResult.tempFilePath == null) {
        return false;
      }

      // Share the temp file
      final tempFile = File(exportResult.tempFilePath!);
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Shared from Cover',
      );

      // Schedule cleanup after sharing
      Future.delayed(const Duration(minutes: 5), () {
        cleanupTempFile(exportResult.tempFilePath!);
      });

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to share file $fileId', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> cleanupAllTempFiles() async {
    final filePaths = List.from(_tempFiles.keys);
    
    for (final filePath in filePaths) {
      await cleanupTempFile(filePath);
    }
    
    AppLogger.debug('Cleaned up all temp files (${filePaths.length} files)');
  }

  @override
  Future<void> cleanupTempFile(String filePath) async {
    try {
      final tempFile = _tempFiles[filePath];
      if (tempFile != null) {
        if (await tempFile.exists()) {
          await tempFile.delete();
          AppLogger.debug('Cleaned up temp file: $filePath');
        }
        _tempFiles.remove(filePath);
        _tempFileTimestamps.remove(filePath);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup temp file: $filePath', e, stackTrace);
      // Still remove from tracking even if deletion failed
      _tempFiles.remove(filePath);
      _tempFileTimestamps.remove(filePath);
    }
  }

  @override
  Future<List<String>> getActiveTempFiles() async {
    final activeFiles = <String>[];
    
    for (final filePath in _tempFiles.keys) {
      final tempFile = _tempFiles[filePath];
      if (tempFile != null && await tempFile.exists()) {
        activeFiles.add(filePath);
      }
    }
    
    return activeFiles;
  }

  @override
  Future<bool> needsCleanup() async {
    // Check if any temp files exceed max age
    final now = DateTime.now();
    
    for (final timestamp in _tempFileTimestamps.values) {
      if (now.difference(timestamp) > _maxTempFileAge) {
        return true;
      }
    }
    
    // Check if temp file count exceeds limit
    if (_tempFiles.length >= _maxTempFiles) {
      return true;
    }
    
    return false;
  }

  /// Perform automatic cleanup of old temp files
  Future<void> performAutoCleanup() async {
    if (!await needsCleanup()) {
      return;
    }

    final now = DateTime.now();
    final filesToCleanup = <String>[];

    // Find files exceeding max age
    for (final entry in _tempFileTimestamps.entries) {
      if (now.difference(entry.value) > _maxTempFileAge) {
        filesToCleanup.add(entry.key);
      }
    }

    // Cleanup old files
    for (final filePath in filesToCleanup) {
      await cleanupTempFile(filePath);
    }

    // If still over limit, cleanup oldest files
    if (_tempFiles.length >= _maxTempFiles) {
      await _cleanupOldestFiles();
    }

    AppLogger.debug('Auto-cleanup completed: ${filesToCleanup.length} files');
  }

  Future<void> _cleanupOldestFiles() async {
    // Sort by timestamp and remove oldest files
    final sortedFiles = _tempFileTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final filesToRemove = sortedFiles.take(10).map((e) => e.key).toList();
    
    for (final filePath in filesToRemove) {
      await cleanupTempFile(filePath);
    }
  }

  Future<ExportConfirmation> _showExportConfirmation(
    BuildContext context,
    String fileName,
  ) async {
    return await showDialog<ExportConfirmation>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to export a file to a temporary location.'),
            const SizedBox(height: 8),
            Text('File: $fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'The file will be stored temporarily and automatically cleaned up after 30 minutes.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const ExportConfirmation(confirmed: false),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              const ExportConfirmation(confirmed: true),
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    ) ?? const ExportConfirmation(confirmed: false);
  }
}

/// Export confirmation dialog widget
class ExportConfirmationDialog extends StatelessWidget {
  final String fileName;
  final String? warningMessage;

  const ExportConfirmationDialog({
    super.key,
    required this.fileName,
    this.warningMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('You are about to export a file to a temporary location.'),
          const SizedBox(height: 8),
          Text('File: $fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'The file will be stored temporarily and automatically cleaned up after 30 minutes.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (warningMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.systemOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppTheme.systemOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningMessage!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.systemOrange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Export'),
        ),
      ],
    );
  }
}
