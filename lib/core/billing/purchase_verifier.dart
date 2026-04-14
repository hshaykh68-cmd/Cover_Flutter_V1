import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';

/// Service for verifying purchases with backend
/// In production, this would call your Firebase Cloud Functions or backend API
class PurchaseVerifier {
  final AppConfig _appConfig;
  final http.Client _httpClient;

  PurchaseVerifier({
    required AppConfig appConfig,
    http.Client? httpClient,
  }) : _appConfig = appConfig,
        _httpClient = httpClient ?? http.Client();

  /// Verify Android purchase with Google Play
  /// In production, use Firebase Cloud Functions with Play Developer API
  Future<bool> verifyAndroidPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async {
    try {
      // For development, we'll use a simple verification
      // In production, implement Firebase Cloud Functions that:
      // 1. Call Play Developer API to verify purchase
      // 2. Check subscription status and expiry
      // 3. Return verification result
      
      AppLogger.info('Verifying Android purchase: $productId');
      
      // Development mode - accept all purchases
      if (kDebugMode || kProfileMode) {
        AppLogger.info('Debug mode: Purchase auto-verified');
        return true;
      }

      // Production verification (to be implemented with Cloud Functions)
      final response = await _httpClient.post(
        Uri.parse('https://your-cloud-function-url/verify-android-purchase'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': productId,
          'purchaseToken': purchaseToken,
          'packageName': packageName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] == true;
      }

      AppLogger.error('Purchase verification failed: ${response.statusCode}');
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error verifying Android purchase', e, stackTrace);
      return false;
    }
  }

  /// Verify iOS purchase with App Store
  /// In production, use Firebase Cloud Functions with App Store Server API
  Future<bool> verifyIosPurchase({
    required String productId,
    required String transactionId,
    required String receiptData,
  }) async {
    try {
      AppLogger.info('Verifying iOS purchase: $productId');
      
      // Development mode - accept all purchases
      if (kDebugMode || kProfileMode) {
        AppLogger.info('Debug mode: Purchase auto-verified');
        return true;
      }

      // Production verification (to be implemented with Cloud Functions)
      final response = await _httpClient.post(
        Uri.parse('https://your-cloud-function-url/verify-ios-purchase'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': productId,
          'transactionId': transactionId,
          'receiptData': receiptData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] == true;
      }

      AppLogger.error('Purchase verification failed: ${response.statusCode}');
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error verifying iOS purchase', e, stackTrace);
      return false;
    }
  }

  /// Get subscription expiry date from purchase details
  /// This extracts the expiry date from the purchase response
  DateTime? getExpiryDateFromPurchase({
    required String productId,
    required Map<String, dynamic> purchaseDetails,
  }) {
    try {
      // For Android, extract from purchase JSON
      if (purchaseDetails.containsKey('expiryTimeMillis')) {
        final expiryMillis = purchaseDetails['expiryTimeMillis'] as int;
        return DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      }

      // For iOS, extract from receipt
      if (purchaseDetails.containsKey('expires_date')) {
        final expiryDateStr = purchaseDetails['expires_date'] as String;
        return DateTime.parse(expiryDateStr);
      }

      // Calculate expiry based on product type (fallback)
      final now = DateTime.now();
      if (productId.contains('monthly')) {
        return now.add(const Duration(days: 30));
      } else if (productId.contains('yearly')) {
        return now.add(const Duration(days: 365));
      } else if (productId.contains('lifetime')) {
        return null; // Lifetime has no expiry
      }

      return null;
    } catch (e) {
      AppLogger.error('Error extracting expiry date', e);
      return null;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
