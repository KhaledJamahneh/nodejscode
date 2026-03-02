// lib/features/client/data/client_service.dart
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/config/api_config.dart';

class ClientService {
  final Dio _dio = DioClient.instance;

  Future<List<Map<String, dynamic>>> getRequests({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.deliveryRequests,
      queryParameters: {
        if (status != null) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(response.data['data']['requests']);
  }

  Future<void> cancelRequest(int requestId) async {
    await _dio.delete('${ApiEndpoints.deliveryRequests}/$requestId');
  }

  Future<void> createRequest({
    required int requestedGallons,
    String? priority,
    String? paymentMethod,
    String? notes,
  }) async {
    await _dio.post(
      ApiEndpoints.createDeliveryRequest,
      data: {
        'requested_gallons': requestedGallons,
        if (priority != null) 'priority': priority,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (notes != null) 'notes': notes,
      },
    );
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(ApiEndpoints.clientProfile);
    return response.data['data'];
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put(ApiEndpoints.clientProfile, data: data);
  }

  Future<Map<String, dynamic>> getUsageHistory({int months = 6}) async {
    final response = await _dio.get(
      ApiEndpoints.clientUsage,
      queryParameters: {'months': months},
    );
    return response.data['data'];
  }

  Future<List<Map<String, dynamic>>> getAssets() async {
    final response = await _dio.get(ApiEndpoints.clientAssets);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> getDebtInfo() async {
    final response = await _dio.get(ApiEndpoints.clientDebt);
    return response.data['data'];
  }

  Future<List<Map<String, dynamic>>> getCouponSizes() async {
    final response = await _dio.get('${ApiConfig.baseUrl}clients/coupon-sizes');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<void> createCouponBookRequest({
    required String bookType,
    required int couponSizeId,
    required String paymentMethod,
  }) async {
    await _dio.post(
      '${ApiConfig.baseUrl}clients/coupon-book-request',
      data: {
        'book_type': bookType,
        'coupon_size_id': couponSizeId,
        'payment_method': paymentMethod,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getCouponBookRequests() async {
    final response = await _dio.get('${ApiConfig.baseUrl}clients/coupon-book-requests');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<void> saveHomeLocation({
    required double latitude,
    required double longitude,
  }) async {
    await _dio.put(
      ApiEndpoints.clientHomeLocation,
      data: {
        'home_latitude': latitude,
        'home_longitude': longitude,
      },
    );
  }
}
