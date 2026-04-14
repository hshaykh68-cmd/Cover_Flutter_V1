import 'package:cover/data/local/database/tables.dart';

abstract class ContactRepository {
  Future<Contact?> getContactById(int id);
  Future<List<Contact>> getContactsByVault(String vaultId);
  Future<List<Contact>> getContactsByFolder(String vaultId, String encryptedFolder);
  Future<Contact> createContact(ContactsCompanion contact);
  Future<bool> updateContact(Contact contact);
  Future<int> deleteContact(int id);
  Future<int> deleteContactsByVault(String vaultId);
  Future<int> getContactCount(String vaultId);
  Future<List<Contact>> searchContacts(String vaultId, String query);
}
