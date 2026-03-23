class TransportLocation {
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

  TransportLocation({
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
}
