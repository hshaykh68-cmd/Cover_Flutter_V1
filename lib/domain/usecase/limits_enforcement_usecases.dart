import 'package:cover/core/config/limits_enforcement.dart';

/// Use case to check if user can add items
class CanAddItemsUseCase {
  final LimitsEnforcement _limitsEnforcement;

  CanAddItemsUseCase(this._limitsEnforcement);

  Future<LimitResult> call(String vaultId, int count) async {
    return await _limitsEnforcement.canAddItems(vaultId, count);
  }
}

/// Use case to check if user can create a vault
class CanCreateVaultUseCase {
  final LimitsEnforcement _limitsEnforcement;

  CanCreateVaultUseCase(this._limitsEnforcement);

  Future<LimitResult> call() async {
    return await _limitsEnforcement.canCreateVault();
  }
}

/// Use case to get items remaining
class GetItemsRemainingUseCase {
  final LimitsEnforcement _limitsEnforcement;

  GetItemsRemainingUseCase(this._limitsEnforcement);

  Future<int> call(String vaultId) async {
    return await _limitsEnforcement.getItemsRemaining(vaultId);
  }
}

/// Use case to get vaults remaining
class GetVaultsRemainingUseCase {
  final LimitsEnforcement _limitsEnforcement;

  GetVaultsRemainingUseCase(this._limitsEnforcement);

  Future<int> call() async {
    return await _limitsEnforcement.getVaultsRemaining();
  }
}

/// Use case to check if paywall should be shown for items
class ShouldShowPaywallForItemsUseCase {
  final LimitsEnforcement _limitsEnforcement;

  ShouldShowPaywallForItemsUseCase(this._limitsEnforcement);

  Future<PaywallTrigger> call(String vaultId) async {
    return await _limitsEnforcement.shouldShowPaywallForItems(vaultId);
  }
}

/// Use case to check if paywall should be shown for vaults
class ShouldShowPaywallForVaultsUseCase {
  final LimitsEnforcement _limitsEnforcement;

  ShouldShowPaywallForVaultsUseCase(this._limitsEnforcement);

  Future<PaywallTrigger> call() async {
    return await _limitsEnforcement.shouldShowPaywallForVaults();
  }
}

/// Use case to check if user is approaching item limit
class IsApproachingItemLimitUseCase {
  final LimitsEnforcement _limitsEnforcement;

  IsApproachingItemLimitUseCase(this._limitsEnforcement);

  Future<bool> call(String vaultId) async {
    return await _limitsEnforcement.isApproachingItemLimit(vaultId);
  }
}

/// Use case to check if user is at item limit
class IsAtItemLimitUseCase {
  final LimitsEnforcement _limitsEnforcement;

  IsAtItemLimitUseCase(this._limitsEnforcement);

  Future<bool> call(String vaultId) async {
    return await _limitsEnforcement.isAtItemLimit(vaultId);
  }
}

/// Use case to check if user is at vault limit
class IsAtVaultLimitUseCase {
  final LimitsEnforcement _limitsEnforcement;

  IsAtVaultLimitUseCase(this._limitsEnforcement);

  Future<bool> call() async {
    return await _limitsEnforcement.isAtVaultLimit();
  }
}

/// Use case to get usage statistics
class GetUsageStatsUseCase {
  final LimitsEnforcement _limitsEnforcement;

  GetUsageStatsUseCase(this._limitsEnforcement);

  Future<Map<String, int>> call(String vaultId) async {
    return await _limitsEnforcement.getUsageStats(vaultId);
  }
}
