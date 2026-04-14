import '../repository/user_repository.dart';
import '../model/user.dart';

/// Use case for creating a user
class CreateUserUseCase {
  final UserRepository _repository;

  CreateUserUseCase(this._repository);

  Future<int> call(User user) {
    return _repository.createUser(user);
  }
}

/// Use case for retrieving a user by vault ID
class GetUserByVaultIdUseCase {
  final UserRepository _repository;

  GetUserByVaultIdUseCase(this._repository);

  Future<User?> call(String vaultId) {
    return _repository.getUserByVaultId(vaultId);
  }
}

/// Use case for updating user settings
class UpdateUserUseCase {
  final UserRepository _repository;

  UpdateUserUseCase(this._repository);

  Future<void> call(User user) {
    return _repository.updateUser(user);
  }
}

/// Use case for updating biometric setting
class UpdateBiometricEnabledUseCase {
  final UserRepository _repository;

  UpdateBiometricEnabledUseCase(this._repository);

  Future<void> call(String vaultId, bool enabled) {
    return _repository.updateBiometricEnabled(vaultId, enabled);
  }
}

/// Use case for updating auto-lock settings
class UpdateAutoLockSettingsUseCase {
  final UserRepository _repository;

  UpdateAutoLockSettingsUseCase(this._repository);

  Future<void> call(String vaultId, bool enabled, int timeout) {
    return _repository.updateAutoLockSettings(vaultId, enabled, timeout);
  }
}

/// Use case for updating PIN hash
class UpdatePinUseCase {
  final UserRepository _repository;

  UpdatePinUseCase(this._repository);

  Future<void> call(String vaultId, String pinHash, String pinSalt) {
    return _repository.updatePin(vaultId, pinHash, pinSalt);
  }
}
