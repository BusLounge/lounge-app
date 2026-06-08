/// Package type tiers for special packages
enum SpecialPackageType {
  platinum,
  gold,
  standard;

  String get displayName {
    switch (this) {
      case SpecialPackageType.platinum:
        return 'Platinum';
      case SpecialPackageType.gold:
        return 'Gold';
      case SpecialPackageType.standard:
        return 'Standard';
    }
  }

  static SpecialPackageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'platinum':
        return SpecialPackageType.platinum;
      case 'gold':
        return SpecialPackageType.gold;
      case 'standard':
        return SpecialPackageType.standard;
      default:
        return SpecialPackageType.standard;
    }
  }
}

/// Domain entity representing a lounge special package
class LoungeSpecialPackage {
  final String id;
  final String loungeId;
  final String packageName;
  final String? imageUrl;
  final SpecialPackageType packageType;
  final String description;
  final String price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoungeSpecialPackage({
    required this.id,
    required this.loungeId,
    required this.packageName,
    this.imageUrl,
    required this.packageType,
    required this.description,
    required this.price,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  LoungeSpecialPackage copyWith({
    String? id,
    String? loungeId,
    String? packageName,
    String? imageUrl,
    SpecialPackageType? packageType,
    String? description,
    String? price,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoungeSpecialPackage(
      id: id ?? this.id,
      loungeId: loungeId ?? this.loungeId,
      packageName: packageName ?? this.packageName,
      imageUrl: imageUrl ?? this.imageUrl,
      packageType: packageType ?? this.packageType,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
