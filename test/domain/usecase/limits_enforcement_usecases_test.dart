import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cover/core/config/limits_enforcement.dart';
import 'package:cover/domain/usecase/limits_enforcement_usecases.dart';

@GenerateMocks([LimitsEnforcement])
import 'limits_enforcement_usecases_test.mocks.dart';

void main() {
  group('Limits Enforcement Use Cases', () {
    late MockLimitsEnforcement mockLimitsEnforcement;

    setUp(() {
      mockLimitsEnforcement = MockLimitsEnforcement();
    });

    group('CanAddItemsUseCase', () {
      test('should return withinLimit when under limit', () async {
        when(mockLimitsEnforcement.canAddItems('vault-1', 5))
            .thenAnswer((_) async => LimitResult.withinLimit);
        final useCase = CanAddItemsUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1', 5);

        expect(result, equals(LimitResult.withinLimit));
      });

      test('should return atLimit when at limit', () async {
        when(mockLimitsEnforcement.canAddItems('vault-1', 5))
            .thenAnswer((_) async => LimitResult.atLimit);
        final useCase = CanAddItemsUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1', 5);

        expect(result, equals(LimitResult.atLimit));
      });

      test('should return exceededLimit when over limit', () async {
        when(mockLimitsEnforcement.canAddItems('vault-1', 5))
            .thenAnswer((_) async => LimitResult.exceededLimit);
        final useCase = CanAddItemsUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1', 5);

        expect(result, equals(LimitResult.exceededLimit));
      });
    });

    group('CanCreateVaultUseCase', () {
      test('should return withinLimit when under limit', () async {
        when(mockLimitsEnforcement.canCreateVault())
            .thenAnswer((_) async => LimitResult.withinLimit);
        final useCase = CanCreateVaultUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result, equals(LimitResult.withinLimit));
      });

      test('should return atLimit when at limit', () async {
        when(mockLimitsEnforcement.canCreateVault())
            .thenAnswer((_) async => LimitResult.atLimit);
        final useCase = CanCreateVaultUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result, equals(LimitResult.atLimit));
      });

      test('should return exceededLimit when over limit', () async {
        when(mockLimitsEnforcement.canCreateVault())
            .thenAnswer((_) async => LimitResult.exceededLimit);
        final useCase = CanCreateVaultUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result, equals(LimitResult.exceededLimit));
      });
    });

    group('GetItemsRemainingUseCase', () {
      test('should return remaining items count', () async {
        when(mockLimitsEnforcement.getItemsRemaining('vault-1'))
            .thenAnswer((_) async => 25);
        final useCase = GetItemsRemainingUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result, equals(25));
      });

      test('should return 0 when at limit', () async {
        when(mockLimitsEnforcement.getItemsRemaining('vault-1'))
            .thenAnswer((_) async => 0);
        final useCase = GetItemsRemainingUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result, equals(0));
      });
    });

    group('GetVaultsRemainingUseCase', () {
      test('should return remaining vaults count', () async {
        when(mockLimitsEnforcement.getVaultsRemaining())
            .thenAnswer((_) async => 2);
        final useCase = GetVaultsRemainingUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result, equals(2));
      });

      test('should return 0 when at limit', () async {
        when(mockLimitsEnforcement.getVaultsRemaining())
            .thenAnswer((_) async => 0);
        final useCase = GetVaultsRemainingUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result, equals(0));
      });
    });

    group('ShouldShowPaywallForItemsUseCase', () {
      test('should return trigger with shouldShow true when limit reached', () async {
        final trigger = PaywallTrigger(
          shouldShow: true,
          reason: 'You have reached your free item limit',
          remaining: 0,
          limit: 50,
        );
        when(mockLimitsEnforcement.shouldShowPaywallForItems('vault-1'))
            .thenAnswer((_) async => trigger);
        final useCase = ShouldShowPaywallForItemsUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result.shouldShow, isTrue);
        expect(result.remaining, equals(0));
        expect(result.limit, equals(50));
      });

      test('should return trigger with shouldShow false when not at limit', () async {
        final trigger = PaywallTrigger(
          shouldShow: false,
          reason: '',
          remaining: 25,
          limit: 50,
        );
        when(mockLimitsEnforcement.shouldShowPaywallForItems('vault-1'))
            .thenAnswer((_) async => trigger);
        final useCase = ShouldShowPaywallForItemsUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result.shouldShow, isFalse);
        expect(result.remaining, equals(25));
      });
    });

    group('ShouldShowPaywallForVaultsUseCase', () {
      test('should return trigger with shouldShow true when limit reached', () async {
        final trigger = PaywallTrigger(
          shouldShow: true,
          reason: 'You have reached your free vault limit',
          remaining: 0,
          limit: 1,
        );
        when(mockLimitsEnforcement.shouldShowPaywallForVaults())
            .thenAnswer((_) async => trigger);
        final useCase = ShouldShowPaywallForVaultsUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result.shouldShow, isTrue);
        expect(result.remaining, equals(0));
        expect(result.limit, equals(1));
      });

      test('should return trigger with shouldShow false when not at limit', () async {
        final trigger = PaywallTrigger(
          shouldShow: false,
          reason: '',
          remaining: 1,
          limit: 3,
        );
        when(mockLimitsEnforcement.shouldShowPaywallForVaults())
            .thenAnswer((_) async => trigger);
        final useCase = ShouldShowPaywallForVaultsUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result.shouldShow, isFalse);
        expect(result.remaining, equals(1));
      });
    });

    group('IsApproachingItemLimitUseCase', () {
      test('should return true when approaching limit', () async {
        when(mockLimitsEnforcement.isApproachingItemLimit('vault-1'))
            .thenAnswer((_) async => true);
        final useCase = IsApproachingItemLimitUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result, isTrue);
      });

      test('should return false when not approaching limit', () async {
        when(mockLimitsEnforcement.isApproachingItemLimit('vault-1'))
            .thenAnswer((_) async => false);
        final useCase = IsApproachingItemLimitUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result, isFalse);
      });
    });

    group('IsAtItemLimitUseCase', () {
      test('should return true when at item limit', () async {
        when(mockLimitsEnforcement.isAtItemLimit('vault-1'))
            .thenAnswer((_) async => true);
        final useCase = IsAtItemLimitUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result, isTrue);
      });

      test('should return false when not at item limit', () async {
        when(mockLimitsEnforcement.isAtItemLimit('vault-1'))
            .thenAnswer((_) async => false);
        final useCase = IsAtItemLimitUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result, isFalse);
      });
    });

    group('IsAtVaultLimitUseCase', () {
      test('should return true when at vault limit', () async {
        when(mockLimitsEnforcement.isAtVaultLimit())
            .thenAnswer((_) async => true);
        final useCase = IsAtVaultLimitUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result, isTrue);
      });

      test('should return false when not at vault limit', () async {
        when(mockLimitsEnforcement.isAtVaultLimit())
            .thenAnswer((_) async => false);
        final useCase = IsAtVaultLimitUseCase(mockLimitsEnforcement);

        final result = await useCase();

        expect(result, isFalse);
      });
    });

    group('GetUsageStatsUseCase', () {
      test('should return usage statistics', () async {
        final stats = {
          'itemCount': 25,
          'itemLimit': 50,
          'vaultCount': 1,
          'vaultLimit': 3,
          'itemsRemaining': 25,
          'vaultsRemaining': 2,
        };
        when(mockLimitsEnforcement.getUsageStats('vault-1'))
            .thenAnswer((_) async => stats);
        final useCase = GetUsageStatsUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result, equals(stats));
        expect(result['itemCount'], equals(25));
        expect(result['itemLimit'], equals(50));
        expect(result['itemsRemaining'], equals(25));
      });

      test('should return empty map on error', () async {
        when(mockLimitsEnforcement.getUsageStats('vault-1'))
            .thenAnswer((_) async => {});
        final useCase = GetUsageStatsUseCase(mockLimitsEnforcement);

        final result = await useCase('vault-1');

        expect(result, isEmpty);
      });
    });
  });
}
