import '../repository/note_repository.dart';
import '../model/note.dart';

/// Use case for adding a note
class AddNoteUseCase {
  final NoteRepository _repository;

  AddNoteUseCase(this._repository);

  Future<int> call(Note note) {
    return _repository.addNote(note);
  }
}

/// Use case for retrieving all notes for a vault
class GetNotesUseCase {
  final NoteRepository _repository;

  GetNotesUseCase(this._repository);

  Future<List<Note>> call(String vaultId) {
    return _repository.getNotes(vaultId);
  }
}

/// Use case for retrieving a note by ID
class GetNoteByIdUseCase {
  final NoteRepository _repository;

  GetNoteByIdUseCase(this._repository);

  Future<Note?> call(int id) {
    return _repository.getNoteById(id);
  }
}

/// Use case for updating a note
class UpdateNoteUseCase {
  final NoteRepository _repository;

  UpdateNoteUseCase(this._repository);

  Future<void> call(Note note) {
    return _repository.updateNote(note);
  }
}

/// Use case for deleting a note
class DeleteNoteUseCase {
  final NoteRepository _repository;

  DeleteNoteUseCase(this._repository);

  Future<void> call(int id) {
    return _repository.deleteNote(id);
  }
}

/// Use case for searching notes by encrypted content
class SearchNotesUseCase {
  final NoteRepository _repository;

  SearchNotesUseCase(this._repository);

  Future<List<Note>> call(String vaultId, String query) {
    return _repository.searchNotes(vaultId, query);
  }
}
