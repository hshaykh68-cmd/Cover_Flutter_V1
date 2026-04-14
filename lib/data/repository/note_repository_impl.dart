import 'package:cover/data/local/database/daos/note_dao.dart';
import 'package:cover/data/local/database/tables.dart';
import 'package:cover/domain/repository/note_repository.dart';
import 'package:cover/core/utils/logger.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteDao _noteDao;

  NoteRepositoryImpl(this._noteDao);

  @override
  Future<Note?> getNoteById(int id) async {
    try {
      return await _noteDao.getNoteById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get note by id: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Note>> getNotesByVault(String vaultId) async {
    try {
      return await _noteDao.getNotesByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get notes for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Note>> getNotesByFolder(String vaultId, String encryptedFolder) async {
    try {
      return await _noteDao.getNotesByFolder(vaultId, encryptedFolder);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get notes by folder', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Note> createNote(NotesCompanion note) async {
    try {
      return await _noteDao.createNote(note);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create note', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> updateNote(Note note) async {
    try {
      return await _noteDao.updateNote(note);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update note', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteNote(int id) async {
    try {
      return await _noteDao.deleteNote(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete note: $id', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> deleteNotesByVault(String vaultId) async {
    try {
      return await _noteDao.deleteNotesByVault(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete notes for vault: $vaultId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getNoteCount(String vaultId) async {
    try {
      return await _noteDao.getNoteCount(vaultId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get note count', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Note>> searchNotes(String vaultId, String query) async {
    try {
      return await _noteDao.searchNotes(vaultId, query);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search notes', e, stackTrace);
      rethrow;
    }
  }
}
