import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/data/repository/subscription_firestore_repository.dart';
import 'package:cover/data/model/subscription_firestore_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing subscription lifecycle events
/// Handles renewals, cancellations, expiry, and grace periods
class SubscriptionLifecycleManager {
  final SubscriptionFirestoreRepository _firestoreRepository;
  final AppConfig _appConfig;
  final FirebaseAuth _auth;

  SubscriptionLifecycleManager({
    required SubscriptionFirestoreRepository firestoreRepository,
    required AppConfig appConfig,
    FirebaseAuth? auth,
  }) : _firestoreRepository = firestoreRepository,
        _appConfig = appConfig,
        _auth = auth ?? FirebaseAuth.instance;

  /// Handle subscription renewal
  Future<void> handleRenewal({
    required String subscriptionId,
    required DateTime newExpiryDate,
  }) async {
    try {
      await _firestoreRepository.updateExpiryDate(subscriptionId, newExpiryDate);
      AppLogger.info('Subscription renewed: $subscriptionId, new expiry: $newExpiryDate');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle renewal', e, stackTrace);
      rethrow;
    }
  }

  /// Handle subscription cancellation
  Future<void> handleCancellation({
    required String subscriptionId,
    required bool immediate,
  }) async {
    try {
      final subscription = await _getSubscriptionById(subscriptionId);
      if (subscription == null) {
        AppLogger.warning('Subscription not found: $subscriptionId');
        return;
      }

      if (immediate) {
        // Immediate cancellation - deactivate now
        await _firestoreRepository.deactivateSubscription(subscriptionId);
      } else {
        // Cancel at period end - disable auto-renewal
        final updated = subscription.copyWith(
          autoRenewEnabled: false,
          updatedAt: DateTime.now(),
        );
        await _firestoreRepository.upsertSubscription(updated);
      }

      AppLogger.info('Subscription cancelled: $subscriptionId, immediate: $immediate');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle cancellation', e, stackTrace);
      rethrow;
    }
  }

  /// Handle subscription expiry
  Future<void> handleExpiry(String subscriptionId) async {
    try {
      await _firestoreRepository.deactivateSubscription(subscriptionId);
      AppLogger.info('Subscription expired and deactivated: $subscriptionId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle expiry', e, stackTrace);
      rethrow;
    }
  }

  /// Handle refund
  Future<void> handleRefund({
    required String subscriptionId,
    required String reason,
  }) async {
    try {
      // Deactivate subscription on refund
      await _firestoreRepository.deactivateSubscription(subscriptionId);
      AppLogger.info('Subscription refunded: $subscriptionId, reason: $reason');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle refund', e, stackTrace);
      rethrow;
    }
  }

  /// Check if subscription is in grace period
  Future<bool> isInGracePeriod(String subscriptionId) async {
    try {
      final subscription = await _getSubscriptionById(subscriptionId);
      if (subscription == null || subscription.expiryDate == null) {
        return false;
      }

      final now = DateTime.now();
      final gracePeriodEnd = subscription.expiryDate!.add(
        Duration(days: _appConfig.subscriptionGracePeriodDays),
      );

      return now.isAfter(subscription.expiryDate!) && now.isBefore(gracePeriodEnd);
    } catch (e) {
      AppLogger.error('Failed to check grace period', e);
      return false;
    }
  }

  /// Get subscriptions expiring soon (for renewal reminders)
  Future<List<SubscriptionFirestoreModel>> getExpiringSubscriptions({
    int daysBefore = 3,
  }) async {
    try {
      final subscriptions = await _firestoreRepository.getUserSubscriptions();
      final now = DateTime.now();
      final warningDate = now.add(Duration(days: daysBefore));

      return subscriptions.where((sub) {
        if (!sub.isActive || sub.expiryDate == null) return false;
        return sub.expiryDate!.isBefore(warningDate) && sub.expiryDate!.isAfter(now);
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get expiring subscriptions', e);
      return [];
    }
  }

  /// Cleanup expired subscriptions
  Future<int> cleanupExpiredSubscriptions() async {
    try {
      return await _firestoreRepository.deleteExpiredSubscriptions();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup expired subscriptions', e, stackTrace);
      return 0;
    }
  }

  /// Get subscription by ID
  Future<SubscriptionFirestoreModel?> _getSubscriptionById(String subscriptionId) async {
    try {
      final subscriptions = await _firestoreRepository.getUserSubscriptions();
      return subscriptions.where((sub) => sub.subscriptionId == subscriptionId).firstOrNull;
    } catch (e) {
      AppLogger.error('Failed to get subscription by ID', e);
      return null;
    }
  }

  /// Sync subscription state with store
  /// This should be called periodically to ensure local state matches store
  Future<void> syncWithStore() async {
    try {
      // In production, this would call Play Developer API or App Store Server API
      // to get the latest subscription status and update Firestore accordingly
      AppLogger.info('Syncing subscription state with store (not implemented for production)');
      
      // For development, we'll just check local Firestore state
      final subscription = await _firestoreRepository.getCurrentSubscription();
      if (subscription != null && !subscription.isCurrentlyActive) {
        // Deactivate if expired
        if (subscription.subscriptionId != null) {
          await _firestoreRepository.deactivateSubscription(subscription.subscriptionId!);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync with store', e, stackTrace);
    }
  }
}
