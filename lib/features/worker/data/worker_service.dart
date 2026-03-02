// lib/features/worker/data/worker_service.dart
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/config/api_config.dart';

class WorkerService {
  Dio get _dio => DioClient.instance;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(ApiEndpoints.workerProfile);
    return response.data['data'];
  }

  Future<List<Map<String, dynamic>>> getMainSchedule({String? date}) async {
    final response = await _dio.get(
      ApiEndpoints.mainSchedule,
      queryParameters: {if (date != null) 'date': date},
    );
    return List<Map<String, dynamic>>.from(response.data['data']['deliveries']);
  }

  Future<List<Map<String, dynamic>>> getSecondaryList() async {
    final response = await _dio.get(ApiEndpoints.secondaryList);
    return List<Map<String, dynamic>>.from(response.data['data']['requests']);
  }

  Future<void> startDelivery(int deliveryId) async {
    await _dio.post('${ApiEndpoints.startDelivery}/$deliveryId/start');
  }

  Future<void> acceptDelivery(int deliveryId) async {
    await _dio.post('${ApiEndpoints.startDelivery}/$deliveryId/accept');
  }

  Future<void> completeDelivery({
    required int deliveryId,
    required int gallonsDelivered,
    int? emptyGallonsReturned,
    double? latitude,
    double? longitude,
    String? notes,
    String? photoUrl,
    double? paidAmount,
    double? totalPrice,
  }) async {
    await _dio.post(
      '${ApiEndpoints.completeDelivery}/$deliveryId/complete',
      data: {
        'gallons_delivered': gallonsDelivered,
        'empty_gallons_returned': emptyGallonsReturned ?? 0,
        'delivery_latitude': latitude,
        'delivery_longitude': longitude,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (paidAmount != null) 'paid_amount': paidAmount,
        if (totalPrice != null) 'total_price': totalPrice,
      },
    );
  }

  Future<void> acceptRequest(int requestId) async {
    await _dio.post('${ApiEndpoints.acceptRequest}/$requestId/accept');
  }

  Future<void> completeRequest({
    required int requestId,
    required int gallonsDelivered,
    int? emptyGallonsReturned,
    double? latitude,
    double? longitude,
    String? notes,
    String? photoUrl,
    // FIX: New — number of coupon-book coupons paid for this request.
    int? paidCouponsCount,
    double? paidAmount,
    double? totalPrice,
  }) async {
    await _dio.post(
      '${ApiEndpoints.completeRequest}/$requestId/complete',
      data: {
        'gallons_delivered': gallonsDelivered,
        'empty_gallons_returned': emptyGallonsReturned ?? 0,
        'delivery_latitude': latitude,
        'delivery_longitude': longitude,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (photoUrl != null) 'photo_url': photoUrl,
        // FIX: only include if relevant (coupon delivery)
        if (paidCouponsCount != null) 'paid_coupons_count': paidCouponsCount,
        if (paidAmount != null) 'paid_amount': paidAmount,
        if (totalPrice != null) 'total_price': totalPrice,
      },
    );
  }

  Future<void> updateInventory(int currentGallons) async {
    await _dio.put(
      ApiEndpoints.updateInventory,
      data: {'current_gallons': currentGallons},
    );
  }

  Future<void> toggleGPS(bool enabled) async {
    await _dio.put(
      ApiEndpoints.toggleGPS,
      data: {'enabled': enabled},
    );
  }

  // On-site Filling Methods
  Future<List<Map<String, dynamic>>> getFillingStations() async {
    final response = await _dio.get(ApiEndpoints.onsiteStations);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<void> updateStationStatus(int stationId, String status) async {
    await _dio.put(
      '${ApiEndpoints.updateStationStatus}/$stationId',
      data: {'status': status},
    );
  }

  Future<Map<String, dynamic>> startFillingSession(int stationId) async {
    final response = await _dio.post(
      ApiEndpoints.onsiteStartSession,
      data: {'station_id': stationId},
    );
    return response.data['data'];
  }

  Future<void> completeFillingSession({
    required int sessionId,
    required int gallonsFilled,
  }) async {
    await _dio.post(
      '${ApiEndpoints.onsiteCompleteSession}/$sessionId/complete',
      data: {'gallons_filled': gallonsFilled},
    );
  }

  Future<void> updateFillingSession({
    required int sessionId,
    required int gallonsFilled,
  }) async {
    await _dio.patch(
      '${ApiEndpoints.onsiteCompleteSession}/$sessionId',
      data: {'gallons_filled': gallonsFilled},
    );
  }

  Future<void> deleteFillingSession(int sessionId) async {
    await _dio.delete('${ApiEndpoints.onsiteCompleteSession}/$sessionId');
  }

  Future<List<Map<String, dynamic>>> getRecentFillingSessions() async {
    final response = await _dio.get(ApiEndpoints.onsiteRecentSessions);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final response = await _dio.get('/workers/expenses');
    return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
  }

  Future<void> submitExpense(Map<String, dynamic> data) async {
    await _dio.post('/workers/expenses', data: data);
  }

  Future<void> updateExpense(int id, Map<String, dynamic> data) async {
    await _dio.put('/workers/expenses/$id', data: data);
  }

  Future<void> deleteExpense(int id) async {
    await _dio.delete('/workers/expenses/$id');
  }
}
