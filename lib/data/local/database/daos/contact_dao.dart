import 'package:cover/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

part 'contact_dao.g.dart';

/// Data Access Object for Contact operations
@DriftAccessor(tables: [Contacts])
class ContactDao extends DatabaseAccessor<AppDatabase> with _$ContactDaoMixin {
  ContactDao(AppDatabase db) : super(db);

  /// Get contact by ID
  Future<Contact?> getContactById(int id) {
    return (select(contacts)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get all contacts for a vault
  Future<List<Contact>> getContactsByVault(String vaultId) {
    return (select(contacts)..where((tbl) => tbl.vaultId.equals(vaultId))).get();
  }

  /// Get contacts by folder for a vault
  Future<List<Contact>> getContactsByFolder(String vaultId, String encryptedFolder) {
    return (select(contacts)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedFolder.equals(encryptedFolder)))
        .get();
  }

  /// Create a new contact
  Future<Contact> createContact(ContactsCompanion contact) async {
    return await into(contacts).insert(contact);
  }

  /// Update a contact
  Future<bool> updateContact(Contact contact) {
    return update(contacts).replace(contact);
  }

  /// Delete a contact
  Future<int> deleteContact(int id) {
    return (delete(contacts)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete all contacts for a vault
  Future<int> deleteContactsByVault(String vaultId) {
    return (delete(contacts)..where((tbl) => tbl.vaultId.equals(vaultId))).go();
  }

  /// Get contact count for a vault
  Future<int> getContactCount(String vaultId) {
    return (select(contacts)..where((tbl) => tbl.vaultId.equals(vaultId)))
        .get()
        .then((list) => list.length);
  }

  /// Search contacts by encrypted name
  Future<List<Contact>> searchContacts(String vaultId, String query) {
    return (select(contacts)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedName.contains(query)))
        .get();
  }
}
