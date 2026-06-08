import '../../domain/entities/lounge_special_package.dart';

/// Data model for serializing / deserializing LoungeSpecialPackage JSON
class LoungeSpecialPackageModel extends LoungeSpecialPackage {
  const LoungeSpecialPackageModel({
    required super.id,
    required super.loungeId,
    required super.packageName,
    super.imageUrl,
    required super.packageType,
    required super.description,
    required super.price,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LoungeSpecialPackageModel.fromJson(Map<String, dynamic> json) {
    return LoungeSpecialPackageModel(
      id: json['id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      packageName: json['package_name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      packageType: SpecialPackageType.fromString(
        json['package_type']?.toString() ?? 'standard',
      ),
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lounge_id': loungeId,
      'package_name': packageName,
      'image_url': imageUrl,
      'package_type': packageType.name,
      'description': description,
      'price': price,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'package_name': packageName,
      if (imageUrl != null) 'image_url': imageUrl,
      'package_type': packageType.name,
      'description': description,
      'price': price,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (packageName.isNotEmpty) 'package_name': packageName,
      if (imageUrl != null) 'image_url': imageUrl,
      'package_type': packageType.name,
      if (description.isNotEmpty) 'description': description,
      if (price.isNotEmpty) 'price': price,
    };
  }
}
