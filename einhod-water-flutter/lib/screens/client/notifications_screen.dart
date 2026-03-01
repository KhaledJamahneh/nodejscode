import 'package:flutter/material.dart';
import 'package:einhod_water/core/theme/app_theme.dart';
import 'package:einhod_water/core/widgets/widgets.dart';
import '../../models/models.dart';

class NotificationsScreen extends StatefulWidget {
  final List<NotificationModel> notifications;

  const NotificationsScreen({super.key, required this.notifications});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(widget.notifications);
  }

  Color _borderColor(NotificationLevel level) {
    switch (level) {
      case NotificationLevel.important:
        return AppColors.danger;
      case NotificationLevel.midImportance:
        return AppColors.warning;
      case NotificationLevel.normal:
        return AppColors.oceanBlue;
    }
  }

  IconData _icon(NotificationLevel level) {
    switch (level) {
      case NotificationLevel.important:
        return Icons.notifications_active;
      case NotificationLevel.midImportance:
        return Icons.notifications;
      case NotificationLevel.normal:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group by date
    final today = _notifications
        .where((n) => DateTime.now().difference(n.timestamp).inDays == 0)
        .toList();
    final yesterday = _notifications
        .where((n) => DateTime.now().difference(n.timestamp).inDays == 1)
        .toList();
    final thisWeek = _notifications.where((n) {
      final diff = DateTime.now().difference(n.timestamp).inDays;
      return diff > 1 && diff <= 7;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _notifications = _notifications
                .map((n) => NotificationModel(
                      id: n.id,
                      title: n.title,
                      body: n.body,
                      level: n.level,
                      timestamp: n.timestamp,
                      isRead: true,
                      actionLabel: n.actionLabel,
                    ))
                .toList()),
            child: Text('Mark all read',
                style: TextStyle(color: AppColors.oceanBlue, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showPreferences(context),
            tooltip: 'Notification preferences',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          if (today.isNotEmpty) ...[
            _GroupLabel('Today'),
            ...today.map((n) => _NotificationCard(
                notification: n,
                borderColor: _borderColor(n.level),
                icon: _icon(n.level))),
          ],
          if (yesterday.isNotEmpty) ...[
            _GroupLabel('Yesterday'),
            ...yesterday.map((n) => _NotificationCard(
                notification: n,
                borderColor: _borderColor(n.level),
                icon: _icon(n.level))),
          ],
          if (thisWeek.isNotEmpty) ...[
            _GroupLabel('This Week'),
            ...thisWeek.map((n) => _NotificationCard(
                notification: n,
                borderColor: _borderColor(n.level),
                icon: _icon(n.level))),
          ],
          if (_notifications.isEmpty)
            const EmptyState(
              emoji: '🔔',
              title: 'No notifications yet',
              subtitle: 'We\'ll notify you about deliveries and updates here',
            ),
        ],
      ),
    );
  }

  void _showPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _NotificationPreferencesSheet(),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(label,
          style: AppTypography.labelLarge
              .copyWith(color: AppColors.textSecondary)),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final Color borderColor;
  final IconData icon;

  const _NotificationCard(
      {required this.notification,
      required this.borderColor,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: AppColors.danger.withOpacity(0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      direction: DismissDirection.endToStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.white
              : AppColors.oceanBlue.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: borderColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(notification.title,
                        style: AppTypography.titleMedium)),
                Text(notification.timeAgo, style: AppTypography.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(notification.body,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (notification.actionLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () {},
                child: Text(
                  notification.actionLabel!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.oceanBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationPreferencesSheet extends StatefulWidget {
  const _NotificationPreferencesSheet();

  @override
  State<_NotificationPreferencesSheet> createState() =>
      _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState
    extends State<_NotificationPreferencesSheet> {
  final _prefs = {
    'Delivery Updates': true,
    'Subscription Reminders': true,
    'Payment Reminders': true,
    'Promotions & Offers': false,
    'System Announcements': true,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Notification Preferences', style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.xl),
          ..._prefs.entries.map((e) => SwitchListTile(
                title: Text(e.key, style: AppTypography.titleMedium),
                value: e.value,
                activeColor: AppColors.oceanBlue,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _prefs[e.key] = v),
              )),
          const SizedBox(height: AppSpacing.base),
          PrimaryButton(
              label: 'Save Preferences', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
