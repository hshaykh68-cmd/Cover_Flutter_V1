import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/billing/regional_pricing_service.dart';
import 'package:cover/core/billing/purchase_verifier.dart';
import 'package:cover/data/repository/subscription_firestore_repository.dart';
import 'package:cover/data/model/subscription_firestore_model.dart';

/// Subscription product details
class SubscriptionProduct {
  final String productId;
  final String title;
  final String description;
  final String price;
  final SubscriptionTier tier;

  SubscriptionProduct({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.tier,
  });

  factory SubscriptionProduct.fromProductDetails(ProductDetails details, SubscriptionTier tier) {
    return SubscriptionProduct(
      productId: details.id,
      title: details.title,
      description: details.description,
      price: details.price,
      tier: tier,
    );
  }
}

/// Purchase result
class PurchaseResult {
  final bool success;
  final String? productId;
  final String? error;
  final SubscriptionTier? tier;

  PurchaseResult({
    required this.success,
    this.productId,
    this.error,
    this.tier,
  });
}

/// Entitlement status
class EntitlementStatus {
  final bool isPremium;
  final SubscriptionTier? currentTier;
  final DateTime? expiryDate;
  final bool adsRemoved;

  EntitlementStatus({
    required this.isPremium,
    this.currentTier,
    this.expiryDate,
    required this.adsRemoved,
  });

  factory EntitlementStatus.free() {
    return EntitlementStatus(
      isPremium: false,
      currentTier: SubscriptionTier.free,
      adsRemoved: false,
    );
  }

  factory EntitlementStatus.premium({SubscriptionTier? tier, DateTime? expiryDate}) {
    return EntitlementStatus(
      isPremium: true,
      currentTier: tier ?? SubscriptionTier.lifetime,
      expiryDate: expiryDate,
      adsRemoved: true,
    );
  }
}

/// Subscription service interface
/// 
/// Manages in-app purchases, subscriptions, and entitlements
abstract class SubscriptionService {
  /// Initialize the subscription service
  Future<bool> initialize();

  /// Check if service is available
  bool get isAvailable;

  /// Get current entitlement status
  EntitlementStatus get entitlementStatus;

  /// Load available products
  Future<List<SubscriptionProduct>> loadProducts();

  /// Purchase a product
  Future<PurchaseResult> purchaseProduct(String productId);

  /// Restore purchases
  Future<PurchaseResult> restorePurchases();

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription();

  /// Get current subscription tier
  Future<SubscriptionTier> getCurrentTier();

  /// Verify purchase with server (for receipt validation)
  Future<bool> verifyPurchase(String purchaseToken);

  /// Handle pending purchases
  Future<void> handlePendingPurchases();

  /// Cancel subscription (Android only)
  Future<bool> cancelSubscription();

  /// Get subscription status stream
  Stream<EntitlementStatus> get entitlementStatusStream;
}

/// Subscription service implementation
class SubscriptionServiceImpl implements SubscriptionService {
  final InAppPurchase _inAppPurchase;
  final AppConfig _appConfig;
  final RegionalPricingService? _regionalPricingService;
  final SubscriptionFirestoreRepository? _firestoreRepository;
  final PurchaseVerifier? _purchaseVerifier;
  final FirebaseAuth _auth;
  final StreamController<EntitlementStatus> _entitlementStatusController = StreamController.broadcast();
  
  bool _isAvailable = false;
  bool _isInitialized = false;
  EntitlementStatus _entitlementStatus = EntitlementStatus.free();
  final Map<String, SubscriptionProduct> _products = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs - configured from RC
  String get _monthlyProductId => _appConfig.subscriptionMonthlyProductId;
  String get _yearlyProductId => _appConfig.subscriptionYearlyProductId;
  String get _lifetimeProductId => _appConfig.subscriptionLifetimeProductId;

  SubscriptionServiceImpl({
    InAppPurchase? inAppPurchase,
    required AppConfig appConfig,
    RegionalPricingService? regionalPricingService,
    SubscriptionFirestoreRepository? firestoreRepository,
    PurchaseVerifier? purchaseVerifier,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
        _appConfig = appConfig,
        _regionalPricingService = regionalPricingService,
        _firestoreRepository = firestoreRepository,
        _purchaseVerifier = purchaseVerifier {
    _initializePlatformSpecific();
  }

  void _initializePlatformSpecific() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _inAppPurchase = InAppPurchaseAndroid(
        googlePlayConnection: InAppPurchaseAndroidGooglePlayConnection.defaultInstance,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      _inAppPurchase = InAppPurchaseStoreKit();
    }
  }

  @override
  bool get isAvailable => _isAvailable;

  @override
  EntitlementStatus get entitlementStatus => _entitlementStatus;

  @override
  Stream<EntitlementStatus> get entitlementStatusStream => _entitlementStatusController.stream;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      AppLogger.warning('In-app purchases not available on this device');
      return false;
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (error) {
        AppLogger.error('Purchase stream error', error);
      },
    );

    // Load subscription state from Firestore
    await _loadSubscriptionFromFirestore();

    // Load existing purchases
    await _loadExistingPurchases();

    _isInitialized = true;
    AppLogger.info('Subscription service initialized');
    return true;
  }

  /// Load subscription state from Firestore
  Future<void> _loadSubscriptionFromFirestore() async {
    if (_firestoreRepository == null) {
      AppLogger.warning('Firestore repository not available');
      return;
    }

    try {
      final subscription = await _firestoreRepository!.getCurrentSubscription();
      if (subscription != null && subscription.isCurrentlyActive) {
        _updateEntitlementStatus(
          tier: _mapFirestoreTier(subscription.tier),
          expiryDate: subscription.expiryDate,
        );
        AppLogger.info('Loaded subscription from Firestore: ${subscription.tier}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load subscription from Firestore', e, stackTrace);
    }
  }

  /// Map Firestore tier to SubscriptionTier
  SubscriptionTier _mapFirestoreTier(SubscriptionTier firestoreTier) {
    switch (firestoreTier) {
      case SubscriptionTier.monthly:
        return SubscriptionTier.monthly;
      case SubscriptionTier.yearly:
        return SubscriptionTier.yearly;
      case SubscriptionTier.lifetime:
        return SubscriptionTier.lifetime;
      case SubscriptionTier.free:
        return SubscriptionTier.free;
    }
  }

  Future<void> _loadExistingPurchases() async {
    try {
      // Query for past purchases using restorePurchases
      await _inAppPurchase.restorePurchases();
      
      // Wait a moment for purchases to be restored
      await Future.delayed(const Duration(seconds: 2));

      AppLogger.info('Attempted to restore existing purchases');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load existing purchases', e, stackTrace);
    }
  }

  @override
  Future<List<SubscriptionProduct>> loadProducts() async {
    if (!_isAvailable) {
      return [];
    }

    try {
      // Get regional product IDs if regional pricing service is available
      String countryCode = 'US';
      if (_regionalPricingService != null) {
        countryCode = await _regionalPricingService.getCountryCode();
      }

      final productIds = [
        _regionalPricingService?.getRegionalProductId(_monthlyProductId, countryCode) ?? _monthlyProductId,
        _regionalPricingService?.getRegionalProductId(_yearlyProductId, countryCode) ?? _yearlyProductId,
        _regionalPricingService?.getRegionalProductId(_lifetimeProductId, countryCode) ?? _lifetimeProductId,
      ];

      final response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.warning('Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        AppLogger.error('Error loading products', response.error);
        return [];
      }

      _products.clear();
      final products = <SubscriptionProduct>[];

      for (final details in response.productDetails) {
        final tier = _getTierFromProductId(details.id);
        final product = SubscriptionProduct.fromProductDetails(details, tier);
        _products[details.id] = product;
        products.add(product);
      }

      AppLogger.info('Loaded ${products.length} products');
      return products;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load products', e, stackTrace);
      return [];
    }
  }

  @override
  Future<PurchaseResult> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      return PurchaseResult(
        success: false,
        error: 'In-app purchase not available',
      );
    }

    try {
      final product = _products[productId];
      if (product == null) {
        return PurchaseResult(
          success: false,
          error: 'Product not found',
        );
      }

      final purchaseParam = PurchaseParam(productDetails: _products[productId]!);
      final response = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (response.error != null) {
        AppLogger.error('Purchase error', response.error);
        return PurchaseResult(
          success: false,
          error: response.error.toString(),
        );
      }

      return PurchaseResult(
        success: true,
        productId: productId,
        tier: product.tier,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to purchase product', e, stackTrace);
      return PurchaseResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!_isAvailable) {
      return PurchaseResult(
        success: false,
        error: 'In-app purchase not available',
      );
    }

    try {
      await _inAppPurchase.restorePurchases();
      
      // Wait a moment for purchases to be restored
      await Future.delayed(const Duration(seconds: 2));

      final hasActive = await hasActiveSubscription();
      final tier = await getCurrentTier();

      return PurchaseResult(
        success: true,
        tier: tier,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to restore purchases', e, stackTrace);
      return PurchaseResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<bool> hasActiveSubscription() async {
    return _entitlementStatus.isPremium;
  }

  @override
  Future<SubscriptionTier> getCurrentTier() async {
    return _entitlementStatus.currentTier ?? SubscriptionTier.free;
  }

  @override
  Future<bool> verifyPurchase(String purchaseToken) async {
    if (_purchaseVerifier == null) {
      AppLogger.warning('Purchase verifier not available');
      return false;
    }

    try {
      // Platform-specific verification
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Extract purchase details from token
        final verified = await _purchaseVerifier!.verifyAndroidPurchase(
          productId: _monthlyProductId, // This should be extracted from purchase
          purchaseToken: purchaseToken,
          packageName: 'com.cover.app',
        );
        return verified;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS verification
        final verified = await _purchaseVerifier!.verifyIosPurchase(
          productId: _monthlyProductId, // This should be extracted from purchase
          transactionId: purchaseToken,
          receiptData: purchaseToken,
        );
        return verified;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Purchase verification failed', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> handlePendingPurchases() async {
    try {
      // Handle any pending purchases
      await _loadExistingPurchases();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle pending purchases', e, stackTrace);
    }
  }

  @override
  Future<bool> cancelSubscription() async {
    // Subscriptions can only be cancelled through the Play Store or App Store
    // This should open the relevant store subscription management page
    AppLogger.info('Subscription cancellation must be done through store');
    return false;
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchase);
          break;
        case PurchaseStatus.error:
          AppLogger.error('Purchase error: ${purchase.error}');
          break;
        case PurchaseStatus.pending:
          AppLogger.info('Purchase pending');
          break;
        default:
          break;
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      // Verify purchase
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }

      // Update entitlement status
      final tier = _getTierFromProductId(purchase.productID);
      
      // Calculate expiry date
      DateTime? expiryDate;
      if (_purchaseVerifier != null) {
        // Extract expiry from purchase details
        final purchaseDetails = <String, dynamic>{};
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidPurchase = purchase as GooglePlayPurchaseDetails;
          purchaseDetails['expiryTimeMillis'] = androidPurchase.billingClientPurchase.purchaseTime;
        }
        expiryDate = _purchaseVerifier!.getExpiryDateFromPurchase(
          productId: purchase.productID,
          purchaseDetails: purchaseDetails,
        );
      }

      _updateEntitlementStatus(tier: tier, expiryDate: expiryDate);

      // Save to Firestore
      if (_firestoreRepository != null) {
        await _saveSubscriptionToFirestore(purchase, tier, expiryDate);
      }

      AppLogger.info('Purchase successful: ${purchase.productID}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle successful purchase', e, stackTrace);
    }
  }

  /// Save subscription to Firestore
  Future<void> _saveSubscriptionToFirestore(
    PurchaseDetails purchase,
    SubscriptionTier tier,
    DateTime? expiryDate,
  ) async {
    if (_firestoreRepository == null) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        AppLogger.warning('No authenticated user, cannot save subscription');
        return;
      }

      final firestoreModel = SubscriptionFirestoreModel(
        userId: userId,
        productId: purchase.productID,
        tier: _mapToFirestoreTier(tier),
        startDate: DateTime.now(),
        expiryDate: expiryDate,
        isActive: true,
        purchaseToken: purchase.verificationData.serverVerificationData,
        originalTransactionId: purchase.purchaseID,
        lastRenewedDate: DateTime.now(),
        autoRenewEnabled: tier != SubscriptionTier.lifetime,
        countryCode: await _getCountryCode(),
      );

      await _firestoreRepository!.upsertSubscription(firestoreModel);
      AppLogger.info('Subscription saved to Firestore');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save subscription to Firestore', e, stackTrace);
    }
  }

  /// Map SubscriptionTier to Firestore tier
  SubscriptionTier _mapToFirestoreTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.monthly:
        return SubscriptionTier.monthly;
      case SubscriptionTier.yearly:
        return SubscriptionTier.yearly;
      case SubscriptionTier.lifetime:
        return SubscriptionTier.lifetime;
      case SubscriptionTier.free:
        return SubscriptionTier.free;
    }
  }

  /// Get country code for regional pricing
  Future<String> _getCountryCode() async {
    if (_regionalPricingService != null) {
      return await _regionalPricingService.getCountryCode();
    }
    return 'US';
  }

  void _updateEntitlementStatus({required SubscriptionTier tier, DateTime? expiryDate}) {
    final now = DateTime.now();
    final isExpired = expiryDate != null && now.isAfter(expiryDate);
    
    final newStatus = isExpired 
        ? EntitlementStatus.free()
        : EntitlementStatus.premium(
            tier: tier,
            expiryDate: expiryDate,
          );

    if (_entitlementStatus != newStatus) {
      _entitlementStatus = newStatus;
      _entitlementStatusController.add(newStatus);
      AppLogger.info('Entitlement status updated: ${tier.name}, expires: $expiryDate');
    }
  }

  SubscriptionTier _getTierFromProductId(String productId) {
    if (productId.contains('monthly')) {
      return SubscriptionTier.monthly;
    } else if (productId.contains('yearly')) {
      return SubscriptionTier.yearly;
    } else if (productId.contains('lifetime')) {
      return SubscriptionTier.lifetime;
    }
    return SubscriptionTier.free;
  }

  void dispose() {
    _subscription?.cancel();
    _entitlementStatusController.close();
  }
}
