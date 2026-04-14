import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/utils/logger.dart';

/// Result of location capture
class LocationCaptureResult {
  final bool success;
  final String? encryptedLocation;
  final String? error;

  LocationCaptureResult({
    required this.success,
    this.encryptedLocation,
    this.error,
  });
}

/// Intruder location capture service interface
abstract class IntruderLocationCaptureService {
  /// Capture current location with timeout
  Future<LocationCaptureResult> captureLocation();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  /// Check if location permission is granted
  Future<bool> hasLocationPermission();
}

/// Intruder location capture service implementation
class IntruderLocationCaptureServiceImpl implements IntruderLocationCaptureService {
  final CryptoService _cryptoService;
  final Duration timeout;

  IntruderLocationCaptureServiceImpl({
    required CryptoService cryptoService,
    this.timeout = const Duration(seconds: 5),
  }) : _cryptoService = cryptoService;

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check location service status', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check location permission', e, stackTrace);
      return false;
    }
  }

  @override
  Future<LocationCaptureResult> captureLocation() async {
    try {
      // Check if location service is enabled
      if (!await isLocationServiceEnabled()) {
        return LocationCaptureResult(
          success: false,
          error: 'Location service is disabled',
        );
      }

      // Check permission
      if (!await hasLocationPermission()) {
        return LocationCaptureResult(
          success: false,
          error: 'Location permission not granted',
        );
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      ).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Location capture timed out');
        },
      );

      // Create location data
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Encrypt the full location JSON
      final locationJson = jsonEncode(locationData);
      final encryptedLocation = await _cryptoService.encryptString(locationJson);

      AppLogger.info('Captured intruder location: ${position.latitude}, ${position.longitude}');

      return LocationCaptureResult(
        success: true,
        encryptedLocation: encryptedLocation,
      );
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.warning('Location capture timed out', e, stackTrace);
      return LocationCaptureResult(
        success: false,
        error: 'Location capture timed out',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to capture intruder location', e, stackTrace);
      return LocationCaptureResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
