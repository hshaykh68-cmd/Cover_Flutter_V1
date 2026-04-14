import 'package:cover/data/local/database/app_database.dart';
import 'package:drift/drift.dart';

part 'note_dao.g.dart';

/// Data Access Object for Note operations
@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(AppDatabase db) : super(db);

  /// Get note by ID
  Future<Note?> getNoteById(int id) {
    return (select(notes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get all notes for a vault
  Future<List<Note>> getNotesByVault(String vaultId) {
    return (select(notes)..where((tbl) => tbl.vaultId.equals(vaultId))).get();
  }

  /// Get notes by folder for a vault
  Future<List<Note>> getNotesByFolder(String vaultId, String encryptedFolder) {
    return (select(notes)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedFolder.equals(encryptedFolder)))
        .get();
  }

  /// Create a new note
  Future<Note> createNote(NotesCompanion note) async {
    return await into(notes).insert(note);
  }

  /// Update a note
  Future<bool> updateNote(Note note) {
    return update(notes).replace(note);
  }

  /// Delete a note
  Future<int> deleteNote(int id) {
    return (delete(notes)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete all notes for a vault
  Future<int> deleteNotesByVault(String vaultId) {
    return (delete(notes)..where((tbl) => tbl.vaultId.equals(vaultId))).go();
  }

  /// Get note count for a vault
  Future<int> getNoteCount(String vaultId) {
    return (select(notes)..where((tbl) => tbl.vaultId.equals(vaultId)))
        .get()
        .then((list) => list.length);
  }

  /// Search notes by encrypted title
  Future<List<Note>> searchNotes(String vaultId, String query) {
    return (select(notes)
          ..where((tbl) =>
              tbl.vaultId.equals(vaultId) & tbl.encryptedTitle.contains(query)))
        .get();
  }
}
