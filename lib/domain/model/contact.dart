class Contact {
  final int id;
  final String vaultId;
  final String encryptedName;
  final String encryptedPhone;
  final String? encryptedEmail;
  final String? encryptedAddress;
  final String? encryptedNotes;
  final String? encryptedFolder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contact({
    required this.id,
    required this.vaultId,
    required this.encryptedName,
    required this.encryptedPhone,
    this.encryptedEmail,
    this.encryptedAddress,
    this.encryptedNotes,
    this.encryptedFolder,
    required this.createdAt,
    required this.updatedAt,
  });

  Contact copyWith({
    int? id,
    String? vaultId,
    String? encryptedName,
    String? encryptedPhone,
    String? encryptedEmail,
    String? encryptedAddress,
    String? encryptedNotes,
    String? encryptedFolder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      encryptedName: encryptedName ?? this.encryptedName,
      encryptedPhone: encryptedPhone ?? this.encryptedPhone,
      encryptedEmail: encryptedEmail ?? this.encryptedEmail,
      encryptedAddress: encryptedAddress ?? this.encryptedAddress,
      encryptedNotes: encryptedNotes ?? this.encryptedNotes,
      encryptedFolder: encryptedFolder ?? this.encryptedFolder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
