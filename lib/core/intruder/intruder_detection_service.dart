import 'dart:convert';
import 'dart:typed_data';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/intruder/intruder_camera_capture_service.dart';
import 'package:cover/core/intruder/intruder_location_capture_service.dart';
import 'package:cover/core/secure_storage/secure_key_storage.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:cover/domain/repository/intruder_log_repository.dart';
import 'package:cover/data/local/database/tables.dart';

/// Result of an intruder event capture
class IntruderEventResult {
  final bool success;
  final String? intruderLogId;
  final String? error;

  IntruderEventResult({
    required this.success,
    this.intruderLogId,
    this.error,
  });
}

/// Intruder detection service interface
/// 
/// Manages intruder detection, logging, and evidence capture
abstract class IntruderDetectionService {
  /// Record a wrong PIN attempt
  /// 
  /// Returns true if the attempt threshold has been reached and capture should be triggered
  Future<bool> recordWrongAttempt({String? vaultId});

  /// Capture intruder evidence (photo + location)
  /// 
  /// Parameters:
  /// - [vaultId]: Optional vault ID if attempt was on a specific vault
  /// - [eventType]: Type of event (wrong_pin, screenshot, compromise_report)
  /// 
  /// Returns the result of the capture operation
  Future<IntruderEventResult> captureIntruderEvidence({
    String? vaultId,
    String eventType = 'wrong_pin',
  });

  /// Get all intruder logs for a vault
  Future<List<IntruderLog>> getIntruderLogs({String? vaultId});

  /// Get intruder logs within a date range
  Future<List<IntruderLog>> getIntruderLogsByDateRange({
    DateTime? startDate,
    DateTime? endDate,
    String? vaultId,
  });

  /// Delete an intruder log
  Future<void> deleteIntruderLog(int logId);

  /// Clear all intruder logs for a vault
  Future<void> clearIntruderLogs({String? vaultId});

  /// Get intruder attempt count
  Future<int> getAttemptCount({String? vaultId});

  /// Reset attempt counter
  Future<void> resetAttemptCounter({String? vaultId});

  /// Check if intruder detection is enabled
  bool get isEnabled;

  /// Enable or disable intruder detection
  Future<void> setEnabled(bool enabled);

  /// Update configuration
  void updateConfiguration({
    int? maxAttemptsBeforeCapture,
    int? captureCountPerAttempt,
  });
}

/// Intruder detection service implementation
class IntruderDetectionServiceImpl implements IntruderDetectionService {
  final IntruderLogRepository _intruderLogRepository;
  final CryptoService _cryptoService;
  final SecureKeyStorage _secureKeyStorage;
  final SecureFileStorage _secureFileStorage;
  final IntruderCameraCaptureService _cameraCaptureService;
  final IntruderLocationCaptureService _locationCaptureService;
  
  // Attempt tracking
  final Map<String, int> _attemptCounters = {};
  
  // Configuration
  bool _enabled = true;
  int _maxAttemptsBeforeCapture = 2;
  int _captureCountPerAttempt = 2;

  IntruderDetectionServiceImpl({
    required IntruderLogRepository intruderLogRepository,
    required CryptoService cryptoService,
    required SecureKeyStorage secureKeyStorage,
    required SecureFileStorage secureFileStorage,
    required IntruderCameraCaptureService cameraCaptureService,
    required IntruderLocationCaptureService locationCaptureService,
    int maxAttemptsBeforeCapture = 2,
    int captureCountPerAttempt = 2,
  })  : _intruderLogRepository = intruderLogRepository,
        _cryptoService = cryptoService,
        _secureKeyStorage = secureKeyStorage,
        _secureFileStorage = secureFileStorage,
        _cameraCaptureService = cameraCaptureService,
        _locationCaptureService = locationCaptureService,
        _maxAttemptsBeforeCapture = maxAttemptsBeforeCapture,
        _captureCountPerAttempt = captureCountPerAttempt;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    AppLogger.info('Intruder detection ${enabled ? "enabled" : "disabled"}');
  }

  @override
  Future<bool> recordWrongAttempt({String? vaultId}) async {
    if (!_enabled) {
      return false;
    }

    final key = vaultId ?? 'global';
    _attemptCounters[key] = (_attemptCounters[key] ?? 0) + 1;
    final currentAttempts = _attemptCounters[key]!;

    // Persist to secure storage
    await _secureKeyStorage.storeString('intruder_attempts_$key', currentAttempts.toString());

    AppLogger.warning('Wrong PIN attempt #$currentAttempts for $key');

    // Check if threshold reached
    if (currentAttempts >= _maxAttemptsBeforeCapture) {
      AppLogger.warning('Intruder capture threshold reached for $key');
      return true;
    }

    return false;
  }

  @override
  Future<int> getAttemptCount({String? vaultId}) async {
    final key = vaultId ?? 'global';
    final persisted = await _secureKeyStorage.retrieveString('intruder_attempts_$key');
    if (persisted != null) {
      return int.tryParse(persisted) ?? 0;
    }
    return _attemptCounters[key] ?? 0;
  }

  @override
  Future<void> resetAttemptCounter({String? vaultId}) async {
    final key = vaultId ?? 'global';
    _attemptCounters[key] = 0;
    await _secureKeyStorage.deleteKey('intruder_attempts_$key');
    AppLogger.debug('Reset attempt counter for $key');
  }

  @override
  Future<IntruderEventResult> captureIntruderEvidence({
    String? vaultId,
    String eventType = 'wrong_pin',
  }) async {
    if (!_enabled) {
      return IntruderEventResult(
        success: false,
        error: 'Intruder detection is disabled',
      );
    }

    try {
      // Capture photos
      final photoPaths = <String>[];
      for (int i = 0; i < _captureCountPerAttempt; i++) {
        final photoResult = await _cameraCaptureService.capturePhoto();
        if (photoResult.success && photoResult.encryptedFilePath != null) {
          photoPaths.add(photoResult.encryptedFilePath!);
        }
        // Small delay between captures
        if (i < _captureCountPerAttempt - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Capture location (with timeout)
      String? encryptedLocation;
      final locationResult = await _locationCaptureService.captureLocation();
      if (locationResult.success && locationResult.encryptedLocation != null) {
        encryptedLocation = locationResult.encryptedLocation;
      }

      // Create metadata
      final metadata = {
        'photo_count': photoPaths.length,
        'location_captured': encryptedLocation != null,
        'capture_timestamp': DateTime.now().toIso8601String(),
      };

      // Store primary photo path (first one)
      final primaryPhotoPath = photoPaths.isNotEmpty ? photoPaths.first : null;

      // Create intruder log entry
      final logId = await _intruderLogRepository.createIntruderLog(
        IntruderLogsCompanion(
          vaultId: Value(vaultId),
          eventType: Value(eventType),
          encryptedPhotoPath: Value(primaryPhotoPath),
          encryptedLocation: Value(encryptedLocation),
          metadata: Value(jsonEncode(metadata)),
        ),
      );

      // Store additional photos in metadata
      if (photoPaths.length > 1) {
        final updatedMetadata = jsonDecode(metadata as String) as Map<String, dynamic>;
        updatedMetadata['additional_photo_paths'] = photoPaths.skip(1).toList();
        await _intruderLogRepository.updateIntruderLog(
          logId,
          metadata: Value(jsonEncode(updatedMetadata)),
        );
      }

      AppLogger.info('Intruder evidence captured: log ID $logId, ${photoPaths.length} photos, location: ${encryptedLocation != null}');

      // Reset attempt counter after capture
      await resetAttemptCounter(vaultId: vaultId);

      return IntruderEventResult(
        success: true,
        intruderLogId: logId.toString(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to capture intruder evidence', e, stackTrace);
      return IntruderEventResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<List<IntruderLog>> getIntruderLogs({String? vaultId}) async {
    try {
      if (vaultId != null) {
        return await _intruderLogRepository.getIntruderLogsByVault(vaultId);
      }
      return await _intruderLogRepository.getAllIntruderLogs();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get intruder logs', e, stackTrace);
      return [];
    }
  }

  @override
  Future<List<IntruderLog>> getIntruderLogsByDateRange({
    DateTime? startDate,
    DateTime? endDate,
    String? vaultId,
  }) async {
    try {
      if (startDate == null && endDate == null) {
        return await getIntruderLogs(vaultId: vaultId);
      }
      final start = startDate ?? DateTime(2000);
      final end = endDate ?? DateTime.now();
      return await _intruderLogRepository.getIntruderLogsByDateRange(
        start,
        end,
        vaultId: vaultId,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get intruder logs by date range', e, stackTrace);
      return [];
    }
  }

  @override
  Future<void> deleteIntruderLog(int logId) async {
    try {
      final log = await _intruderLogRepository.getIntruderLogById(logId);
      if (log != null) {
        // Delete associated files
        if (log.encryptedPhotoPath != null) {
          await _secureFileStorage.deleteFile(log.encryptedPhotoPath!);
        }
        
        // Check for additional photos in metadata
        if (log.metadata != null) {
          try {
            final metadata = jsonDecode(log.metadata!) as Map<String, dynamic>;
            if (metadata['additional_photo_paths'] != null) {
              final additionalPaths = metadata['additional_photo_paths'] as List;
              for (final path in additionalPaths) {
                await _secureFileStorage.deleteFile(path as String);
              }
            }
          } catch (e) {
            // Ignore metadata parsing errors
          }
        }
      }
      
      await _intruderLogRepository.deleteIntruderLog(logId);
      AppLogger.info('Deleted intruder log: $logId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete intruder log $logId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearIntruderLogs({String? vaultId}) async {
    try {
      final logs = await getIntruderLogs(vaultId: vaultId);
      
      for (final log in logs) {
        await deleteIntruderLog(log.id);
      }
      
      AppLogger.info('Cleared ${logs.length} intruder logs');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear intruder logs', e, stackTrace);
      rethrow;
    }
  }

  @override
  void updateConfiguration({
    int? maxAttemptsBeforeCapture,
    int? captureCountPerAttempt,
  }) {
    if (maxAttemptsBeforeCapture != null) {
      _maxAttemptsBeforeCapture = maxAttemptsBeforeCapture;
    }
    if (captureCountPerAttempt != null) {
      _captureCountPerAttempt = captureCountPerAttempt;
    }
    AppLogger.info('Intruder detection configuration updated');
  }
}
