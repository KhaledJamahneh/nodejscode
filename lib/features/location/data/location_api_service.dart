// lib/features/location/data/location_api_service.dart
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/config/api_config.dart';

/// All location-related HTTP calls.
class LocationApiService {
  Dio get _dio => DioClient.instance;

  // ─── Worker ───────────────────────────────────────────────────────────────

  /// Worker calls this periodically (every ~30 s) while tracking.
  Future<void> updateWorkerLocation({
    required double latitude,
    required double longitude,
    int? activeDeliveryId,
  }) async {
    await _dio.put(
      ApiEndpoints.workerLocation,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (activeDeliveryId != null) 'delivery_id': activeDeliveryId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ─── Client ───────────────────────────────────────────────────────────────

  /// Persist the client's home location (one-time / update anytime).
  Future<void> saveClientHomeLocation({
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

  /// Poll the assigned worker's location for an in-progress delivery.
  /// Returns null if no live location is available yet.
  Future<WorkerLocationSnapshot?> getWorkerLocationForDelivery(
    int deliveryId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.workerLiveLocation}/$deliveryId',
      );
      final data = response.data['data'];
      if (data == null) return null;
      return WorkerLocationSnapshot.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Poll the assigned worker's location for an in-progress request.
  Future<WorkerLocationSnapshot?> getWorkerLocationForRequest(
    int requestId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.workerLiveLocationRequest}/$requestId',
      );
      final data = response.data['data'];
      if (data == null) return null;
      return WorkerLocationSnapshot.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

/// Snapshot of a worker's live position as returned by the API.
class WorkerLocationSnapshot {
  final double latitude;
  final double longitude;
  final String? workerName;
  final DateTime? updatedAt;

  const WorkerLocationSnapshot({
    required this.latitude,
    required this.longitude,
    this.workerName,
    this.updatedAt,
  });

  factory WorkerLocationSnapshot.fromJson(Map<String, dynamic> json) {
    return WorkerLocationSnapshot(
      latitude: double.tryParse(json['latitude'].toString()) ?? 0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0,
      workerName: json['worker_name'],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
