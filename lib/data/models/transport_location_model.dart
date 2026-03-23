import '../../domain/entities/transport_location.dart';

class TransportLocationModel {
  final String id;
  final String loungeId;
  final String locationName;
  final double latitude;
  final double longitude;
  final int? estDuration;
  final double? distance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, double>? prices; // vehicle_type -> price

  TransportLocationModel({
    required this.id,
    required this.loungeId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.estDuration,
    this.distance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.prices,
  });

  factory TransportLocationModel.fromJson(Map<String, dynamic> json) {
    Map<String, double>? parsedPrices;
    if (json['prices'] != null) {
      parsedPrices = {};
      final pricesData = json['prices'] as Map<String, dynamic>;
      pricesData.forEach((key, value) {
        parsedPrices![key] = (value as num).toDouble();
      });
    }

    // Determine isActive from multiple possible fields
    bool isActive = true;
    if (json['is_active'] is bool) {
      isActive = json['is_active'] as bool;
    } else if (json['status'] is String) {
      isActive = (json['status'] as String).toLowerCase() == 'active';
    }

    return TransportLocationModel(
      id: json['id'] as String,
      loungeId: json['lounge_id'] as String,
      locationName:
          json['location'] as String? ?? json['location_name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      estDuration: (json['est_duration'] as num?)?.toInt() ??
          (json['estDuration'] as num?)?.toInt(),
      distance: (json['distance'] as num?)?.toDouble(),
      isActive: isActive,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      prices: parsedPrices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lounge_id': loungeId,
      'location': locationName,
      'latitude': latitude,
      'longitude': longitude,
      if (estDuration != null) 'est_duration': estDuration,
      if (distance != null) 'distance': distance,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (prices != null) 'prices': prices,
    };
  }

  TransportLocation toEntity() {
    return TransportLocation(
      id: id,
      loungeId: loungeId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      estDuration: estDuration,
      distance: distance,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      prices: prices,
    );
  }

  factory TransportLocationModel.fromEntity(TransportLocation entity) {
    return TransportLocationModel(
      id: entity.id,
      loungeId: entity.loungeId,
      locationName: entity.locationName,
      latitude: entity.latitude,
      longitude: entity.longitude,
      estDuration: entity.estDuration,
      distance: entity.distance,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      prices: entity.prices,
    );
  }
}
