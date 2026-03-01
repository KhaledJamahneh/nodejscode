// lib/core/providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationsProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, viewAs) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getNotifications(viewAs: viewAs);
});

final unreadCountProvider = FutureProvider.family<int, String?>((ref, viewAs) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getUnreadCount(viewAs: viewAs);
});

// Auto-refresh unread count every 30 seconds
final unreadCountPollingProvider = StreamProvider.family<int, String?>((ref, viewAs) async* {
  final service = ref.read(notificationServiceProvider);
  
  while (true) {
    try {
      final count = await service.getUnreadCount(viewAs: viewAs);
      yield count;
    } catch (e) {
      yield 0;
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});
