class IntruderLog {
  final int id;
  final String? vaultId;
  final DateTime timestamp;
  final String eventType;
  final String? encryptedPhotoPath;
  final String? encryptedLocation;
  final String? metadata;

  const IntruderLog({
    required this.id,
    this.vaultId,
    required this.timestamp,
    required this.eventType,
    this.encryptedPhotoPath,
    this.encryptedLocation,
    this.metadata,
  });

  IntruderLog copyWith({
    int? id,
    String? vaultId,
    DateTime? timestamp,
    String? eventType,
    String? encryptedPhotoPath,
    String? encryptedLocation,
    String? metadata,
  }) {
    return IntruderLog(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      encryptedPhotoPath: encryptedPhotoPath ?? this.encryptedPhotoPath,
      encryptedLocation: encryptedLocation ?? this.encryptedLocation,
      metadata: metadata ?? this.metadata,
    );
  }
}
