import 'package:cover/data/local/database/daos/contact_dao.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/contact_repository.dart';
import 'package:cover/core/utils/logger.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactDao _contactDao;

  ContactRepositoryImpl(this._contactDao);

  @override
  Future<Contact?> getContactById(int id) async {
    try {
      return await _contactDao.getContactById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get contact by id: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Contact>> getContactsByVault(String vaultId) async {
    try {
      return await _contactDao.getContactsByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get contacts for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Contact>> getContactsByFolder(String vaultId, String encryptedFolder) async {
    try {
      return await _contactDao.getContactsByFolder(vaultId, encryptedFolder);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get contacts by folder', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Contact> createContact(ContactsCompanion contact) async {
    try {
      return await _contactDao.createContact(contact);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create contact', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateContact(Contact contact) async {
    try {
      return await _contactDao.updateContact(contact);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update contact', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteContact(int id) async {
    try {
      return await _contactDao.deleteContact(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete contact: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteContactsByVault(String vaultId) async {
    try {
      return await _contactDao.deleteContactsByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete contacts for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getContactCount(String vaultId) async {
    try {
      return await _contactDao.getContactCount(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get contact count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Contact>> searchContacts(String vaultId, String query) async {
    try {
      return await _contactDao.searchContacts(vaultId, query);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search contacts', e, stackTrace);
      rethrow;
    }
  }
}
