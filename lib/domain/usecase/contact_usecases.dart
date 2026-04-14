import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/contact_repository.dart';
import 'package:cover/core/crypto/crypto_service.dart';
import 'package:cover/core/vault/vault_service.dart';
import 'package:cover/core/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Use case for creating a contact entry
class CreateContactUseCase {
  final ContactRepository _contactRepository;
  final CryptoService _cryptoService;
  final VaultService _vaultService;

  CreateContactUseCase(
    this._contactRepository,
    this._cryptoService,
    this._vaultService,
  );

  Future<Contact> execute({
    required String name,
    required String phone,
    String? email,
    String? address,
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
      final encryptionKey = _cryptoService.generateRandomKey(length: 32);

      // Encrypt sensitive data
      final encryptedName = await _cryptoService.encryptString(name, encryptionKey);
      final encryptedPhone = await _cryptoService.encryptString(phone, encryptionKey);

      String? encryptedEmail;
      if (email != null) {
        encryptedEmail = await _cryptoService.encryptString(email, encryptionKey);
      }

      String? encryptedAddress;
      if (address != null) {
        encryptedAddress = await _cryptoService.encryptString(address, encryptionKey);
      }

      String? encryptedNotes;
      if (notes != null) {
        encryptedNotes = await _cryptoService.encryptString(notes, encryptionKey);
      }

      String? encryptedFolder;
      if (folder != null) {
        encryptedFolder = await _cryptoService.encryptString(folder, encryptionKey);
      }

      final contact = await _contactRepository.createContact(
        ContactsCompanion(
          vaultId: vaultId,
          encryptedName: encryptedName.base64,
          encryptedPhone: encryptedPhone.base64,
          encryptedEmail: Value(encryptedEmail?.base64),
          encryptedAddress: Value(encryptedAddress?.base64),
          encryptedNotes: Value(encryptedNotes?.base64),
          encryptedFolder: Value(encryptedFolder?.base64),
        ),
      );

      AppLogger.info('Created contact entry: ${contact.id}');
      return contact;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create contact', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for updating a contact entry
class UpdateContactUseCase {
  final ContactRepository _contactRepository;

  UpdateContactUseCase(this._contactRepository);

  Future<bool> execute(Contact contact) async {
    try {
      final success = await _contactRepository.updateContact(contact);
      AppLogger.info('Updated contact entry: ${contact.id}');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update contact', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for deleting a contact entry
class DeleteContactUseCase {
  final ContactRepository _contactRepository;

  DeleteContactUseCase(this._contactRepository);

  Future<int> execute(int id) async {
    try {
      final result = await _contactRepository.deleteContact(id);
      AppLogger.info('Deleted contact entry: $id');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete contact', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for getting all contacts for current vault
class GetContactsUseCase {
  final ContactRepository _contactRepository;
  final VaultService _vaultService;

  GetContactsUseCase(
    this._contactRepository,
    this._vaultService,
  );

  Future<List<Contact>> execute() async {
    try {
      final vaultId = await _vaultService.getVaultId(VaultNamespace.real);
      if (vaultId == null) {
        return [];
      }

      final contacts = await _contactRepository.getContactsByVault(vaultId);
      AppLogger.debug('Retrieved ${contacts.length} contacts');
      return contacts;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get contacts', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for getting a contact by ID
class GetContactByIdUseCase {
  final ContactRepository _contactRepository;

  GetContactByIdUseCase(this._contactRepository);

  Future<Contact?> execute(int id) async {
    try {
      final contact = await _contactRepository.getContactById(id);
      return contact;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get contact by id: $id', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for initiating a phone call to a contact
class CallContactUseCase {
  final CryptoService _cryptoService;

  CallContactUseCase(this._cryptoService);

  Future<bool> execute(String encryptedPhoneBase64, Uint8List encryptionKey) async {
    try {
      // Decrypt phone number
      final encryptedData = EncryptedData(
        base64: encryptedPhoneBase64,
        nonce: Uint8List(12), // Placeholder - in production, store nonce with encrypted data
      );
      final phone = await _cryptoService.decryptString(encryptedData, encryptionKey);

      // Launch phone call
      final uri = Uri.parse('tel:$phone');
      final launched = await launchUrl(uri);

      if (launched) {
        AppLogger.info('Initiated phone call to: $phone');
      } else {
        AppLogger.warning('Could not launch phone call');
      }

      return launched;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initiate phone call', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for sending SMS to a contact
class SmsContactUseCase {
  final CryptoService _cryptoService;

  SmsContactUseCase(this._cryptoService);

  Future<bool> execute(String encryptedPhoneBase64, Uint8List encryptionKey, {String? message}) async {
    try {
      // Decrypt phone number
      final encryptedData = EncryptedData(
        base64: encryptedPhoneBase64,
        nonce: Uint8List(12), // Placeholder
      );
      final phone = await _cryptoService.decryptString(encryptedData, encryptionKey);

      // Launch SMS
      final uri = Uri.parse('sms:$phone${message != null ? "?body=${Uri.encodeComponent(message)}" : ""}');
      final launched = await launchUrl(uri);

      if (launched) {
        AppLogger.info('Initiated SMS to: $phone');
      } else {
        AppLogger.warning('Could not launch SMS');
      }

      return launched;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initiate SMS', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for sending email to a contact
class EmailContactUseCase {
  final CryptoService _cryptoService;

  EmailContactUseCase(this._cryptoService);

  Future<bool> execute(String encryptedEmailBase64, Uint8List encryptionKey, {String? subject, String? body}) async {
    try {
      // Decrypt email
      final encryptedData = EncryptedData(
        base64: encryptedEmailBase64,
        nonce: Uint8List(12), // Placeholder
      );
      final email = await _cryptoService.decryptString(encryptedData, encryptionKey);

      // Launch email
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        query: _buildQuery(subject: subject, body: body),
      );
      final launched = await launchUrl(uri);

      if (launched) {
        AppLogger.info('Initiated email to: $email');
      } else {
        AppLogger.warning('Could not launch email');
      }

      return launched;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initiate email', e, stackTrace);
      rethrow;
    }
  }

  String? _buildQuery({String? subject, String? body}) {
    final params = <String, String>{};
    if (subject != null) params['subject'] = subject;
    if (body != null) params['body'] = body;
    if (params.isEmpty) return null;
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

/// Use case for searching contacts
class SearchContactsUseCase {
  final ContactRepository _contactRepository;
  final VaultService _vaultService;

  SearchContactsUseCase(
    this._contactRepository,
    this._vaultService,
  );

  Future<List<Contact>> execute(String query) async {
    try {
      final vaultId = await _vaultService.getVaultId(VaultNamespace.real);
      if (vaultId == null) {
        return [];
      }

      final contacts = await _contactRepository.searchContacts(vaultId, query);
      AppLogger.debug('Found ${contacts.length} contacts matching "$query"');
      return contacts;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search contacts', e, stackTrace);
      rethrow;
    }
  }
}

/// Use case for getting contacts by folder
class GetContactsByFolderUseCase {
  final ContactRepository _contactRepository;
  final VaultService _vaultService;
  final CryptoService _cryptoService;

  GetContactsByFolderUseCase(
    this._contactRepository,
    this._vaultService,
    this._cryptoService,
  );

  Future<List<Contact>> execute(String folder) async {
    try {
      final vaultId = await _vaultService.getVaultId(VaultNamespace.real);
      if (vaultId == null) {
        return [];
      }

      // Encrypt folder name for search
      final encryptionKey = _cryptoService.generateRandomKey(length: 32);
      final encryptedFolder = await _cryptoService.encryptString(folder, encryptionKey);

      final contacts = await _contactRepository.getContactsByFolder(
        vaultId,
        encryptedFolder.base64,
      );

      AppLogger.debug('Retrieved ${contacts.length} contacts in folder: $folder');
      return contacts;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get contacts by folder', e, stackTrace);
      rethrow;
    }
  }
}
