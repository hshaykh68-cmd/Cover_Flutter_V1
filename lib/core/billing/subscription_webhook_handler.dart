import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/billing/subscription_lifecycle_manager.dart';
import 'package:cover/data/repository/subscription_firestore_repository.dart';
import 'package:cover/core/config/app_config.dart';

/// Webhook handler for subscription events from Google Play and App Store
/// This would typically run on a server (Firebase Cloud Functions)
class SubscriptionWebhookHandler {
  final SubscriptionLifecycleManager _lifecycleManager;
  final AppConfig _appConfig;

  SubscriptionWebhookHandler({
    required SubscriptionLifecycleManager lifecycleManager,
    required AppConfig appConfig,
  }) : _lifecycleManager = lifecycleManager,
        _appConfig = appConfig;

  /// Handle Google Play Real-time Developer Notification
  Future<Response> handleGooglePlayNotification(Request request) async {
    try {
      if (!_appConfig.subscriptionWebhookEnabled) {
        return Response.forbidden('Webhooks disabled');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Verify signature (in production)
      // final signature = request.headers['X-Goog-Signature'];
      // if (!verifySignature(signature, body)) {
      //   return Response.forbidden('Invalid signature');
      // }

      final notificationType = data['notificationType'];
      final subscriptionNotification = data['subscriptionNotification'];

      switch (notificationType) {
        case 'SUBSCRIPTION_RENEWED':
          await _handleGooglePlayRenewal(subscriptionNotification);
          break;
        case 'SUBSCRIPTION_CANCELED':
          await _handleGooglePlayCancellation(subscriptionNotification);
          break;
        case 'SUBSCRIPTION_EXPIRED':
          await _handleGooglePlayExpiry(subscriptionNotification);
          break;
        case 'SUBSCRIPTION_PURCHASED':
          await _handleGooglePlayPurchase(subscriptionNotification);
          break;
        case 'SUBSCRIPTION_ON_HOLD':
          await _handleGooglePlayOnHold(subscriptionNotification);
          break;
        case 'SUBSCRIPTION_IN_GRACE_PERIOD':
          await _handleGooglePlayGracePeriod(subscriptionNotification);
          break;
        case 'SUBSCRIPTION_RESTARTED':
          await _handleGooglePlayRestarted(subscriptionNotification);
          break;
        default:
          AppLogger.warning('Unknown notification type: $notificationType');
      }

      return Response.ok('OK');
    } catch (e, stackTrace) {
      AppLogger.error('Error handling Google Play notification', e, stackTrace);
      return Response.internalServerError();
    }
  }

  /// Handle App Store Server Notification
  Future<Response> handleAppStoreNotification(Request request) async {
    try {
      if (!_appConfig.subscriptionWebhookEnabled) {
        return Response.forbidden('Webhooks disabled');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Verify signature (in production)
      // final signature = request.headers['X-Apple-Signature'];
      // if (!verifySignature(signature, body)) {
      //   return Response.forbidden('Invalid signature');
      // }

      final notificationType = data['notification_type'];
      final subscriptionNotification = data['subscription_notification'];

      switch (notificationType) {
        case 'RENEWAL':
          await _handleAppStoreRenewal(subscriptionNotification);
          break;
        case 'DID_FAIL_TO_RENEW':
          await _handleAppStoreFailedRenewal(subscriptionNotification);
          break;
        case 'DID_RECOVER':
          await _handleAppStoreRecovery(subscriptionNotification);
          break;
        case 'EXPIRED':
          await _handleAppStoreExpiry(subscriptionNotification);
          break;
        case 'CANCEL':
          await _handleAppStoreCancellation(subscriptionNotification);
          break;
        case 'PRICE_INCREASE':
          await _handleAppStorePriceIncrease(subscriptionNotification);
          break;
        case 'REFUND':
          await _handleAppStoreRefund(subscriptionNotification);
          break;
        default:
          AppLogger.warning('Unknown notification type: $notificationType');
      }

      return Response.ok('OK');
    } catch (e, stackTrace) {
      AppLogger.error('Error handling App Store notification', e, stackTrace);
      return Response.internalServerError();
    }
  }

  // Google Play handlers
  Future<void> _handleGooglePlayRenewal(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscriptionId'];
    final expiryTimeMillis = notification['expiryTimeMillis'];
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimeMillis);

    await _lifecycleManager.handleRenewal(
      subscriptionId: subscriptionId,
      newExpiryDate: expiryDate,
    );
  }

  Future<void> _handleGooglePlayCancellation(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscriptionId'];
    await _lifecycleManager.handleCancellation(
      subscriptionId: subscriptionId,
      immediate: false, // Cancel at period end
    );
  }

  Future<void> _handleGooglePlayExpiry(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscriptionId'];
    await _lifecycleManager.handleExpiry(subscriptionId);
  }

  Future<void> _handleGooglePlayPurchase(Map<String, dynamic> notification) async {
    // Initial purchase is handled by the app, but webhook confirms it
    AppLogger.info('Google Play purchase confirmed: ${notification['subscriptionId']}');
  }

  Future<void> _handleGooglePlayOnHold(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscriptionId'];
    // Subscription is on hold due to payment issues
    AppLogger.info('Subscription on hold: $subscriptionId');
  }

  Future<void> _handleGooglePlayGracePeriod(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscriptionId'];
    // Subscription entered grace period
    AppLogger.info('Subscription in grace period: $subscriptionId');
  }

  Future<void> _handleGooglePlayRestarted(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscriptionId'];
    final expiryTimeMillis = notification['expiryTimeMillis'];
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimeMillis);

    await _lifecycleManager.handleRenewal(
      subscriptionId: subscriptionId,
      newExpiryDate: expiryDate,
    );
  }

  // App Store handlers
  Future<void> _handleAppStoreRenewal(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscription_id'];
    final expiresDate = DateTime.parse(notification['expires_date']);

    await _lifecycleManager.handleRenewal(
      subscriptionId: subscriptionId,
      newExpiryDate: expiresDate,
    );
  }

  Future<void> _handleAppStoreFailedRenewal(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscription_id'];
    // Renewal failed, check grace period
    final inGrace = await _lifecycleManager.isInGracePeriod(subscriptionId);
    AppLogger.info('App Store renewal failed for $subscriptionId, in grace: $inGrace');
  }

  Future<void> _handleAppStoreRecovery(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscription_id'];
    final expiresDate = DateTime.parse(notification['expires_date']);

    await _lifecycleManager.handleRenewal(
      subscriptionId: subscriptionId,
      newExpiryDate: expiresDate,
    );
  }

  Future<void> _handleAppStoreExpiry(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscription_id'];
    await _lifecycleManager.handleExpiry(subscriptionId);
  }

  Future<void> _handleAppStoreCancellation(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscription_id'];
    await _lifecycleManager.handleCancellation(
      subscriptionId: subscriptionId,
      immediate: false,
    );
  }

  Future<void> _handleAppStorePriceIncrease(Map<String, dynamic> notification) async {
    // Price increase - notify user
    AppLogger.info('Price increase for subscription: ${notification['subscription_id']}');
  }

  Future<void> _handleAppStoreRefund(Map<String, dynamic> notification) async {
    final subscriptionId = notification['subscription_id'];
    await _lifecycleManager.handleRefund(
      subscriptionId: subscriptionId,
      reason: notification['reason'] ?? 'User requested',
    );
  }
}
