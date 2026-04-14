class User {
  final int id;
  final String vaultId;
  final String pinHash;
  final String pinSalt;
  final bool biometricEnabled;
  final bool autoLockEnabled;
  final int autoLockTimeout;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.vaultId,
    required this.pinHash,
    required this.pinSalt,
    this.biometricEnabled = false,
    this.autoLockEnabled = true,
    this.autoLockTimeout = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    int? id,
    String? vaultId,
    String? pinHash,
    String? pinSalt,
    bool? biometricEnabled,
    bool? autoLockEnabled,
    int? autoLockTimeout,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
