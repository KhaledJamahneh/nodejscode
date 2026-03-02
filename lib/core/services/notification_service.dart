// lib/core/services/notification_service.dart
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../config/api_config.dart';

class NotificationService {
  Dio get _dio => DioClient.instance;

  Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'unread_only': unreadOnly,
      },
    );
    return response.data['data'];
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiEndpoints.unreadCount);
    return response.data['data']['unread_count'];
  }

  Future<void> markAsRead(int id) async {
    await _dio.patch('${ApiEndpoints.notifications}/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch(ApiEndpoints.markAllRead);
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('${ApiEndpoints.notifications}/$id');
  }
}
