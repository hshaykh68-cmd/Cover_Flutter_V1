import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/data/model/subscription_firestore_model.dart';

/// Repository for subscription operations in Firestore
class SubscriptionFirestoreRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _collectionName = 'subscriptions';

  SubscriptionFirestoreRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get subscription for current user
  Future<SubscriptionFirestoreModel?> getCurrentSubscription() async {
    if (_currentUserId == null) {
      AppLogger.warning('No authenticated user');
      return null;
    }

    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _currentUserId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return SubscriptionFirestoreModel.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get current subscription', e, stackTrace);
      return null;
    }
  }

  /// Create or update subscription
  Future<void> upsertSubscription(SubscriptionFirestoreModel subscription) async {
    if (_currentUserId == null) {
      AppLogger.warning('No authenticated user');
      return;
    }

    try {
      if (subscription.subscriptionId != null) {
        // Update existing
        await _firestore
            .collection(_collectionName)
            .doc(subscription.subscriptionId)
            .update(subscription.toFirestore());
      } else {
        // Create new
        await _firestore
            .collection(_collectionName)
            .add(subscription.toFirestore());
      }
      AppLogger.info('Subscription upserted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upsert subscription', e, stackTrace);
      rethrow;
    }
  }

  /// Deactivate subscription
  Future<void> deactivateSubscription(String subscriptionId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(subscriptionId)
          .update({
        'isActive': false,
        'autoRenewEnabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Subscription deactivated: $subscriptionId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to deactivate subscription', e, stackTrace);
      rethrow;
    }
  }

  /// Update subscription expiry date
  Future<void> updateExpiryDate(String subscriptionId, DateTime newExpiryDate) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(subscriptionId)
          .update({
        'expiryDate': Timestamp.fromDate(newExpiryDate),
        'lastRenewedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Subscription expiry updated: $subscriptionId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update expiry date', e, stackTrace);
      rethrow;
    }
  }

  /// Get subscription by purchase token
  Future<SubscriptionFirestoreModel?> getSubscriptionByPurchaseToken(String purchaseToken) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('purchaseToken', isEqualTo: purchaseToken)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return SubscriptionFirestoreModel.fromFirestore(querySnapshot.docs.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get subscription by purchase token', e, stackTrace);
      return null;
    }
  }

  /// Get all subscriptions for a user (for debugging)
  Future<List<SubscriptionFirestoreModel>> getUserSubscriptions() async {
    if (_currentUserId == null) {
      AppLogger.warning('No authenticated user');
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SubscriptionFirestoreModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user subscriptions', e, stackTrace);
      return [];
    }
  }

  /// Delete expired subscriptions (cleanup job)
  Future<int> deleteExpiredSubscriptions() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('expiryDate', isLessThan: Timestamp.fromDate(now))
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      AppLogger.info('Deactivated ${querySnapshot.docs.length} expired subscriptions');
      return querySnapshot.docs.length;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete expired subscriptions', e, stackTrace);
      return 0;
    }
  }
}
