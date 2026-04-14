import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:cover/domain/repository/vault_repository.dart';
import 'package:cover/domain/repository/user_repository.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/utils/logger.dart';

enum VaultNamespace {
  real,
  decoy,
}

class VaultService {
  final VaultRepository _vaultRepository;
  final UserRepository _userRepository;
  final CryptoService _cryptoService;
  final Uuid _uuid = const Uuid();

  VaultService(this._vaultRepository, this._userRepository, this._cryptoService);

  /// Gets the vault ID for a specific namespace
  Future<String?> getVaultId(VaultNamespace namespace) async {
    try {
      final typeStr = namespace == VaultNamespace.real ? 'real' : 'decoy';
      final vaults = await _vaultRepository.getAllVaults();
      
      final vault = vaults.firstWhere(
        (v) => v.type == typeStr,
        orElse: () => throw Exception('Vault not found'),
      );
      
      return vault.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get vault ID for $namespace', e, stackTrace);
      return null;
    }
  }

  /// Checks if a vault exists for a specific namespace
  Future<bool> vaultExists(VaultNamespace namespace) async {
    try {
      final vaultId = await getVaultId(namespace);
      return vaultId != null;
    } catch (e) {
      return false;
    }
  }

  /// Creates a vault for a specific namespace
  Future<String> createVault(VaultNamespace namespace, {String? name}) async {
    try {
      final typeStr = namespace == VaultNamespace.real ? 'real' : 'decoy';
      
      // Generate a unique encryption key for this vault
      final encryptionKey = _cryptoService.generateRandomKey(length: 32);
      final encryptionKeyBase64 = _cryptoService.bytesToBase64(encryptionKey);
      
      final vaultId = await _vaultRepository.createVault(
        type: typeStr,
        name: name ?? (namespace == VaultNamespace.real ? 'My Vault' : 'Decoy Vault'),
        encryptionKey: encryptionKeyBase64,
      );
      
      AppLogger.info('Created $namespace vault: $vaultId with encryption key');
      return vaultId;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create $namespace vault', e, stackTrace);
      rethrow;
    }
  }

  /// Ensures a vault exists for a specific namespace, creates if it doesn't
  Future<String> ensureVaultExists(VaultNamespace namespace, {String? name}) async {
    final existingVaultId = await getVaultId(namespace);
    if (existingVaultId != null) {
      return existingVaultId;
    }
    
    return createVault(namespace, name: name);
  }

  /// Checks parity between real and decoy vaults
  /// Returns true if decoy vault exists and has parity with real vault
  Future<bool> checkVaultParity() async {
    try {
      final realVaultId = await getVaultId(VaultNamespace.real);
      final decoyVaultId = await getVaultId(VaultNamespace.decoy);
      
      if (realVaultId == null || decoyVaultId == null) {
        // Parity cannot be checked if one vault doesn't exist
        return false;
      }
      
      // Get vault information
      final vaults = await _vaultRepository.getAllVaults();
      final realVault = vaults.firstWhere((v) => v.id == realVaultId);
      final decoyVault = vaults.firstWhere((v) => v.id == decoyVaultId);
      
      // Check structural parity
      // In a full implementation, this would check:
      // - Same number of tabs enabled
      // - Same settings structure
      // - Similar data structure (not content)
      
      // For now, just check that both exist and have valid types
      return realVault.type == 'real' && decoyVault.type == 'decoy';
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check vault parity', e, stackTrace);
      return false;
    }
  }

  /// Syncs settings from real vault to decoy vault for parity
  Future<void> syncVaultSettings() async {
    try {
      final realVaultId = await getVaultId(VaultNamespace.real);
      final decoyVaultId = await getVaultId(VaultNamespace.decoy);
      
      if (realVaultId == null || decoyVaultId == null) {
        throw Exception('Both vaults must exist to sync settings');
      }
      
      // Get vaults
      final vaults = await _vaultRepository.getAllVaults();
      final realVault = vaults.firstWhere((v) => v.id == realVaultId);
      
      // Update decoy vault settings to match real vault
      // For now, we'll sync the name (in a full implementation, this would sync all settings)
      await _vaultRepository.updateVault(
        decoyVaultId,
        name: realVault.name,
      );
      
      AppLogger.info('Synced vault settings from real to decoy');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync vault settings', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a vault for a specific namespace
  Future<void> deleteVault(VaultNamespace namespace) async {
    try {
      final vaultId = await getVaultId(namespace);
      if (vaultId != null) {
        await _vaultRepository.deleteVault(vaultId);
        AppLogger.info('Deleted $namespace vault: $vaultId');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete $namespace vault', e, stackTrace);
      rethrow;
    }
  }

  /// Verify if a PIN is correct for the specified vault
  Future<bool> verifyPin(String pin, {VaultNamespace? namespace}) async {
    try {
      final vaultId = await getVaultId(namespace ?? VaultNamespace.real);
      if (vaultId == null) {
        return false;
      }

      // Load stored hash + salt from Users table via UserRepository
      final user = await _userRepository.getUserByVaultId(vaultId);
      if (user == null) {
        return false;
      }

      final storedSalt = _cryptoService.base64ToBytes(user.pinSalt);
      final candidateHash = await _cryptoService.hashPin(pin, storedSalt);
      final storedHash = _cryptoService.base64ToBytes(user.pinHash);
      final candidateBytes = _cryptoService.base64ToBytes(candidateHash);

      return _cryptoService.constantTimeCompare(storedHash, candidateBytes);
    } catch (e, st) {
      AppLogger.error('PIN verification failed', e, st);
      return false;
    }
  }

  /// Change the PIN for the specified vault
  Future<void> changePin(String oldPin, String newPin, {VaultNamespace? namespace}) async {
    try {
      final vaultId = await getVaultId(namespace ?? VaultNamespace.real);
      if (vaultId == null) {
        throw Exception('Vault not found');
      }

      // Verify old PIN first
      final isOldPinValid = await verifyPin(oldPin, namespace: namespace);
      if (!isOldPinValid) {
        throw Exception('Old PIN is incorrect');
      }

      // Get user for this vault
      final user = await _userRepository.getUserByVaultId(vaultId);
      if (user == null) {
        throw Exception('User not found for vault');
      }

      // Generate new PIN hash and salt
      final salt = _cryptoService.generateRandomKey(length: 16);
      final pinHash = await _cryptoService.hashPin(newPin, salt);
      final saltBase64 = _cryptoService.bytesToBase64(salt);

      // Update PIN in user repository
      final success = await _userRepository.updateUserPin(user.id, pinHash, saltBase64);
      if (!success) {
        throw Exception('Failed to update PIN in database');
      }

      AppLogger.info('PIN changed for vault: $vaultId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to change PIN', e, stackTrace);
      rethrow;
    }
  }

  Future<Uint8List> getEncryptionKey({VaultNamespace namespace = VaultNamespace.real}) async {
    final vaultId = await getVaultId(namespace);
    if (vaultId == null) throw Exception('Vault not found');
    final vault = await _vaultRepository.getVaultById(vaultId);
    if (vault == null) throw Exception('Vault not found');
    return _cryptoService.base64ToBytes(vault.encryptionKey);
  }
}
