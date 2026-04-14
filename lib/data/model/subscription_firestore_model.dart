import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore model for subscription state
class SubscriptionFirestoreModel {
  final String userId;
  final String? subscriptionId;
  final String productId;
  final SubscriptionTier tier;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final bool isActive;
  final String? purchaseToken;
  final String? originalTransactionId;
  final DateTime? lastRenewedDate;
  final bool autoRenewEnabled;
  final String? countryCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionFirestoreModel({
    required this.userId,
    this.subscriptionId,
    required this.productId,
    required this.tier,
    this.startDate,
    this.expiryDate,
    required this.isActive,
    this.purchaseToken,
    this.originalTransactionId,
    this.lastRenewedDate,
    required this.autoRenewEnabled,
    this.countryCode,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory SubscriptionFirestoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionFirestoreModel(
      userId: data['userId'] as String,
      subscriptionId: doc.id,
      productId: data['productId'] as String,
      tier: _parseTier(data['tier'] as String),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool,
      purchaseToken: data['purchaseToken'] as String?,
      originalTransactionId: data['originalTransactionId'] as String?,
      lastRenewedDate: (data['lastRenewedDate'] as Timestamp?)?.toDate(),
      autoRenewEnabled: data['autoRenewEnabled'] as bool,
      countryCode: data['countryCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'tier': tier.name,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isActive': isActive,
      'purchaseToken': purchaseToken,
      'originalTransactionId': originalTransactionId,
      'lastRenewedDate': lastRenewedDate != null ? Timestamp.fromDate(lastRenewedDate!) : null,
      'autoRenewEnabled': autoRenewEnabled,
      'countryCode': countryCode,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static SubscriptionTier _parseTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'monthly':
        return SubscriptionTier.monthly;
      case 'yearly':
        return SubscriptionTier.yearly;
      case 'lifetime':
        return SubscriptionTier.lifetime;
      default:
        return SubscriptionTier.free;
    }
  }

  /// Check if subscription is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (expiryDate == null) return true; // Lifetime
    return DateTime.now().isBefore(expiryDate!);
  }

  /// Create copy with updated fields
  SubscriptionFirestoreModel copyWith({
    String? subscriptionId,
    String? productId,
    SubscriptionTier? tier,
    DateTime? startDate,
    DateTime? expiryDate,
    bool? isActive,
    String? purchaseToken,
    String? originalTransactionId,
    DateTime? lastRenewedDate,
    bool? autoRenewEnabled,
    String? countryCode,
    DateTime? updatedAt,
  }) {
    return SubscriptionFirestoreModel(
      userId: userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      productId: productId ?? this.productId,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      originalTransactionId: originalTransactionId ?? this.originalTransactionId,
      lastRenewedDate: lastRenewedDate ?? this.lastRenewedDate,
      autoRenewEnabled: autoRenewEnabled ?? this.autoRenewEnabled,
      countryCode: countryCode ?? this.countryCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

enum SubscriptionTier {
  free,
  monthly,
  yearly,
  lifetime,
}
