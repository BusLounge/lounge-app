import 'package:equatable/equatable.dart';

/// Product stock status enum
enum ProductStockStatus {
  inStock,
  lowStock,
  outOfStock,
  madeToOrder;

  String get value {
    switch (this) {
      case ProductStockStatus.inStock:
        return 'in_stock';
      case ProductStockStatus.lowStock:
        return 'low_stock';
      case ProductStockStatus.outOfStock:
        return 'out_of_stock';
      case ProductStockStatus.madeToOrder:
        return 'made_to_order';
    }
  }

  static ProductStockStatus fromString(String? value) {
    switch (value) {
      case 'low_stock':
        return ProductStockStatus.lowStock;
      case 'out_of_stock':
        return ProductStockStatus.outOfStock;
      case 'made_to_order':
        return ProductStockStatus.madeToOrder;
      default:
        return ProductStockStatus.inStock;
    }
  }

  String get displayName {
    switch (this) {
      case ProductStockStatus.inStock:
        return 'In Stock';
      case ProductStockStatus.lowStock:
        return 'Low Stock';
      case ProductStockStatus.outOfStock:
        return 'Out of Stock';
      case ProductStockStatus.madeToOrder:
        return 'Made to Order';
    }
  }
}

/// Product type enum
enum ProductType {
  product,
  service,
  other,
  combo;

  String get value {
    switch (this) {
      case ProductType.product:
        return 'product';
      case ProductType.service:
        return 'service';
      case ProductType.other:
        return 'other';
      case ProductType.combo:
        return 'combo';
    }
  }

  static ProductType fromString(String? value) {
    switch (value) {
      case 'service':
        return ProductType.service;
      case 'other':
        return ProductType.other;
      case 'combo':
        return ProductType.combo;
      default:
        return ProductType.product;
    }
  }

  String get displayName {
    switch (this) {
      case ProductType.product:
        return 'Product';
      case ProductType.service:
        return 'Service';
      case ProductType.other:
        return 'Other';
      case ProductType.combo:
        return 'Combo/Package';
    }
  }
}

/// Entity representing a lounge product or service
class LoungeProduct extends Equatable {
  final String id;
  final String loungeId;
  final String categoryId;
  final String? categoryName; // Populated from JOIN
  final String name;
  final String? description;
  final ProductType productType;
  final String price; // Stored as string for precision
  final String priceRateType;
  final String? discountedPrice;
  final String? imageUrl;
  final String? thumbnailUrl;
  final ProductStockStatus stockStatus;
  final int? stockQuantity;
  final bool isAvailable;
  final bool isPreOrderable;
  final String? availableFrom; // Time string HH:MM
  final String? availableUntil; // Time string HH:MM
  final List<String>? availableDays; // ['mon', 'tue', ...]
  final int? serviceDurationMinutes;
  final bool isVegetarian;
  final bool isVegan;
  final bool isHalal;
  final List<String>? allergens;
  final int? calories;
  final int displayOrder;
  final bool isFeatured;
  final List<String>? tags;
  final double? averageRating;
  final int? totalReviews;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoungeProduct({
    required this.id,
    required this.loungeId,
    required this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    this.productType = ProductType.product,
    required this.price,
    this.priceRateType = 'fixed_rate',
    this.discountedPrice,
    this.imageUrl,
    this.thumbnailUrl,
    this.stockStatus = ProductStockStatus.inStock,
    this.stockQuantity,
    this.isAvailable = true,
    this.isPreOrderable = false,
    this.availableFrom,
    this.availableUntil,
    this.availableDays,
    this.serviceDurationMinutes,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isHalal = false,
    this.allergens,
    this.calories,
    this.displayOrder = 0,
    this.isFeatured = false,
    this.tags,
    this.averageRating,
    this.totalReviews,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        loungeId,
        categoryId,
        categoryName,
        name,
        description,
        productType,
        price,
        priceRateType,
        discountedPrice,
        imageUrl,
        thumbnailUrl,
        stockStatus,
        stockQuantity,
        isAvailable,
        isPreOrderable,
        availableFrom,
        availableUntil,
        availableDays,
        serviceDurationMinutes,
        isVegetarian,
        isVegan,
        isHalal,
        allergens,
        calories,
        displayOrder,
        isFeatured,
        tags,
        averageRating,
        totalReviews,
        isActive,
        createdAt,
        updatedAt,
      ];

  /// Get display price (discounted if available)
  String get displayPrice => discountedPrice ?? price;

  /// Check if product has a discount
  bool get hasDiscount =>
      discountedPrice != null && discountedPrice!.isNotEmpty;

  /// Get price as double for calculations
  double get priceAsDouble => double.tryParse(price) ?? 0.0;

  /// Get discounted price as double
  double? get discountedPriceAsDouble =>
      discountedPrice != null ? double.tryParse(discountedPrice!) : null;

  /// Calculate discount percentage
  int? get discountPercentage {
    if (!hasDiscount) return null;
    final original = priceAsDouble;
    final discounted = discountedPriceAsDouble;
    if (original <= 0 || discounted == null) return null;
    return (((original - discounted) / original) * 100).round();
  }

  /// Check if product is a service
  bool get isService => productType == ProductType.service;

  /// Check if product is available now (based on time restrictions)
  bool get isAvailableNow {
    if (!isAvailable) return false;
    if (availableFrom == null && availableUntil == null) return true;

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (availableFrom != null && currentTime.compareTo(availableFrom!) < 0) {
      return false;
    }
    if (availableUntil != null && currentTime.compareTo(availableUntil!) > 0) {
      return false;
    }
    return true;
  }

  /// Get dietary flags as list
  List<String> get dietaryFlags {
    final flags = <String>[];
    if (isVegetarian) flags.add('Vegetarian');
    if (isVegan) flags.add('Vegan');
    if (isHalal) flags.add('Halal');
    return flags;
  }

  LoungeProduct copyWith({
    String? id,
    String? loungeId,
    String? categoryId,
    String? categoryName,
    String? name,
    String? description,
    ProductType? productType,
    String? price,
    String? priceRateType,
    String? discountedPrice,
    String? imageUrl,
    String? thumbnailUrl,
    ProductStockStatus? stockStatus,
    int? stockQuantity,
    bool? isAvailable,
    bool? isPreOrderable,
    String? availableFrom,
    String? availableUntil,
    List<String>? availableDays,
    int? serviceDurationMinutes,
    bool? isVegetarian,
    bool? isVegan,
    bool? isHalal,
    List<String>? allergens,
    int? calories,
    int? displayOrder,
    bool? isFeatured,
    List<String>? tags,
    double? averageRating,
    int? totalReviews,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoungeProduct(
      id: id ?? this.id,
      loungeId: loungeId ?? this.loungeId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      description: description ?? this.description,
      productType: productType ?? this.productType,
      price: price ?? this.price,
      priceRateType: priceRateType ?? this.priceRateType,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      stockStatus: stockStatus ?? this.stockStatus,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      isPreOrderable: isPreOrderable ?? this.isPreOrderable,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      availableDays: availableDays ?? this.availableDays,
      serviceDurationMinutes:
          serviceDurationMinutes ?? this.serviceDurationMinutes,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isHalal: isHalal ?? this.isHalal,
      allergens: allergens ?? this.allergens,
      calories: calories ?? this.calories,
      displayOrder: displayOrder ?? this.displayOrder,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
