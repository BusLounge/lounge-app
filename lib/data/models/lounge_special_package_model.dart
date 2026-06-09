import '../../domain/entities/lounge_special_package.dart';

/// Helper: safely parse a JSON array field into List<String>
List<String>? _parseStringList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((e) => e?.toString() ?? '').toList();
  }
  return null;
}

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
    // Extended
    super.pax,
    super.transportStatus,
    super.transportMode,
    super.mealStatus,
    super.breakfastStatus,
    super.breakfastType,
    super.lunchStatus,
    super.lunchType,
    super.eveningSnackStatus,
    super.eveningSnackType,
    super.dinnerStatus,
    super.dinnerType,
    super.places,
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
      // Extended
      pax: json['pax'] != null ? (json['pax'] as num).toInt() : null,
      transportStatus: json['transport_status'] as bool?,
      transportMode: TransportMode.fromString(json['transport_mode']?.toString()),
      mealStatus: json['meal_status'] as bool?,
      breakfastStatus: json['breakfast_status'] as bool?,
      breakfastType: _parseStringList(json['breakfast_type']),
      lunchStatus: json['lunch_status'] as bool?,
      lunchType: _parseStringList(json['lunch_type']),
      eveningSnackStatus: json['evening_snack_status'] as bool?,
      eveningSnackType: _parseStringList(json['evening_snack_type']),
      dinnerStatus: json['dinner_status'] as bool?,
      dinnerType: _parseStringList(json['dinner_type']),
      places: _parseStringList(json['places']),
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
      if (pax != null) 'pax': pax,
      if (transportStatus != null) 'transport_status': transportStatus,
      if (transportMode != null) 'transport_mode': transportMode!.apiValue,
      if (mealStatus != null) 'meal_status': mealStatus,
      if (breakfastStatus != null) 'breakfast_status': breakfastStatus,
      if (breakfastType != null) 'breakfast_type': breakfastType,
      if (lunchStatus != null) 'lunch_status': lunchStatus,
      if (lunchType != null) 'lunch_type': lunchType,
      if (eveningSnackStatus != null) 'evening_snack_status': eveningSnackStatus,
      if (eveningSnackType != null) 'evening_snack_type': eveningSnackType,
      if (dinnerStatus != null) 'dinner_status': dinnerStatus,
      if (dinnerType != null) 'dinner_type': dinnerType,
      if (places != null) 'places': places,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'package_name': packageName,
      if (imageUrl != null) 'image_url': imageUrl,
      'package_type': packageType.name,
      'description': description,
      'price': price,
      if (pax != null) 'pax': pax,
      if (transportStatus != null) 'transport_status': transportStatus,
      if (transportMode != null) 'transport_mode': transportMode!.apiValue,
      if (mealStatus != null) 'meal_status': mealStatus,
      if (breakfastStatus != null) 'breakfast_status': breakfastStatus,
      if (breakfastType != null && breakfastType!.isNotEmpty)
        'breakfast_type': breakfastType,
      if (lunchStatus != null) 'lunch_status': lunchStatus,
      if (lunchType != null && lunchType!.isNotEmpty) 'lunch_type': lunchType,
      if (eveningSnackStatus != null) 'evening_snack_status': eveningSnackStatus,
      if (eveningSnackType != null && eveningSnackType!.isNotEmpty)
        'evening_snack_type': eveningSnackType,
      if (dinnerStatus != null) 'dinner_status': dinnerStatus,
      if (dinnerType != null && dinnerType!.isNotEmpty) 'dinner_type': dinnerType,
      if (places != null && places!.isNotEmpty) 'places': places,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (packageName.isNotEmpty) 'package_name': packageName,
      if (imageUrl != null) 'image_url': imageUrl,
      'package_type': packageType.name,
      if (description.isNotEmpty) 'description': description,
      if (price.isNotEmpty) 'price': price,
      if (pax != null) 'pax': pax,
      if (transportStatus != null) 'transport_status': transportStatus,
      if (transportMode != null) 'transport_mode': transportMode!.apiValue,
      if (mealStatus != null) 'meal_status': mealStatus,
      if (breakfastStatus != null) 'breakfast_status': breakfastStatus,
      if (breakfastType != null) 'breakfast_type': breakfastType,
      if (lunchStatus != null) 'lunch_status': lunchStatus,
      if (lunchType != null) 'lunch_type': lunchType,
      if (eveningSnackStatus != null) 'evening_snack_status': eveningSnackStatus,
      if (eveningSnackType != null) 'evening_snack_type': eveningSnackType,
      if (dinnerStatus != null) 'dinner_status': dinnerStatus,
      if (dinnerType != null) 'dinner_type': dinnerType,
      if (places != null) 'places': places,
    };
  }
}
