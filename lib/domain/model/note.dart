class Note {
  final int id;
  final String vaultId;
  final String encryptedTitle;
  final String encryptedContent;
  final String? encryptedFolder;
  final String? encryptedTags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.vaultId,
    required this.encryptedTitle,
    required this.encryptedContent,
    this.encryptedFolder,
    this.encryptedTags,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    int? id,
    String? vaultId,
    String? encryptedTitle,
    String? encryptedContent,
    String? encryptedFolder,
    String? encryptedTags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      encryptedTitle: encryptedTitle ?? this.encryptedTitle,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      encryptedFolder: encryptedFolder ?? this.encryptedFolder,
      encryptedTags: encryptedTags ?? this.encryptedTags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
