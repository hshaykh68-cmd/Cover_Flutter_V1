class Password {
  final int id;
  final String vaultId;
  final String encryptedTitle;
  final String encryptedUsername;
  final String encryptedPassword;
  final String? encryptedUrl;
  final String? encryptedNotes;
  final String? encryptedFolder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Password({
    required this.id,
    required this.vaultId,
    required this.encryptedTitle,
    required this.encryptedUsername,
    required this.encryptedPassword,
    this.encryptedUrl,
    this.encryptedNotes,
    this.encryptedFolder,
    required this.createdAt,
    required this.updatedAt,
  });

  Password copyWith({
    int? id,
    String? vaultId,
    String? encryptedTitle,
    String? encryptedUsername,
    String? encryptedPassword,
    String? encryptedUrl,
    String? encryptedNotes,
    String? encryptedFolder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Password(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      encryptedTitle: encryptedTitle ?? this.encryptedTitle,
      encryptedUsername: encryptedUsername ?? this.encryptedUsername,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      encryptedUrl: encryptedUrl ?? this.encryptedUrl,
      encryptedNotes: encryptedNotes ?? this.encryptedNotes,
      encryptedFolder: encryptedFolder ?? this.encryptedFolder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
