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

/// Transport mode options
enum TransportMode {
  threeWheeler,
  van,
  car;

  String get apiValue {
    switch (this) {
      case TransportMode.threeWheeler:
        return 'three-wheeler';
      case TransportMode.van:
        return 'van';
      case TransportMode.car:
        return 'car';
    }
  }

  String get displayName {
    switch (this) {
      case TransportMode.threeWheeler:
        return 'Three-Wheeler';
      case TransportMode.van:
        return 'Van';
      case TransportMode.car:
        return 'Car';
    }
  }

  static TransportMode? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'three-wheeler':
        return TransportMode.threeWheeler;
      case 'van':
        return TransportMode.van;
      case 'car':
        return TransportMode.car;
      default:
        return null;
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

  // Extended fields
  final int? pax;
  final bool? transportStatus;
  final TransportMode? transportMode;
  final bool? mealStatus;
  final bool? breakfastStatus;
  final List<String>? breakfastType;
  final bool? lunchStatus;
  final List<String>? lunchType;
  final bool? eveningSnackStatus;
  final List<String>? eveningSnackType;
  final bool? dinnerStatus;
  final List<String>? dinnerType;
  final List<String>? places;

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
    // Extended
    this.pax,
    this.transportStatus,
    this.transportMode,
    this.mealStatus,
    this.breakfastStatus,
    this.breakfastType,
    this.lunchStatus,
    this.lunchType,
    this.eveningSnackStatus,
    this.eveningSnackType,
    this.dinnerStatus,
    this.dinnerType,
    this.places,
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
    int? pax,
    bool? transportStatus,
    TransportMode? transportMode,
    bool? mealStatus,
    bool? breakfastStatus,
    List<String>? breakfastType,
    bool? lunchStatus,
    List<String>? lunchType,
    bool? eveningSnackStatus,
    List<String>? eveningSnackType,
    bool? dinnerStatus,
    List<String>? dinnerType,
    List<String>? places,
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
      pax: pax ?? this.pax,
      transportStatus: transportStatus ?? this.transportStatus,
      transportMode: transportMode ?? this.transportMode,
      mealStatus: mealStatus ?? this.mealStatus,
      breakfastStatus: breakfastStatus ?? this.breakfastStatus,
      breakfastType: breakfastType ?? this.breakfastType,
      lunchStatus: lunchStatus ?? this.lunchStatus,
      lunchType: lunchType ?? this.lunchType,
      eveningSnackStatus: eveningSnackStatus ?? this.eveningSnackStatus,
      eveningSnackType: eveningSnackType ?? this.eveningSnackType,
      dinnerStatus: dinnerStatus ?? this.dinnerStatus,
      dinnerType: dinnerType ?? this.dinnerType,
      places: places ?? this.places,
    );
  }
}
