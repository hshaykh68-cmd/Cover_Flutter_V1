import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/config/limits_enforcement.dart';
import 'package:cover/domain/repository/vault_repository.dart';
import 'package:cover/domain/repository/media_item_repository.dart';
import 'package:cover/data/local/database/tables.dart';

@GenerateMocks([AppConfig, VaultRepository, MediaItemRepository])
import 'limits_enforcement_test.mocks.dart';

void main() {
  group('LimitsEnforcement', () {
    late LimitsEnforcement limitsEnforcement;
    late MockAppConfig mockAppConfig;
    late MockVaultRepository mockVaultRepository;
    late MockMediaItemRepository mockMediaItemRepository;

    setUp(() {
      mockAppConfig = MockAppConfig();
      mockVaultRepository = MockVaultRepository();
      mockMediaItemRepository = MockMediaItemRepository();
      limitsEnforcement = LimitsEnforcement(
        mockAppConfig,
        mockVaultRepository,
        mockMediaItemRepository,
      );
    });

    group('Limit Constants', () {
      test('should return max free items from config', () {
        when(mockAppConfig.maxFreeItems).thenReturn(50);

        expect(limitsEnforcement.maxFreeItems, equals(50));
      });

      test('should return max free vaults from config', () {
        when(mockAppConfig.maxFreeVaults).thenReturn(1);

        expect(limitsEnforcement.maxFreeVaults, equals(1));
      });

      test('should return upsell trigger items remaining from config', () {
        when(mockAppConfig.upsellTriggerItemsRemaining).thenReturn(10);

        expect(limitsEnforcement.upsellTriggerItemsRemaining, equals(10));
      });
    });

    group('Get Items Remaining', () {
      test('should return remaining items when under limit', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => [
                  MediaItem(id: 1, vaultId: 'vault-1', type: 'photo', encryptedFilePath: '', originalFileName: '', fileSize: 1000, mimeType: 'image/jpeg'),
                  MediaItem(id: 2, vaultId: 'vault-1', type: 'photo', encryptedFilePath: '', originalFileName: '', fileSize: 1000, mimeType: 'image/jpeg'),
                ]);

        final remaining = await limitsEnforcement.getItemsRemaining('vault-1');

        expect(remaining, equals(48));
      });

      test('should return 0 when at limit', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => List.generate(50, (i) => MediaItem(
                  id: i,
                  vaultId: 'vault-1',
                  type: 'photo',
                  encryptedFilePath: '',
                  originalFileName: '',
                  fileSize: 1000,
                  mimeType: 'image/jpeg',
                )));

        final remaining = await limitsEnforcement.getItemsRemaining('vault-1');

        expect(remaining, equals(0));
      });

      test('should return 0 on error', () async {
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenThrow(Exception('Database error'));

        final remaining = await limitsEnforcement.getItemsRemaining('vault-1');

        expect(remaining, equals(0));
      });
    });

    group('Get Vaults Remaining', () {
      test('should return remaining vaults when under limit', () async {
        when(mockAppConfig.maxFreeVaults).thenReturn(3);
        when(mockVaultRepository.getAllVaults())
            .thenAnswer((_) async => [
                  Vault(id: 'vault-1', type: 'real', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                ]);

        final remaining = await limitsEnforcement.getVaultsRemaining();

        expect(remaining, equals(2));
      });

      test('should return 0 when at limit', () async {
        when(mockAppConfig.maxFreeVaults).thenReturn(1);
        when(mockVaultRepository.getAllVaults())
            .thenAnswer((_) async => [
                  Vault(id: 'vault-1', type: 'real', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                ]);

        final remaining = await limitsEnforcement.getVaultsRemaining();

        expect(remaining, equals(0));
      });
    });

    group('Can Add Items', () {
      test('should return withinLimit when under limit', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => [
                  MediaItem(id: 1, vaultId: 'vault-1', type: 'photo', encryptedFilePath: '', originalFileName: '', fileSize: 1000, mimeType: 'image/jpeg'),
                ]);

        final result = await limitsEnforcement.canAddItems('vault-1', 10);

        expect(result, equals(LimitResult.withinLimit));
      });

      test('should return atLimit when adding would hit limit', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => List.generate(45, (i) => MediaItem(
                  id: i,
                  vaultId: 'vault-1',
                  type: 'photo',
                  encryptedFilePath: '',
                  originalFileName: '',
                  fileSize: 1000,
                  mimeType: 'image/jpeg',
                )));

        final result = await limitsEnforcement.canAddItems('vault-1', 5);

        expect(result, equals(LimitResult.atLimit));
      });

      test('should return exceededLimit when adding would exceed limit', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => List.generate(45, (i) => MediaItem(
                  id: i,
                  vaultId: 'vault-1',
                  type: 'photo',
                  encryptedFilePath: '',
                  originalFileName: '',
                  fileSize: 1000,
                  mimeType: 'image/jpeg',
                )));

        final result = await limitsEnforcement.canAddItems('vault-1', 10);

        expect(result, equals(LimitResult.exceededLimit));
      });

      test('should return exceededLimit on error', () async {
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenThrow(Exception('Database error'));

        final result = await limitsEnforcement.canAddItems('vault-1', 10);

        expect(result, equals(LimitResult.exceededLimit));
      });
    });

    group('Can Create Vault', () {
      test('should return withinLimit when under limit', () async {
        when(mockAppConfig.maxFreeVaults).thenReturn(3);
        when(mockVaultRepository.getAllVaults())
            .thenAnswer((_) async => [
                  Vault(id: 'vault-1', type: 'real', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                ]);

        final result = await limitsEnforcement.canCreateVault();

        expect(result, equals(LimitResult.withinLimit));
      });

      test('should return atLimit when creating would hit limit', () async {
        when(mockAppConfig.maxFreeVaults).thenReturn(2);
        when(mockVaultRepository.getAllVaults())
            .thenAnswer((_) async => [
                  Vault(id: 'vault-1', type: 'real', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                ]);

        final result = await limitsEnforcement.canCreateVault();

        expect(result, equals(LimitResult.atLimit));
      });

      test('should return exceededLimit when at limit', () async {
        when(mockAppConfig.maxFreeVaults).thenReturn(1);
        when(mockVaultRepository.getAllVaults())
            .thenAnswer((_) async => [
                  Vault(id: 'vault-1', type: 'real', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                ]);

        final result = await limitsEnforcement.canCreateVault();

        expect(result, equals(LimitResult.exceededLimit));
      });
    });

    group('Paywall Triggers', () {
      test('should trigger paywall when items remaining <= threshold', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockAppConfig.upsellTriggerItemsRemaining).thenReturn(10);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => List.generate(45, (i) => MediaItem(
                  id: i,
                  vaultId: 'vault-1',
                  type: 'photo',
                  encryptedFilePath: '',
                  originalFileName: '',
                  fileSize: 1000,
                  mimeType: 'image/jpeg',
                )));

        final trigger = await limitsEnforcement.shouldShowPaywallForItems('vault-1');

        expect(trigger.shouldShow, isTrue);
        expect(trigger.remaining, equals(5));
        expect(trigger.limit, equals(50));
      });

      test('should not trigger paywall when items remaining > threshold', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockAppConfig.upsellTriggerItemsRemaining).thenReturn(10);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => [
                  MediaItem(id: 1, vaultId: 'vault-1', type: 'photo', encryptedFilePath: '', originalFileName: '', fileSize: 1000, mimeType: 'image/jpeg'),
                ]);

        final trigger = await limitsEnforcement.shouldShowPaywallForItems('vault-1');

        expect(trigger.shouldShow, isFalse);
      });

      test('should trigger paywall at limit with appropriate message', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockAppConfig.upsellTriggerItemsRemaining).thenReturn(10);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => List.generate(50, (i) => MediaItem(
                  id: i,
                  vaultId: 'vault-1',
                  type: 'photo',
                  encryptedFilePath: '',
                  originalFileName: '',
                  fileSize: 1000,
                  mimeType: 'image/jpeg',
                )));

        final trigger = await limitsEnforcement.shouldShowPaywallForItems('vault-1');

        expect(trigger.shouldShow, isTrue);
        expect(trigger.reason, contains('reached your free limit'));
      });

      test('should trigger paywall for vaults when at limit', () async {
        when(mockAppConfig.maxFreeVaults).thenReturn(1);
        when(mockVaultRepository.getAllVaults())
            .thenAnswer((_) async => [
                  Vault(id: 'vault-1', type: 'real', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                ]);

        final trigger = await limitsEnforcement.shouldShowPaywallForVaults();

        expect(trigger.shouldShow, isTrue);
        expect(trigger.reason, contains('reached your free limit'));
      });
    });

    group('Limit Checks', () {
      test('should return true when approaching item limit', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockAppConfig.upsellTriggerItemsRemaining).thenReturn(10);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => List.generate(42, (i) => MediaItem(
                  id: i,
                  vaultId: 'vault-1',
                  type: 'photo',
                  encryptedFilePath: '',
                  originalFileName: '',
                  fileSize: 1000,
                  mimeType: 'image/jpeg',
                )));

        final isApproaching = await limitsEnforcement.isApproachingItemLimit('vault-1');

        expect(isApproaching, isTrue);
      });

      test('should return false when not approaching item limit', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockAppConfig.upsellTriggerItemsRemaining).thenReturn(10);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => [
                  MediaItem(id: 1, vaultId: 'vault-1', type: 'photo', encryptedFilePath: '', originalFileName: '', fileSize: 1000, mimeType: 'image/jpeg'),
                ]);

        final isApproaching = await limitsEnforcement.isApproachingItemLimit('vault-1');

        expect(isApproaching, isFalse);
      });

      test('should return true when at item limit', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => List.generate(50, (i) => MediaItem(
                  id: i,
                  vaultId: 'vault-1',
                  type: 'photo',
                  encryptedFilePath: '',
                  originalFileName: '',
                  fileSize: 1000,
                  mimeType: 'image/jpeg',
                )));

        final atLimit = await limitsEnforcement.isAtItemLimit('vault-1');

        expect(atLimit, isTrue);
      });

      test('should return true on error when checking item limit', () async {
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenThrow(Exception('Database error'));

        final atLimit = await limitsEnforcement.isAtItemLimit('vault-1');

        expect(atLimit, isTrue); // Fail-safe: deny if we can't check
      });

      test('should return true when at vault limit', () async {
        when(mockAppConfig.maxFreeVaults).thenReturn(1);
        when(mockVaultRepository.getAllVaults())
            .thenAnswer((_) async => [
                  Vault(id: 'vault-1', type: 'real', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                ]);

        final atLimit = await limitsEnforcement.isAtVaultLimit();

        expect(atLimit, isTrue);
      });
    });

    group('Usage Statistics', () {
      test('should return correct usage stats', () async {
        when(mockAppConfig.maxFreeItems).thenReturn(50);
        when(mockAppConfig.maxFreeVaults).thenReturn(3);
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenAnswer((_) async => List.generate(25, (i) => MediaItem(
                  id: i,
                  vaultId: 'vault-1',
                  type: 'photo',
                  encryptedFilePath: '',
                  originalFileName: '',
                  fileSize: 1000,
                  mimeType: 'image/jpeg',
                )));
        when(mockVaultRepository.getAllVaults())
            .thenAnswer((_) async => [
                  Vault(id: 'vault-1', type: 'real', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                  Vault(id: 'vault-2', type: 'decoy', itemCount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
                ]);

        final stats = await limitsEnforcement.getUsageStats('vault-1');

        expect(stats['itemCount'], equals(25));
        expect(stats['itemLimit'], equals(50));
        expect(stats['vaultCount'], equals(2));
        expect(stats['vaultLimit'], equals(3));
        expect(stats['itemsRemaining'], equals(25));
        expect(stats['vaultsRemaining'], equals(1));
      });

      test('should return empty map on error', () async {
        when(mockMediaItemRepository.getMediaItemsByVault('vault-1'))
            .thenThrow(Exception('Database error'));

        final stats = await limitsEnforcement.getUsageStats('vault-1');

        expect(stats, isEmpty);
      });
    });
  });
}
