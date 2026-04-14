import 'package:cover/data/local/database/tables.dart';

abstract class NoteRepository {
  Future<Note?> getNoteById(int id);
  Future<List<Note>> getNotesByVault(String vaultId);
  Future<List<Note>> getNotesByFolder(String vaultId, String encryptedFolder);
  Future<Note> createNote(NotesCompanion note);
  Future<bool> updateNote(Note note);
  Future<int> deleteNote(int id);
  Future<int> deleteNotesByVault(String vaultId);
  Future<int> getNoteCount(String vaultId);
  Future<List<Note>> searchNotes(String vaultId, String query);
}
