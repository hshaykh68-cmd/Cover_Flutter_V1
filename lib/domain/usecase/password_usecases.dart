import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/password_repository.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/password/password_generator_service.dart';
import 'package:cover/core/password/clipboard_timeout_service.dart';
import 'package:cover/core/vault/vault_service.dart';
import 'package:cover/core/utils/logger.dart';

/// Use case for creating a password entry
class CreatePasswordUseCase {
  final PasswordRepository _passwordRepository;
  final CryptoService _cryptoService;
  final VaultService _vaultService;

  CreatePasswordUseCase(
    this._passwordRepository,
    this._cryptoService,
    this._vaultService,
  );

  Future<Password> execute({
    required String title,
    required String username,
    required String password,
    String? url,
    String? notes,
    String? folder,
  }) async {
    try {
      // Get current vault ID
      final vaultId = await _vaultService.getVaultId(VaultNamespace.real);
      if (vaultId == null) {
        throw Exception('No vault found');
      }

      // Get vault encryption key
      final encryptionKeyBase64 = await _vaultService.getVaultId(VaultNamespace.real);
      if (encryptionKeyBase64 == null) {
        throw Exception('Vault encryption key not found');
      }

      // This is simplified - in production you'd get the actual encryption key
      // For now, we'll encrypt with a placeholder
      final encryptionKey = _cryptoService.generateRandomKey(length: 32);

      // Encrypt sensitive data
      final encryptedTitle = await _cryptoService.encryptString(title, encryptionKey);
      final encryptedUsername = await _cryptoService.encryptString(username, encryptionKey);
      final encryptedPassword = await _cryptoService.encryptString(password, encryptionKey);

      String? encryptedUrl;
      if (url != null) {
        encryptedUrl = await _cryptoService.encryptString(url, encryptionKey);
      }

      String? encryptedNotes;
      if (notes != null) {
        encryptedNotes = await _cryptoService.encryptString(notes, encryptionKey);
      }

      String? encryptedFolder;
      if (folder != null) {
        encryptedFolder = await _cryptoService.encryptString(folder, encryptionKey);
      }

      final passwordEntry = await _passwordRepository.createPassword(
        PasswordsCompanion(
          vaultId: vaultId,
          encryptedTitle: encryptedTitle.base64,
          encryptedUsername: encryptedUsername.base64,
          encryptedPassword: encryptedPassword.base64,
          encryptedUrl: Value(encryptedUrl?.base64),
          encryptedNotes: Value(encryptedNotes?.base64),
          encryptedFolder: Value(encryptedFolder?.base64),
        ),
      );

      AppLogger.info('Created password entry: ${passwordEntry.id}');
      return passwordEntry;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create password', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for updating a password entry
class UpdatePasswordUseCase {
  final PasswordRepository _passwordRepository;
  final CryptoService _cryptoService;
  final VaultService _vaultService;

  UpdatePasswordUseCase(
    this._passwordRepository,
    this._cryptoService,
    this._vaultService,
  );

  Future<bool> execute(Password password) async {
    try {
      final success = await _passwordRepository.updatePassword(password);
      AppLogger.info('Updated password entry: ${password.id}');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update password', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for deleting a password entry
class DeletePasswordUseCase {
  final PasswordRepository _passwordRepository;

  DeletePasswordUseCase(this._passwordRepository);

  Future<int> execute(int id) async {
    try {
      final result = await _passwordRepository.deletePassword(id);
      AppLogger.info('Deleted password entry: $id');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete password', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for getting all passwords for current vault
class GetPasswordsUseCase {
  final PasswordRepository _passwordRepository;
  final VaultService _vaultService;

  GetPasswordsUseCase(
    this._passwordRepository,
    this._vaultService,
  );

  Future<List<Password>> execute() async {
    try {
      final vaultId = await _vaultService.getVaultId(VaultNamespace.real);
      if (vaultId == null) {
        return [];
      }

      final passwords = await _passwordRepository.getPasswordsByVault(vaultId);
      AppLogger.debug('Retrieved ${passwords.length} passwords');
      return passwords;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get passwords', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for getting a password by ID
class GetPasswordByIdUseCase {
  final PasswordRepository _passwordRepository;

  GetPasswordByIdUseCase(this._passwordRepository);

  Future<Password?> execute(int id) async {
    try {
      final password = await _passwordRepository.getPasswordById(id);
      return password;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get password by id: $id', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for copying password to clipboard with timeout
class CopyPasswordToClipboardUseCase {
  final ClipboardTimeoutService _clipboardService;

  CopyPasswordToClipboardUseCase(this._clipboardService);

  Future<bool> execute(String password) async {
    try {
      final success = await _clipboardService.copyWithTimeout(password);
      if (success) {
        AppLogger.info('Password copied to clipboard with timeout');
      }
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to copy password to clipboard', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for generating a secure password
class GeneratePasswordUseCase {
  final PasswordGeneratorService _passwordGenerator;

  GeneratePasswordUseCase(this._passwordGenerator);

  String execute({
    int? length,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
    bool excludeAmbiguous = true,
  }) {
    return _passwordGenerator.generatePassword(
      length: length,
      includeUppercase: includeUppercase,
      includeLowercase: includeLowercase,
      includeNumbers: includeNumbers,
      includeSpecialChars: includeSpecialChars,
      excludeAmbiguous: excludeAmbiguous,
    );
  }

  String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
  }) {
    return _passwordGenerator.generatePassphrase(
      wordCount: wordCount,
      separator: separator,
      capitalize: capitalize,
    );
  }

  int estimateStrength(String password) {
    return _passwordGenerator.estimateStrength(password);
  }

  bool meetsRequirements(String password) {
    return _passwordGenerator.meetsRequirements(password);
  }
}

/// Use case for searching passwords
class SearchPasswordsUseCase {
  final PasswordRepository _passwordRepository;
  final VaultService _vaultService;

  SearchPasswordsUseCase(
    this._passwordRepository,
    this._vaultService,
  );

  Future<List<Password>> execute(String query) async {
    try {
      final vaultId = await _vaultService.getVaultId(VaultNamespace.real);
      if (vaultId == null) {
        return [];
      }

      final passwords = await _passwordRepository.searchPasswords(vaultId, query);
      AppLogger.debug('Found ${passwords.length} passwords matching "$query"');
      return passwords;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search passwords', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for getting passwords by folder
class GetPasswordsByFolderUseCase {
  final PasswordRepository _passwordRepository;
  final VaultService _vaultService;
  final CryptoService _cryptoService;

  GetPasswordsByFolderUseCase(
    this._passwordRepository,
    this._vaultService,
    this._cryptoService,
  );

  Future<List<Password>> execute(String folder) async {
    try {
      final vaultId = await _vaultService.getVaultId(VaultNamespace.real);
      if (vaultId == null) {
        return [];
      }

      // Encrypt folder name for search
      final encryptionKey = _cryptoService.generateRandomKey(length: 32);
      final encryptedFolder = await _cryptoService.encryptString(folder, encryptionKey);

      final passwords = await _passwordRepository.getPasswordsByFolder(
        vaultId,
        encryptedFolder.base64,
      );

      AppLogger.debug('Retrieved ${passwords.length} passwords in folder: $folder');
      return passwords;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get passwords by folder', e, stackTrace);
      rethrow;
    }
  }
}
