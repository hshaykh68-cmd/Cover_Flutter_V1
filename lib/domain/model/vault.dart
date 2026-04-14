import 'vault_type.dart';

class Vault {
  final String id;
  final VaultType type;
  final String? name;
  final bool isActive;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vault({
    required this.id,
    required this.type,
    this.name,
    this.isActive = true,
    this.itemCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Vault copyWith({
    String? id,
    VaultType? type,
    String? name,
    bool? isActive,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vault(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
