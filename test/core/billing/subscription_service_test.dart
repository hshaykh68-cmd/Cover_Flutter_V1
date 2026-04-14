import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cover/core/billing/subscription_service.dart';
import 'package:cover/core/config/app_config.dart';

@GenerateMocks([
  AppConfig,
  InAppPurchase,
])
import 'subscription_service_test.mocks.dart';

void main() {
  group('SubscriptionService', () {
    late SubscriptionServiceImpl service;
    late MockAppConfig mockAppConfig;
    late MockInAppPurchase mockInAppPurchase;

    setUp(() {
      mockAppConfig = MockAppConfig();
      mockInAppPurchase = MockInAppPurchase();
      
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);
      when(mockInAppPurchase.queryProductDetails(any)).thenAnswer((_) async => QueryProductDetailsResponse(
        productDetails: [],
        notFoundIDs: [],
        error: null,
      ));
      when(mockInAppPurchase.queryPastPurchases()).thenAnswer((_) async => QueryPastPurchasesResponse(
        pastPurchases: [],
        error: null,
      ));
      when(mockInAppPurchase.purchaseStream).thenAnswer((_) => const Stream.empty());

      service = SubscriptionServiceImpl(
        appConfig: mockAppConfig,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize successfully', () async {
      // Act
      final result = await service.initialize();

      // Assert
      expect(result, true);
      expect(service.isAvailable, true);
    });

    test('should return false when in-app purchase not available', () async {
      // Arrange
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => false);

      // Act
      final result = await service.initialize();

      // Assert
      expect(result, false);
      expect(service.isAvailable, false);
    });

    test('should load products', () async {
      // Arrange
      await service.initialize();
      
      when(mockInAppPurchase.queryProductDetails(any)).thenAnswer((_) async => QueryProductDetailsResponse(
        productDetails: [
          ProductDetails(
            id: 'com.cover.subscription.monthly',
            title: 'Monthly Subscription',
            description: 'Monthly subscription',
            price: '\$9.99',
            rawPrice: 999,
            currencyCode: 'USD',
          ),
        ],
        notFoundIDs: [],
        error: null,
      ));

      // Act
      final products = await service.loadProducts();

      // Assert
      expect(products.length, 1);
      expect(products.first.productId, 'com.cover.subscription.monthly');
    });

    test('should return empty products when query fails', () async {
      // Arrange
      await service.initialize();
      
      when(mockInAppPurchase.queryProductDetails(any)).thenAnswer((_) async => QueryProductDetailsResponse(
        productDetails: [],
        notFoundIDs: [],
        error: Exception('Query failed'),
      ));

      // Act
      final products = await service.loadProducts();

      // Assert
      expect(products.length, 0);
    });

    test('should check entitlement status', () {
      // Act
      final status = service.entitlementStatus;

      // Assert
      expect(status.isPremium, false);
      expect(status.currentTier, SubscriptionTier.free);
      expect(status.adsRemoved, false);
    });

    test('should check if has active subscription', () async {
      // Act
      final result = await service.hasActiveSubscription();

      // Assert
      expect(result, false);
    });

    test('should get current tier', () async {
      // Act
      final tier = await service.getCurrentTier();

      // Assert
      expect(tier, SubscriptionTier.free);
    });

    test('should restore purchases', () async {
      // Arrange
      await service.initialize();

      // Act
      final result = await service.restorePurchases();

      // Assert
      expect(result.success, true);
    });

    test('should handle pending purchases', () async {
      // Arrange
      await service.initialize();

      // Act
      await service.handlePendingPurchases();

      // Assert - Should not throw
    });

    test('should return false for cancel subscription', () async {
      // Act
      final result = await service.cancelSubscription();

      // Assert
      expect(result, false);
    });

    test('should verify purchase', () async {
      // Act
      final result = await service.verifyPurchase('test_token');

      // Assert
      expect(result, true);
    });

    test('should get entitlement status stream', () {
      // Act
      final stream = service.entitlementStatusStream;

      // Assert
      expect(stream, isNotNull);
    });

    test('should dispose properly', () {
      // Act
      service.dispose();

      // Assert - Should not throw
    });

    test('should handle purchase product', () async {
      // Arrange
      await service.initialize();
      await service.loadProducts();

      // Act
      final result = await service.purchaseProduct('com.cover.subscription.monthly');

      // Assert
      expect(result.success, true);
    });

    test('should return error when purchasing non-existent product', () async {
      // Arrange
      await service.initialize();
      await service.loadProducts();

      // Act
      final result = await service.purchaseProduct('non_existent_product');

      // Assert
      expect(result.success, false);
      expect(result.error, contains('not found'));
    });
  });
}
