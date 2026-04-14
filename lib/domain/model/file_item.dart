class FileItem {
  final int id;
  final String vaultId;
  final String encryptedFilePath;
  final String originalFileName;
  final int fileSize;
  final String mimeType;
  final String? encryptedFolder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FileItem({
    required this.id,
    required this.vaultId,
    required this.encryptedFilePath,
    required this.originalFileName,
    required this.fileSize,
    required this.mimeType,
    this.encryptedFolder,
    required this.createdAt,
    required this.updatedAt,
  });

  FileItem copyWith({
    int? id,
    String? vaultId,
    String? encryptedFilePath,
    String? originalFileName,
    int? fileSize,
    String? mimeType,
    String? encryptedFolder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FileItem(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      encryptedFilePath: encryptedFilePath ?? this.encryptedFilePath,
      originalFileName: originalFileName ?? this.originalFileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      encryptedFolder: encryptedFolder ?? this.encryptedFolder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
