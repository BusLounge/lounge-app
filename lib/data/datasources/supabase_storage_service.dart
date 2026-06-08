import 'dart:io';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/error/exceptions.dart';

/// Service for uploading and deleting images through the backend.
/// The backend stores assets in Cloudinary and returns public URLs.
class SupabaseStorageService {
  final ApiClient apiClient;

  SupabaseStorageService({required this.apiClient});

  Future<String> _uploadImage(
    String endpoint, {
    required File imageFile,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...fields,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await apiClient.uploadFile(endpoint, formData);
      if (response.statusCode != 200) {
        throw FileUploadException(
          'Failed to upload image: HTTP ${response.statusCode}',
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final url = data['url']?.toString() ?? data['secure_url']?.toString();
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }

      throw FileUploadException(
        'Upload succeeded but no image URL was returned',
      );
    } catch (e) {
      if (e is FileUploadException) rethrow;
      throw FileUploadException('Failed to upload image: ${e.toString()}');
    }
  }

  /// Upload NIC image for a lounge owner.
  Future<String> uploadNICImage({
    required File imageFile,
    required String userId,
    required String side, // 'front' or 'back'
  }) async {
    return _uploadImage(
      '/api/v1/uploads/lounge-owner/$userId/nic/$side',
      imageFile: imageFile,
      fields: {'side': side},
    );
  }

  /// Upload lounge photo.
  Future<String> uploadLoungePhoto({
    required File imageFile,
    required String loungeId,
  }) async {
    return _uploadImage(
      '/api/v1/uploads/lounge-photos/$loungeId',
      imageFile: imageFile,
      fields: {'lounge_id': loungeId},
    );
  }

  /// Upload a product image for lounge marketplace items.
  Future<String> uploadProductImage({
    required File imageFile,
    required String loungeId,
  }) async {
    return _uploadImage(
      '/api/v1/uploads/lounge-products/$loungeId/image',
      imageFile: imageFile,
      fields: {'lounge_id': loungeId},
    );
  }

  /// Upload a special package image for lounge marketplace.
  Future<String> uploadSpecialPackageImage({
    required File imageFile,
    required String loungeId,
  }) async {
    return _uploadImage(
      '/api/v1/uploads/lounge-special-packages/$loungeId/image',
      imageFile: imageFile,
      fields: {'lounge_id': loungeId},
    );
  }

  /// Delete an image from storage
  Future<void> deleteImage({
    required String url,
    required bool isNICImage,
  }) async {
    try {
      await apiClient.post('/api/v1/uploads/image/delete', data: {'url': url});
    } catch (e) {
      throw FileUploadException('Failed to delete image: ${e.toString()}');
    }
  }

  /// Upload multiple lounge photos.
  Future<List<String>> uploadMultipleLoungePhotos({
    required List<File> imageFiles,
    required String loungeId,
  }) async {
    final urls = <String>[];

    for (final imageFile in imageFiles) {
      final url = await uploadLoungePhoto(
        imageFile: imageFile,
        loungeId: loungeId,
      );
      urls.add(url);
    }

    return urls;
  }
}
