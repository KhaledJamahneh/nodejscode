// lib/features/notifications/presentation/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/utils/notification_localizer.dart';
import '../../../../widgets/shared_widgets.dart';
import 'package:einhod_water/l10n/app_localizations.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (data) {
          final notifications = data['notifications'] as List;
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.iosGray.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(l10n.noActivity, style: const TextStyle(color: AppTheme.iosGray)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(notification: notification);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.iosRed),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final Map<String, dynamic> notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? '';
    final createdAt = DateTime.parse(notification['created_at']);

    return Dismissible(
      key: Key('notification_${notification['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.iosRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(notificationServiceProvider).deleteNotification(notification['id']);
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadCountProvider);
      },
      child: ModernCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        color: isRead ? null : AppTheme.primaryBlue.withOpacity(0.05),
        child: InkWell(
          onTap: () async {
            if (!isRead) {
              await ref.read(notificationServiceProvider).markAsRead(notification['id']);
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            }
            _navigateToReference(context, notification);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getIconColor(type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(type), color: _getIconColor(type), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              NotificationLocalizer.getTitle(
                                notification['notification_key'],
                                notification['title'] ?? '',
                                l10n,
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NotificationLocalizer.getMessage(
                          notification['notification_key'],
                          notification['message'] ?? '',
                          NotificationLocalizer.parseParams(notification['params']),
                          l10n,
                        ),
                        style: const TextStyle(fontSize: 13, color: AppTheme.iosGray),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(createdAt),
                        style: const TextStyle(fontSize: 11, color: AppTheme.iosGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'coupon_request':
        return Icons.menu_book_rounded;
      case 'coupon_status':
        return Icons.check_circle_outline;
      case 'delivery_request':
        return Icons.local_shipping_rounded;
      case 'delivery_status':
        return Icons.update_rounded;
      case 'worker_assignment':
        return Icons.assignment_ind_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'coupon_request':
      case 'coupon_status':
        return AppTheme.iosIndigo;
      case 'delivery_request':
      case 'delivery_status':
        return AppTheme.primaryBlue;
      case 'worker_assignment':
        return AppTheme.iosOrange;
      default:
        return AppTheme.iosGray;
    }
  }

  void _navigateToReference(BuildContext context, Map<String, dynamic> notification) {
    final referenceType = notification['reference_type'];
    final referenceId = notification['reference_id'];

    if (referenceType == null || referenceId == null) return;

    switch (referenceType) {
      case 'coupon_book_request':
        context.push('/admin/requests?index=2');
        break;
      case 'delivery_request':
        context.push('/admin/requests');
        break;
      default:
        break;
    }
  }
}
