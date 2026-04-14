import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/data/storage/secure_file_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Result of camera capture
class CameraCaptureResult {
  final bool success;
  final String? encryptedFilePath;
  final String? error;

  CameraCaptureResult({
    required this.success,
    this.encryptedFilePath,
    this.error,
  });
}

/// Intruder camera capture service interface
abstract class IntruderCameraCaptureService {
  /// Capture a photo from the front camera
  Future<CameraCaptureResult> capturePhoto();

  /// Check if camera is available
  Future<bool> isCameraAvailable();

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission();
}

/// Intruder camera capture service implementation
class IntruderCameraCaptureServiceImpl implements IntruderCameraCaptureService {
  final CryptoService _cryptoService;
  final SecureFileStorage _secureFileStorage;
  final String? _vaultId;
  final Uuid _uuid = const Uuid();

  CameraController? _cameraController;
  bool _isInitialized = false;

  IntruderCameraCaptureServiceImpl({
    required CryptoService cryptoService,
    required SecureFileStorage secureFileStorage,
    String? vaultId,
  })  : _cryptoService = cryptoService,
        _secureFileStorage = secureFileStorage,
        _vaultId = vaultId;

  @override
  Future<bool> isCameraAvailable() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check camera availability', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> hasCameraPermission() async {
    try {
      // Check if camera permission is granted
      // Using the camera package's built-in permission check
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return false;
      }
      
      // Initialize camera to check permissions
      // This will throw an error if permissions are not granted
      try {
        final controller = CameraController(
          cameras.first,
          ResolutionPreset.low,
          enableAudio: false,
        );
        await controller.initialize();
        await controller.dispose();
        return true;
      } catch (e) {
        // Permission not granted
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check camera permission', e, stackTrace);
      return false;
    }
  }

  @override
  Future<CameraCaptureResult> capturePhoto() async {
    try {
      // Check if camera is available
      if (!await isCameraAvailable()) {
        return CameraCaptureResult(
          success: false,
          error: 'Camera not available',
        );
      }

      // Check permission
      if (!await hasCameraPermission()) {
        return CameraCaptureResult(
          success: false,
          error: 'Camera permission not granted',
        );
      }

      // Get front camera
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialize camera controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _isInitialized = true;

      // Capture image
      final image = await _cameraController!.takePicture();

      // Read image bytes
      final imageBytes = await File(image.path).readAsBytes();

      // Dispose camera
      await _cameraController!.dispose();
      _cameraController = null;
      _isInitialized = false;

      // Delete temporary file
      await File(image.path).delete();

      // Store encrypted photo
      final encryptedFilePath = await _secureFileStorage.storeFile(
        vaultId: _vaultId ?? 'intruder',
        type: 'intruder_photo',
        data: Uint8List.fromList(imageBytes),
        originalFileName: 'intruder_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      AppLogger.info('Captured intruder photo: $encryptedFilePath');

      return CameraCaptureResult(
        success: true,
        encryptedFilePath: encryptedFilePath,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to capture intruder photo', e, stackTrace);
      
      // Cleanup
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
        _isInitialized = false;
      }

      return CameraCaptureResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Dispose camera controller
  void dispose() {
    if (_cameraController != null) {
      _cameraController!.dispose();
      _cameraController = null;
      _isInitialized = false;
    }
  }
}
