class MediaItem {
  final int id;
  final String vaultId;
  final String type;
  final String encryptedFilePath;
  final String? encryptedThumbnailPath;
  final String originalFileName;
  final int fileSize;
  final String mimeType;
  final int? width;
  final int? height;
  final int? duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaItem({
    required this.id,
    required this.vaultId,
    required this.type,
    required this.encryptedFilePath,
    this.encryptedThumbnailPath,
    required this.originalFileName,
    required this.fileSize,
    required this.mimeType,
    this.width,
    this.height,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  MediaItem copyWith({
    int? id,
    String? vaultId,
    String? type,
    String? encryptedFilePath,
    String? encryptedThumbnailPath,
    String? originalFileName,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      type: type ?? this.type,
      encryptedFilePath: encryptedFilePath ?? this.encryptedFilePath,
      encryptedThumbnailPath: encryptedThumbnailPath ?? this.encryptedThumbnailPath,
      originalFileName: originalFileName ?? this.originalFileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
