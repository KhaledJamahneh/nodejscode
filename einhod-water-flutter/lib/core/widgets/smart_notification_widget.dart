import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'glass_card.dart';

class SmartNotificationList extends StatelessWidget {
  final List<NotificationGroup> groups;

  const SmartNotificationList({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: groups.length,
      itemBuilder: (context, i) => _GroupWidget(group: groups[i]),
    );
  }
}

class NotificationGroup {
  final String title;
  final List<NotificationItem> items;
  NotificationGroup({required this.title, required this.items});
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final String? icon;
  final List<NotificationAction>? actions;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    this.icon,
    this.actions,
  });
}

class NotificationAction {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isPrimary;

  NotificationAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.isPrimary = false,
  });
}

class _GroupWidget extends StatelessWidget {
  final NotificationGroup group;
  const _GroupWidget({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            group.title.toUpperCase(),
            style: AppTypography.microCopy.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...group.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _NotificationCard(item: item),
            )),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      color: item.isRead ? AppColors.white : AppColors.glassBlue,
      opacity: item.isRead ? 0.9 : 0.7,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.base),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.isRead ? AppColors.divider : AppColors.oceanBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item.icon ?? '🔔',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              item.title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(item.time),
                  style: AppTypography.microCopy.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            isThreeLine: true,
          ),
          if (item.actions != null && item.actions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(left: AppSpacing.base, right: AppSpacing.base, bottom: AppSpacing.base),
              child: Row(
                children: item.actions!.map((action) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: TextButton.icon(
                    onPressed: action.onTap,
                    icon: action.icon != null ? Icon(action.icon, size: 16) : const SizedBox.shrink(),
                    label: Text(action.label),
                    style: TextButton.styleFrom(
                      backgroundColor: action.isPrimary ? AppColors.oceanBlue : AppColors.divider.withOpacity(0.5),
                      foregroundColor: action.isPrimary ? Colors.white : AppColors.oceanBlue,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
