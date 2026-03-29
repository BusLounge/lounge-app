import '../../domain/entities/lounge_product.dart';

/// Model for lounge product data from API
class LoungeProductModel extends LoungeProduct {
  const LoungeProductModel({
    required super.id,
    required super.loungeId,
    required super.categoryId,
    super.categoryName,
    required super.name,
    super.description,
    super.productType,
    required super.price,
    super.priceRateType,
    super.discountedPrice,
    super.imageUrl,
    super.thumbnailUrl,
    super.stockStatus,
    super.stockQuantity,
    super.isAvailable,
    super.isPreOrderable,
    super.availableFrom,
    super.availableUntil,
    super.availableDays,
    super.serviceDurationMinutes,
    super.isVegetarian,
    super.isVegan,
    super.isHalal,
    super.allergens,
    super.calories,
    super.displayOrder,
    super.isFeatured,
    super.tags,
    super.averageRating,
    super.totalReviews,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create model from JSON
  factory LoungeProductModel.fromJson(Map<String, dynamic> json) {
    return LoungeProductModel(
      id: json['id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString(),
      name: json['name']?.toString() ?? 'Unnamed Product',
      description: json['description']?.toString(),
      productType: ProductType.fromString(json['product_type']?.toString()),
      price: json['price']?.toString() ?? '0',
      priceRateType: _normalizePriceRateType(
        json['price_rate_type']?.toString(),
      ),
      discountedPrice: json['discounted_price']?.toString(),
      imageUrl: json['image_url']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      stockStatus: ProductStockStatus.fromString(
        json['stock_status']?.toString(),
      ),
      stockQuantity: json['stock_quantity'] as int?,
      isAvailable: json['is_available'] as bool? ?? true,
      isPreOrderable: json['is_pre_orderable'] as bool? ?? false,
      availableFrom: json['available_from']?.toString(),
      availableUntil: json['available_until']?.toString(),
      availableDays: (json['available_days'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      serviceDurationMinutes: json['service_duration_minutes'] as int?,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isVegan: json['is_vegan'] as bool? ?? false,
      isHalal: json['is_halal'] as bool? ?? false,
      allergens: (json['allergens'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      calories: json['calories'] as int?,
      displayOrder: json['display_order'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      totalReviews: json['total_reviews'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static String _normalizePriceRateType(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'hourly_rate':
      case 'hourly':
        return 'hourly_rate';
      case 'daily_rate':
      case 'daily':
        return 'daily_rate';
      case 'fixed_rate':
      case 'fixed':
      default:
        return 'fixed_rate';
    }
  }

  /// Convert model to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lounge_id': loungeId,
      'category_id': categoryId,
      'name': name,
      if (description != null) 'description': description,
      'product_type': productType.value,
      'price': price,
      'price_rate_type': priceRateType,
      if (discountedPrice != null) 'discounted_price': discountedPrice,
      if (imageUrl != null) 'image_url': imageUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      'stock_status': stockStatus.value,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      'is_available': isAvailable,
      'is_pre_orderable': isPreOrderable,
      if (availableFrom != null) 'available_from': availableFrom,
      if (availableUntil != null) 'available_until': availableUntil,
      if (availableDays != null) 'available_days': availableDays,
      if (serviceDurationMinutes != null)
        'service_duration_minutes': serviceDurationMinutes,
      'is_vegetarian': isVegetarian,
      'is_vegan': isVegan,
      'is_halal': isHalal,
      if (allergens != null) 'allergens': allergens,
      if (calories != null) 'calories': calories,
      'display_order': displayOrder,
      'is_featured': isFeatured,
      if (tags != null) 'tags': tags,
    };
  }

  /// Convert to create request JSON (without id)
  Map<String, dynamic> toCreateJson() {
    return {
      'category_id': categoryId,
      'name': name,
      if (description != null) 'description': description,
      'product_type': productType.value,
      'price': price,
      'price_rate_type': priceRateType,
      if (discountedPrice != null) 'discounted_price': discountedPrice,
      if (imageUrl != null) 'image_url': imageUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      'stock_status': stockStatus.value,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      'is_available': isAvailable,
      'is_pre_orderable': isPreOrderable,
      if (availableFrom != null) 'available_from': availableFrom,
      if (availableUntil != null) 'available_until': availableUntil,
      if (availableDays != null) 'available_days': availableDays,
      if (serviceDurationMinutes != null)
        'service_duration_minutes': serviceDurationMinutes,
      'is_vegetarian': isVegetarian,
      'is_vegan': isVegan,
      'is_halal': isHalal,
      if (allergens != null) 'allergens': allergens,
      if (calories != null) 'calories': calories,
      'display_order': displayOrder,
      'is_featured': isFeatured,
      if (tags != null) 'tags': tags,
    };
  }

  /// Convert entity to model
  factory LoungeProductModel.fromEntity(LoungeProduct entity) {
    return LoungeProductModel(
      id: entity.id,
      loungeId: entity.loungeId,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      name: entity.name,
      description: entity.description,
      productType: entity.productType,
      price: entity.price,
      priceRateType: entity.priceRateType,
      discountedPrice: entity.discountedPrice,
      imageUrl: entity.imageUrl,
      thumbnailUrl: entity.thumbnailUrl,
      stockStatus: entity.stockStatus,
      stockQuantity: entity.stockQuantity,
      isAvailable: entity.isAvailable,
      isPreOrderable: entity.isPreOrderable,
      availableFrom: entity.availableFrom,
      availableUntil: entity.availableUntil,
      availableDays: entity.availableDays,
      serviceDurationMinutes: entity.serviceDurationMinutes,
      isVegetarian: entity.isVegetarian,
      isVegan: entity.isVegan,
      isHalal: entity.isHalal,
      allergens: entity.allergens,
      calories: entity.calories,
      displayOrder: entity.displayOrder,
      isFeatured: entity.isFeatured,
      tags: entity.tags,
      averageRating: entity.averageRating,
      totalReviews: entity.totalReviews,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to entity
  LoungeProduct toEntity() {
    return LoungeProduct(
      id: id,
      loungeId: loungeId,
      categoryId: categoryId,
      categoryName: categoryName,
      name: name,
      description: description,
      productType: productType,
      price: price,
      priceRateType: priceRateType,
      discountedPrice: discountedPrice,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      stockStatus: stockStatus,
      stockQuantity: stockQuantity,
      isAvailable: isAvailable,
      isPreOrderable: isPreOrderable,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
      availableDays: availableDays,
      serviceDurationMinutes: serviceDurationMinutes,
      isVegetarian: isVegetarian,
      isVegan: isVegan,
      isHalal: isHalal,
      allergens: allergens,
      calories: calories,
      displayOrder: displayOrder,
      isFeatured: isFeatured,
      tags: tags,
      averageRating: averageRating,
      totalReviews: totalReviews,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
