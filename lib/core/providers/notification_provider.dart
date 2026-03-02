// lib/core/providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getNotifications();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getUnreadCount();
});

// Auto-refresh unread count every 30 seconds
final unreadCountPollingProvider = StreamProvider<int>((ref) async* {
  final service = ref.read(notificationServiceProvider);
  
  while (true) {
    try {
      final count = await service.getUnreadCount();
      yield count;
    } catch (e) {
      yield 0;
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});
