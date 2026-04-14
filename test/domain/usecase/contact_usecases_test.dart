import 'package:flutter_test/flutter_test.dart';
import 'package:cover/domain/usecase/contact_usecases.dart';
import 'package:cover/domain/repository/contact_repository.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/vault/vault_service.dart';
import 'package:cover/data/local/database/tables.dart';

class MockContactRepository implements ContactRepository {
  final List<Contact> _contacts = [];
  int _nextId = 1;

  @override
  Future<Contact> createContact(ContactsCompanion contact) async {
    final newContact = Contact(
      id: _nextId++,
      vaultId: contact.vaultId.value,
      encryptedName: contact.encryptedName.value,
      encryptedPhone: contact.encryptedPhone.value,
      encryptedEmail: contact.encryptedEmail.value,
      encryptedAddress: contact.encryptedAddress.value,
      encryptedNotes: contact.encryptedNotes.value,
      encryptedFolder: contact.encryptedFolder.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _contacts.add(newContact);
    return newContact;
  }

  @override
  Future<bool> updateContact(Contact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index >= 0) {
      _contacts[index] = contact;
      return true;
    }
    return false;
  }

  @override
  Future<int> deleteContact(int id) async {
    final initialLength = _contacts.length;
    _contacts.removeWhere((c) => c.id == id);
    return initialLength - _contacts.length;
  }

  @override
  Future<Contact?> getContactById(int id) async {
    return _contacts.firstWhere((c) => c.id == id);
  }

  @override
  Future<List<Contact>> getContactsByVault(String vaultId) async {
    return _contacts.where((c) => c.vaultId == vaultId).toList();
  }

  @override
  Future<List<Contact>> getContactsByFolder(String vaultId, String encryptedFolder) async {
    return _contacts.where((c) => c.vaultId == vaultId && c.encryptedFolder == encryptedFolder).toList();
  }

  @override
  Future<List<Contact>> searchContacts(String vaultId, String query) async {
    return _contacts.where((c) => c.vaultId == vaultId && c.encryptedName.contains(query)).toList();
  }

  @override
  Future<int> getContactCount(String vaultId) async {
    return _contacts.where((c) => c.vaultId == vaultId).length;
  }

  @override
  Future<List<Contact>> getAllContacts() async => _contacts;
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

void main() {
  late CreateContactUseCase createContactUseCase;
  late UpdateContactUseCase updateContactUseCase;
  late DeleteContactUseCase deleteContactUseCase;
  late GetContactsUseCase getContactsUseCase;
  late GetContactByIdUseCase getContactByIdUseCase;
  late SearchContactsUseCase searchContactsUseCase;

  late MockContactRepository mockContactRepository;
  late MockCryptoService mockCryptoService;
  late MockVaultService mockVaultService;

  setUp(() {
    mockContactRepository = MockContactRepository();
    mockCryptoService = MockCryptoService();
    mockVaultService = MockVaultService();

    createContactUseCase = CreateContactUseCase(
      mockContactRepository,
      mockCryptoService,
      mockVaultService,
    );
    updateContactUseCase = UpdateContactUseCase(mockContactRepository);
    deleteContactUseCase = DeleteContactUseCase(mockContactRepository);
    getContactsUseCase = GetContactsUseCase(
      mockContactRepository,
      mockVaultService,
    );
    getContactByIdUseCase = GetContactByIdUseCase(mockContactRepository);
    searchContactsUseCase = SearchContactsUseCase(
      mockContactRepository,
      mockVaultService,
    );
  });

  group('ContactUseCases', () {
    test('should create contact', () async {
      final contact = await createContactUseCase.execute(
        name: 'John Doe',
        phone: '+1234567890',
      );

      expect(contact, isNotNull);
      expect(contact.id, greaterThan(0));
    });

    test('should create contact with optional fields', () async {
      final contact = await createContactUseCase.execute(
        name: 'Jane Doe',
        phone: '+0987654321',
        email: 'jane@example.com',
        address: '123 Main St',
        notes: 'Work contact',
      );

      expect(contact, isNotNull);
      expect(contact.id, greaterThan(0));
    });

    test('should update contact', () async {
      final contact = await createContactUseCase.execute(
        name: 'Test Contact',
        phone: '+1111111111',
      );

      final updated = await updateContactUseCase.execute(contact);
      expect(updated, isTrue);
    });

    test('should delete contact', () async {
      final contact = await createContactUseCase.execute(
        name: 'Test Contact',
        phone: '+1111111111',
      );

      final deleted = await deleteContactUseCase.execute(contact.id);
      expect(deleted, 1);
    });

    test('should get all contacts', () async {
      await createContactUseCase.execute(
        name: 'Contact 1',
        phone: '+1111111111',
      );
      await createContactUseCase.execute(
        name: 'Contact 2',
        phone: '+2222222222',
      );

      final contacts = await getContactsUseCase.execute();
      expect(contacts.length, 2);
    });

    test('should get contact by ID', () async {
      final contact = await createContactUseCase.execute(
        name: 'Test Contact',
        phone: '+1111111111',
      );

      final found = await getContactByIdUseCase.execute(contact.id);
      expect(found, isNotNull);
      expect(found?.id, equals(contact.id));
    });

    test('should search contacts', () async {
      await createContactUseCase.execute(
        name: 'John Doe',
        phone: '+1234567890',
      );
      await createContactUseCase.execute(
        name: 'Jane Smith',
        phone: '+0987654321',
      );

      final results = await searchContactsUseCase.execute('John');
      expect(results.length, greaterThan(0));
    });

    test('should handle empty search results', () async {
      await createContactUseCase.execute(
        name: 'John Doe',
        phone: '+1234567890',
      );

      final results = await searchContactsUseCase.execute('NonExistent');
      expect(results.length, 0);
    });
  });
}
