import 'package:flutter_test/flutter_test.dart';
import 'package:cover/domain/usecase/password_usecases.dart';
import 'package:cover/domain/repository/password_repository.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/password/password_generator_service.dart';
import 'package:cover/core/password/clipboard_timeout_service.dart';
import 'package:cover/core/vault/vault_service.dart';
import 'package:cover/data/local/database/tables.dart';

class MockPasswordRepository implements PasswordRepository {
  final List<Password> _passwords = [];
  int _nextId = 1;

  @override
  Future<Password> createPassword(PasswordsCompanion password) async {
    final newPassword = Password(
      id: _nextId++,
      vaultId: password.vaultId.value,
      encryptedTitle: password.encryptedTitle.value,
      encryptedUsername: password.encryptedUsername.value,
      encryptedPassword: password.encryptedPassword.value,
      encryptedUrl: password.encryptedUrl.value,
      encryptedNotes: password.encryptedNotes.value,
      encryptedFolder: password.encryptedFolder.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _passwords.add(newPassword);
    return newPassword;
  }

  @override
  Future<bool> updatePassword(Password password) async {
    final index = _passwords.indexWhere((p) => p.id == password.id);
    if (index >= 0) {
      _passwords[index] = password;
      return true;
    }
    return false;
  }

  @override
  Future<int> deletePassword(int id) async {
    final initialLength = _passwords.length;
    _passwords.removeWhere((p) => p.id == id);
    return initialLength - _passwords.length;
  }

  @override
  Future<Password?> getPasswordById(int id) async {
    return _passwords.firstWhere((p) => p.id == id);
  }

  @override
  Future<List<Password>> getPasswordsByVault(String vaultId) async {
    return _passwords.where((p) => p.vaultId == vaultId).toList();
  }

  @override
  Future<List<Password>> getPasswordsByFolder(String vaultId, String encryptedFolder) async {
    return _passwords.where((p) => p.vaultId == vaultId && p.encryptedFolder == encryptedFolder).toList();
  }

  @override
  Future<List<Password>> searchPasswords(String vaultId, String query) async {
    return _passwords.where((p) => p.vaultId == vaultId && p.encryptedTitle.contains(query)).toList();
  }

  @override
  Future<int> getPasswordCount(String vaultId) async {
    return _passwords.where((p) => p.vaultId == vaultId).length;
  }

  @override
  Future<List<Password>> getAllPasswords() async => _passwords;
}

class MockCryptoService implements CryptoService {
  @override
  Future<DerivedKeyResult> deriveKey(String password, {Uint8List? salt}) async {
    return DerivedKeyResult(
      key: Uint8List(32),
      salt: salt ?? Uint8List(16),
    );
  }

  @override
  Future<Uint8List> deriveKeyWithSalt(String password, Uint8List salt) async {
    return Uint8List(32);
  }

  @override
  Future<EncryptedData> encrypt(Uint8List plaintext, Uint8List key, {Uint8List? associatedData, Uint8List? nonce}) async {
    return EncryptedData(
      base64: 'encrypted_base64',
      nonce: nonce ?? Uint8List(12),
    );
  }

  @override
  Future<Uint8List> decrypt(EncryptedData encryptedData, Uint8List key, {Uint8List? associatedData}) async {
    return Uint8List(0);
  }

  @override
  Future<EncryptedData> encryptString(String plaintext, Uint8List key, {Uint8List? associatedData, Uint8List? nonce}) async {
    return EncryptedData(
      base64: plaintext,
      nonce: nonce ?? Uint8List(12),
    );
  }

  @override
  Future<String> decryptString(EncryptedData encryptedData, Uint8List key, {Uint8List? associatedData}) async {
    return encryptedData.base64;
  }

  @override
  Uint8List generateRandomKey({int length = 32}) => Uint8List(length);

  @override
  Uint8List generateRandomSalt({int length = 16}) => Uint8List(length);

  @override
  Uint8List generateRandomNonce({int length = 12}) => Uint8List(length);

  @override
  Uint8List sha256Hash(Uint8List data) => Uint8List(32);

  @override
  bool constantTimeCompare(Uint8List a, Uint8List b) => true;

  @override
  String bytesToBase64(Uint8List data) => 'base64';

  @override
  Uint8List base64ToBytes(String base64) => Uint8List(0);

  @override
  Future<String> hashPin(String pin, Uint8List salt) async => 'hashed_pin';
}

class MockVaultService implements VaultService {
  @override
  Future<String?> getVaultId(VaultNamespace namespace) async => 'vault_1';

  @override
  Future<bool> vaultExists(VaultNamespace namespace) async => true;

  @override
  Future<String> createVault(VaultNamespace namespace, {String? name}) async => 'vault_1';

  @override
  Future<String> ensureVaultExists(VaultNamespace namespace, {String? name}) async => 'vault_1';

  @override
  Future<bool> checkVaultParity() async => true;

  @override
  Future<void> syncVaultSettings() async {}

  @override
  Future<void> deleteVault(VaultNamespace namespace) async {}

  @override
  Future<bool> verifyPin(String pin, {VaultNamespace? namespace}) async => true;

  @override
  Future<void> changePin(String oldPin, String newPin, {VaultNamespace? namespace}) async {}
}

class MockPasswordGeneratorService implements PasswordGeneratorService {
  @override
  String generatePassword({
    int? length,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
    bool excludeAmbiguous = true,
  }) {
    return 'GeneratedPassword123!';
  }

  @override
  String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
  }) {
    return 'correct-horse-battery-staple';
  }

  @override
  int estimateStrength(String password) => 80;

  @override
  bool meetsRequirements(String password) => true;
}

class MockClipboardTimeoutService implements ClipboardTimeoutService {
  @override
  Future<bool> copyWithTimeout(String text, {int? timeoutSeconds}) async => true;

  @override
  Future<bool> copyWithoutTimeout(String text) async => true;

  @override
  Future<bool> clearClipboard() async => true;

  @override
  Future<String?> getClipboardContent() async => null;

  @override
  void cancelTimeout() {}

  @override
  bool hasActiveTimeout() => false;
}

void main() {
  late CreatePasswordUseCase createPasswordUseCase;
  late UpdatePasswordUseCase updatePasswordUseCase;
  late DeletePasswordUseCase deletePasswordUseCase;
  late GetPasswordsUseCase getPasswordsUseCase;
  late GetPasswordByIdUseCase getPasswordByIdUseCase;
  late CopyPasswordToClipboardUseCase copyPasswordToClipboardUseCase;
  late GeneratePasswordUseCase generatePasswordUseCase;
  late SearchPasswordsUseCase searchPasswordsUseCase;

  late MockPasswordRepository mockPasswordRepository;
  late MockCryptoService mockCryptoService;
  late MockVaultService mockVaultService;
  late MockPasswordGeneratorService mockPasswordGeneratorService;
  late MockClipboardTimeoutService mockClipboardTimeoutService;

  setUp(() {
    mockPasswordRepository = MockPasswordRepository();
    mockCryptoService = MockCryptoService();
    mockVaultService = MockVaultService();
    mockPasswordGeneratorService = MockPasswordGeneratorService();
    mockClipboardTimeoutService = MockClipboardTimeoutService();

    createPasswordUseCase = CreatePasswordUseCase(
      mockPasswordRepository,
      mockCryptoService,
      mockVaultService,
    );
    updatePasswordUseCase = UpdatePasswordUseCase(
      mockPasswordRepository,
      mockCryptoService,
      mockVaultService,
    );
    deletePasswordUseCase = DeletePasswordUseCase(mockPasswordRepository);
    getPasswordsUseCase = GetPasswordsUseCase(
      mockPasswordRepository,
      mockVaultService,
    );
    getPasswordByIdUseCase = GetPasswordByIdUseCase(mockPasswordRepository);
    copyPasswordToClipboardUseCase = CopyPasswordToClipboardUseCase(mockClipboardTimeoutService);
    generatePasswordUseCase = GeneratePasswordUseCase(mockPasswordGeneratorService);
    searchPasswordsUseCase = SearchPasswordsUseCase(
      mockPasswordRepository,
      mockVaultService,
    );
  });

  group('PasswordUseCases', () {
    test('should create password', () async {
      final password = await createPasswordUseCase.execute(
        title: 'Test Password',
        username: 'testuser',
        password: 'testpass123',
      );

      expect(password, isNotNull);
      expect(password.id, greaterThan(0));
    });

    test('should update password', () async {
      final password = await createPasswordUseCase.execute(
        title: 'Test Password',
        username: 'testuser',
        password: 'testpass123',
      );

      final updated = await updatePasswordUseCase.execute(password);
      expect(updated, isTrue);
    });

    test('should delete password', () async {
      final password = await createPasswordUseCase.execute(
        title: 'Test Password',
        username: 'testuser',
        password: 'testpass123',
      );

      final deleted = await deletePasswordUseCase.execute(password.id);
      expect(deleted, 1);
    });

    test('should get all passwords', () async {
      await createPasswordUseCase.execute(
        title: 'Password 1',
        username: 'user1',
        password: 'pass1',
      );
      await createPasswordUseCase.execute(
        title: 'Password 2',
        username: 'user2',
        password: 'pass2',
      );

      final passwords = await getPasswordsUseCase.execute();
      expect(passwords.length, 2);
    });

    test('should get password by ID', () async {
      final password = await createPasswordUseCase.execute(
        title: 'Test Password',
        username: 'testuser',
        password: 'testpass123',
      );

      final found = await getPasswordByIdUseCase.execute(password.id);
      expect(found, isNotNull);
      expect(found?.id, equals(password.id));
    });

    test('should copy password to clipboard', () async {
      const testPassword = 'test_password_123';
      final result = await copyPasswordToClipboardUseCase.execute(testPassword);
      expect(result, isTrue);
    });

    test('should generate password', () {
      final password = generatePasswordUseCase.execute(length: 16);
      expect(password, equals('GeneratedPassword123!'));
    });

    test('should generate passphrase', () {
      final passphrase = generatePasswordUseCase.generatePassphrase();
      expect(passphrase, equals('correct-horse-battery-staple'));
    });

    test('should estimate password strength', () {
      final strength = generatePasswordUseCase.estimateStrength('TestPass123!');
      expect(strength, equals(80));
    });

    test('should check if password meets requirements', () {
      final meets = generatePasswordUseCase.meetsRequirements('TestPass123!');
      expect(meets, isTrue);
    });

    test('should search passwords', () async {
      await createPasswordUseCase.execute(
        title: 'Test Password',
        username: 'testuser',
        password: 'testpass123',
      );

      final results = await searchPasswordsUseCase.execute('Test');
      expect(results.length, greaterThan(0));
    });
  });
}
