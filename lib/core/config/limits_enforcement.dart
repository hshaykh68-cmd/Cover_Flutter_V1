import 'package:cover/core/config/app_config.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:cover/domain/repository/vault_repository.dart';
import 'package:cover/domain/repository/media_item_repository.dart';

/// Result of a limit check
enum LimitResult {
  withinLimit,
  atLimit,
  exceededLimit,
}

/// Paywall trigger information
class PaywallTrigger {
  final bool shouldShow;
  final String reason;
  final int remaining;
  final int limit;

  PaywallTrigger({
    required this.shouldShow,
    required this.reason,
    required this.remaining,
    required this.limit,
  });

  factory PaywallTrigger.noTrigger() {
    return PaywallTrigger(
      shouldShow: false,
      reason: '',
      remaining: 0,
      limit: 0,
    );
  }
}

/// Service for enforcing free tier limits controlled by Remote Config
/// Handles item limits, vault limits, and paywall trigger detection
class LimitsEnforcement {
  final AppConfig _config;
  final VaultRepository _vaultRepository;
  final MediaItemRepository _mediaItemRepository;

  LimitsEnforcement(
    this._config,
    this._vaultRepository,
    this._mediaItemRepository,
  );

  // ========== Item Limits ==========
  
  /// Get the maximum number of items allowed for free tier
  int get maxFreeItems => _config.maxFreeItems;

  /// Get the maximum number of vaults allowed for free tier
  int get maxFreeVaults => _config.maxFreeVaults;

  /// Get the number of items remaining before hitting the limit
  Future<int> getItemsRemaining(String vaultId) async {
    try {
      final items = await _mediaItemRepository.getMediaItemsByVault(vaultId);
      final currentCount = items.length;
      final remaining = maxFreeItems - currentCount;
      return remaining > 0 ? remaining : 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get items remaining', e, stackTrace);
      return 0;
    }
  }

  /// Get the number of vaults remaining before hitting the limit
  Future<int> getVaultsRemaining() async {
    try {
      final vaults = await _vaultRepository.getAllVaults();
      final currentCount = vaults.length;
      final remaining = maxFreeVaults - currentCount;
      return remaining > 0 ? remaining : 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get vaults remaining', e, stackTrace);
      return 0;
    }
  }

  /// Check if user can add more items to a vault
  Future<LimitResult> canAddItems(String vaultId, int count) async {
    try {
      final items = await _mediaItemRepository.getMediaItemsByVault(vaultId);
      final currentCount = items.length;
      final newCount = currentCount + count;

      if (newCount > maxFreeItems) {
        return LimitResult.exceededLimit;
      } else if (newCount == maxFreeItems) {
        return LimitResult.atLimit;
      } else {
        return LimitResult.withinLimit;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check item limit', e, stackTrace);
      return LimitResult.exceededLimit; // Fail safe: deny if we can't check
    }
  }

  /// Check if user can create more vaults
  Future<LimitResult> canCreateVault() async {
    try {
      final vaults = await _vaultRepository.getAllVaults();
      final currentCount = vaults.length;

      if (currentCount >= maxFreeVaults) {
        return LimitResult.exceededLimit;
      } else if (currentCount == maxFreeVaults - 1) {
        return LimitResult.atLimit;
      } else {
        return LimitResult.withinLimit;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check vault limit', e, stackTrace);
      return LimitResult.exceededLimit; // Fail safe: deny if we can't check
    }
  }

  // ========== Paywall Triggers ==========

  /// Get the trigger threshold for items remaining
  int get upsellTriggerItemsRemaining => _config.upsellTriggerItemsRemaining;

  /// Get the trigger threshold for days since install
  int get upsellTriggerAfterDays => _config.upsellTriggerAfterDays;

  /// Check if paywall should be shown based on item count
  Future<PaywallTrigger> shouldShowPaywallForItems(String vaultId) async {
    try {
      final remaining = await getItemsRemaining(vaultId);
      
      if (remaining <= upsellTriggerItemsRemaining) {
        return PaywallTrigger(
          shouldShow: true,
          reason: remaining == 0 
              ? 'You have reached your free limit of $maxFreeItems items' 
              : 'You have $remaining items remaining',
          remaining: remaining,
          limit: maxFreeItems,
        );
      }

      return PaywallTrigger.noTrigger();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check paywall trigger for items', e, stackTrace);
      return PaywallTrigger.noTrigger();
    }
  }

  /// Check if paywall should be shown based on vault count
  Future<PaywallTrigger> shouldShowPaywallForVaults() async {
    try {
      final remaining = await getVaultsRemaining();
      
      if (remaining <= 0) {
        return PaywallTrigger(
          shouldShow: true,
          reason: 'You have reached your free limit of $maxFreeVaults vaults',
          remaining: remaining,
          limit: maxFreeVaults,
        );
      }

      return PaywallTrigger.noTrigger();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check paywall trigger for vaults', e, stackTrace);
      return PaywallTrigger.noTrigger();
    }
  }

  /// Check if user is approaching limits (for UI warnings)
  Future<bool> isApproachingItemLimit(String vaultId) async {
    try {
      final remaining = await getItemsRemaining(vaultId);
      return remaining <= upsellTriggerItemsRemaining;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check if approaching item limit', e, stackTrace);
      return false;
    }
  }

  /// Check if user is at limit (for hard blocks)
  Future<bool> isAtItemLimit(String vaultId) async {
    try {
      final remaining = await getItemsRemaining(vaultId);
      return remaining <= 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check if at item limit', e, stackTrace);
      return true; // Fail safe: block if we can't check
    }
  }

  /// Check if user is at vault limit
  Future<bool> isAtVaultLimit() async {
    try {
      final remaining = await getVaultsRemaining();
      return remaining <= 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check if at vault limit', e, stackTrace);
      return true; // Fail safe: block if we can't check
    }
  }

  /// Get current usage statistics for display
  Future<Map<String, int>> getUsageStats(String vaultId) async {
    try {
      final items = await _mediaItemRepository.getMediaItemsByVault(vaultId);
      final vaults = await _vaultRepository.getAllVaults();
      
      return {
        'itemCount': items.length,
        'itemLimit': maxFreeItems,
        'vaultCount': vaults.length,
        'vaultLimit': maxFreeVaults,
        'itemsRemaining': maxFreeItems - items.length,
        'vaultsRemaining': maxFreeVaults - vaults.length,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get usage stats', e, stackTrace);
      return {};
    }
  }

  /// Log current limit status for debugging
  Future<void> logLimitStatus(String vaultId) async {
    try {
      final stats = await getUsageStats(vaultId);
      AppLogger.info('=== Limits Enforcement Status ===');
      AppLogger.info('Items: ${stats['itemCount']}/${stats['itemLimit']}');
      AppLogger.info('Vaults: ${stats['vaultCount']}/${stats['vaultLimit']}');
      AppLogger.info('Items Remaining: ${stats['itemsRemaining']}');
      AppLogger.info('Vaults Remaining: ${stats['vaultsRemaining']}');
      AppLogger.info('Upsell Trigger at: $upsellTriggerItemsRemaining items remaining');
      AppLogger.info('=================================');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to log limit status', e, stackTrace);
    }
  }
}
