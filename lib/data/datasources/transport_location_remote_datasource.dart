import 'package:dio/dio.dart';
import '../models/transport_location_model.dart';
import '../../core/error/exceptions.dart';
import '../../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TransportLocationRemoteDataSource {
  /// GET /api/v1/lounges/:id/transport-locations
  Future<List<TransportLocationModel>> getTransportLocations(String loungeId);

  /// POST /api/v1/lounges/transport-locations
  Future<TransportLocationModel> addTransportLocation({
    required String loungeId,
    required String locationName,
    required double latitude,
    required double longitude,
    required int estDuration,
    required double distance,
  });

  /// PUT /api/v1/lounges/:id/transport-locations/:location_id
  Future<TransportLocationModel> updateTransportLocation({
    required String loungeId,
    required String locationId,
    String? locationName,
    double? latitude,
    double? longitude,
    int? estDuration,
    double? distance,
    bool? isActive,
  });

  /// DELETE /api/v1/lounges/:id/transport-locations/:location_id
  Future<void> deleteTransportLocation({
    required String loungeId,
    required String locationId,
  });

  /// GET /api/v1/lounges/:id/transport-locations/:location_id/prices
  Future<Map<String, double>> getLocationPrices({
    required String loungeId,
    required String locationId,
  });

  /// POST /api/v1/lounges/:id/transport-locations/:location_id/prices
  Future<void> setLocationPrices({
    required String loungeId,
    required String locationId,
    required Map<String, double> prices,
  });
}

class TransportLocationRemoteDataSourceImpl
    implements TransportLocationRemoteDataSource {
  late final Dio _dio;
  final _secureStorage = const FlutterSecureStorage();

  TransportLocationRemoteDataSourceImpl() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.getLoungeBaseUrl(),
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔐 Transport Location API: Token added to request');
        } else {
          print('⚠️ Transport Location API: No token found');
        }
        return handler.next(options);
      },
    ));
  }

  @override
  Future<List<TransportLocationModel>> getTransportLocations(
      String loungeId) async {
    try {
      print('📤 [API] Getting transport locations for lounge: $loungeId');

      final response = await _dio.get(
        '/api/v1/lounges/$loungeId/transport-locations',
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.data == null) {
        throw const ServerException(
          'Empty response from server',
          'EMPTY_RESPONSE',
          null,
        );
      }

      try {
        final data = response.data as Map<String, dynamic>;
        // Backend returns 'transport_locations' key
        final locationsList = data['transport_locations'] as List<dynamic>? ??
            data['locations'] as List<dynamic>? ??
            [];

        print('📥 Found ${locationsList.length} locations');

        return locationsList
            .map((json) =>
                TransportLocationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (parseError) {
        print('❌ Parse Error: $parseError');
        print('❌ Response type: ${response.data.runtimeType}');
        throw ServerException(
          'Failed to parse locations: $parseError',
          'PARSE_ERROR',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected Error: $e');
      rethrow;
    }
  }

  @override
  Future<TransportLocationModel> addTransportLocation({
    required String loungeId,
    required String locationName,
    required double latitude,
    required double longitude,
    required int estDuration,
    required double distance,
  }) async {
    try {
      print('📤 [API] Adding transport location: $locationName');
      print('📤 [API] Lounge ID: $loungeId');
      print('📤 [API] Coordinates: ($latitude, $longitude)');
      print('📤 [API] Estimated duration: $estDuration min');
      print('📤 [API] Distance: $distance km');

      final response = await _dio.post(
        '/api/v1/lounges/transport-locations',
        data: {
          'lounge_id': loungeId,
          'location': locationName,
          'latitude': latitude,
          'longitude': longitude,
          'est_duration': estDuration,
          'distance': distance,
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.data == null) {
        throw const ServerException(
          'Empty response from server',
          'EMPTY_RESPONSE',
          null,
        );
      }

      try {
        final locationData = _extractTransportLocationData(response.data);

        return TransportLocationModel.fromJson(locationData);
      } catch (parseError) {
        print('❌ Parse Error: $parseError');
        print('❌ Response type: ${response.data.runtimeType}');
        throw ServerException(
          'Failed to parse response: $parseError',
          'PARSE_ERROR',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected Error: $e');
      rethrow;
    }
  }

  @override
  Future<TransportLocationModel> updateTransportLocation({
    required String loungeId,
    required String locationId,
    String? locationName,
    double? latitude,
    double? longitude,
    int? estDuration,
    double? distance,
    bool? isActive,
  }) async {
    try {
      print('📤 [API] Updating transport location: $locationId');

      final requestData = <String, dynamic>{};
      if (locationName != null && locationName.trim().isNotEmpty) {
        requestData['location'] = locationName.trim();
      }
      if (latitude != null) {
        requestData['latitude'] = latitude;
      }
      if (longitude != null) {
        requestData['longitude'] = longitude;
      }
      if (estDuration != null) {
        requestData['est_duration'] = estDuration;
      }
      if (distance != null) {
        requestData['distance'] = distance;
      }
      if (isActive != null) {
        requestData['status'] = isActive ? 'active' : 'inactive';
      }

      if (requestData.isEmpty) {
        throw const ServerException(
          'At least one field must be provided for update',
          'EMPTY_UPDATE_PAYLOAD',
          400,
        );
      }

      final response = await _dio.put(
        '/api/v1/lounges/$loungeId/transport-locations/$locationId',
        data: requestData,
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.data == null) {
        throw const ServerException(
          'Empty response from server',
          'EMPTY_RESPONSE',
          null,
        );
      }

      final locationData = _extractTransportLocationData(response.data);
      return TransportLocationModel.fromJson(locationData);
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _extractTransportLocationData(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      final direct = rawData;

      final nestedLocation = direct['location'];
      if (nestedLocation is Map<String, dynamic>) {
        return nestedLocation;
      }

      final nestedData = direct['data'];
      if (nestedData is Map<String, dynamic>) {
        return nestedData;
      }

      if (direct.containsKey('id') && direct.containsKey('lounge_id')) {
        return direct;
      }
    }

    throw const ServerException(
      'Invalid transport location response format',
      'INVALID_RESPONSE_FORMAT',
      null,
    );
  }

  @override
  Future<void> deleteTransportLocation({
    required String loungeId,
    required String locationId,
  }) async {
    try {
      print('📤 [API] Deleting transport location: $locationId');

      final response = await _dio.delete(
        '/api/v1/lounges/$loungeId/transport-locations/$locationId',
      );

      print('📥 Response status: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, double>> getLocationPrices({
    required String loungeId,
    required String locationId,
  }) async {
    try {
      print('📤 [API] Getting prices for location: $locationId');

      final response = await _dio.get(
        '/api/v1/lounges/$loungeId/transport-locations/$locationId/prices',
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.data == null) {
        throw const ServerException(
          'Empty response from server',
          'EMPTY_RESPONSE',
          null,
        );
      }

      final data = response.data as Map<String, dynamic>;

      // Backend returns prices with these field names
      final prices = <String, double>{};

      // Map field names to vehicle types
      if (data['three_wheeler_price'] != null) {
        prices['three_wheeler_price'] =
            (data['three_wheeler_price'] as num).toDouble();
      }
      if (data['car_price'] != null) {
        prices['car_price'] = (data['car_price'] as num).toDouble();
      }
      if (data['van_price'] != null) {
        prices['van_price'] = (data['van_price'] as num).toDouble();
      }

      return prices;
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> setLocationPrices({
    required String loungeId,
    required String locationId,
    required Map<String, double> prices,
  }) async {
    try {
      print('📤 [API] Setting prices for location: $locationId');
      print('📤 [API] Prices: $prices');

      // Map vehicle types to backend field names
      final requestData = <String, dynamic>{};

      prices.forEach((vehicleType, price) {
        final key = vehicleType.toLowerCase().replaceAll(' ', '_') + '_price';
        requestData[key] = price > 0 ? price : null;
      });

      // Also support direct field names if provided
      if (prices.containsKey('three_wheeler_price')) {
        requestData['three_wheeler_price'] = prices['three_wheeler_price'];
      }
      if (prices.containsKey('car_price')) {
        requestData['car_price'] = prices['car_price'];
      }
      if (prices.containsKey('van_price')) {
        requestData['van_price'] = prices['van_price'];
      }

      final response = await _dio.post(
        '/api/v1/lounges/$loungeId/transport-locations/$locationId/prices',
        data: requestData,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkException(
        'Connection timeout. Please check if the backend server is running.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const NetworkException(
        'Cannot connect to server. Please ensure the backend is running and accessible.',
      );
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String message = 'An error occurred';
      String? code;

      print('📥 Error Response Data: $data');
      print('📥 Error Status Code: $statusCode');

      if (data is Map<String, dynamic>) {
        message =
            data['message'] as String? ?? data['error'] as String? ?? message;
        code = data['code'] as String? ?? data['error'] as String?;
      } else if (data is String) {
        message = data;
      }

      if (statusCode == 401) {
        return AuthException(message, code);
      } else if (statusCode == 403) {
        return AuthException(message, code ?? 'FORBIDDEN');
      } else if (statusCode == 404) {
        // Route not found - likely a backend routing issue
        print('❓ 404 Not Found: Check if backend route is properly registered');
        return ServerException(
          message.isNotEmpty
              ? message
              : 'Endpoint not found. Verify backend route is registered.',
          code ?? 'NOT_FOUND',
          statusCode,
        );
      } else if (statusCode == 409) {
        return ServerException(
          message.isNotEmpty
              ? message
              : 'This location already exists or there is a conflict',
          code ?? 'CONFLICT',
          statusCode,
        );
      } else if (statusCode == 429) {
        return ServerException(message, code, statusCode);
      } else if (statusCode != null && statusCode >= 500) {
        return ServerException(message, code, statusCode);
      } else {
        return ServerException(message, code, statusCode);
      }
    }

    return NetworkException(error.message ?? 'Network error');
  }
}
