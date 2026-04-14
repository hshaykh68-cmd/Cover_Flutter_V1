import '../repository/vault_repository.dart';
import '../model/vault.dart';

/// Use case for creating a vault
class CreateVaultUseCase {
  final VaultRepository _repository;

  CreateVaultUseCase(this._repository);

  Future<void> call(Vault vault) {
    return _repository.createVault(vault);
  }
}

/// Use case for retrieving a vault by ID
class GetVaultByIdUseCase {
  final VaultRepository _repository;

  GetVaultByIdUseCase(this._repository);

  Future<Vault?> call(String id) {
    return _repository.getVaultById(id);
  }
}

/// Use case for retrieving all vaults
class GetAllVaultsUseCase {
  final VaultRepository _repository;

  GetAllVaultsUseCase(this._repository);

  Future<List<Vault>> call() {
    return _repository.getAllVaults();
  }
}

/// Use case for retrieving the active vault
class GetActiveVaultUseCase {
  final VaultRepository _repository;

  GetActiveVaultUseCase(this._repository);

  Future<Vault?> call() {
    return _repository.getActiveVault();
  }
}

/// Use case for updating a vault
class UpdateVaultUseCase {
  final VaultRepository _repository;

  UpdateVaultUseCase(this._repository);

  Future<void> call(Vault vault) {
    return _repository.updateVault(vault);
  }
}

/// Use case for deleting a vault
class DeleteVaultUseCase {
  final VaultRepository _repository;

  DeleteVaultUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteVault(id);
  }
}

/// Use case for setting the active vault
class SetActiveVaultUseCase {
  final VaultRepository _repository;

  SetActiveVaultUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.setActiveVault(id);
  }
}

/// Use case for updating vault item count
class UpdateVaultItemCountUseCase {
  final VaultRepository _repository;

  UpdateVaultItemCountUseCase(this._repository);

  Future<void> call(String id, int count) {
    return _repository.updateItemCount(id, count);
  }
}
