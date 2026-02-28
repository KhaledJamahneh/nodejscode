import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/services/haptic_service.dart';

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
    final l10n = AppLocalizations.of(context)!;
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

    int animationIndex = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.notifications),
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
            child: Text(l10n.markAllRead,
                style: const TextStyle(color: AppColors.oceanBlue, fontSize: 13)),
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
            _GroupLabel(l10n.today),
            ...today.map((n) => _NotificationCard(
                notification: n,
                borderColor: _borderColor(n.level),
                icon: _icon(n.level))
                .animate()
                .fadeIn(delay: (50 * animationIndex++).ms)
                .slideX(begin: 0.1, end: 0)),
          ],
          if (yesterday.isNotEmpty) ...[
            _GroupLabel('Yesterday'), // This one isn't in arb yet, let's just use it for now if needed or check if arb has it
            ...yesterday.map((n) => _NotificationCard(
                notification: n,
                borderColor: _borderColor(n.level),
                icon: _icon(n.level))
                .animate()
                .fadeIn(delay: (50 * animationIndex++).ms)
                .slideX(begin: 0.1, end: 0)),
          ],
          if (thisWeek.isNotEmpty) ...[
            _GroupLabel('This Week'),
            ...thisWeek.map((n) => _NotificationCard(
                notification: n,
                borderColor: _borderColor(n.level),
                icon: _icon(n.level))
                .animate()
                .fadeIn(delay: (50 * animationIndex++).ms)
                .slideX(begin: 0.1, end: 0)),
          ],
          if (_notifications.isEmpty)
            EmptyState(
              emoji: '🔔',
              title: l10n.noActivity,
              subtitle: l10n.yourRequestsAppearHere,
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
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.xl),
        child: const Icon(Icons.check_circle_outline, color: AppColors.success),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onUpdate: (details) {
        if (details.reached && !details.previousReached) {
          HapticService.light();
        }
      },
      onDismissed: (direction) {
        HapticService.medium();
        // Logical implementation would be here to update parent state
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        color: notification.isRead
            ? AppColors.white
            : AppColors.glassBlue,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: borderColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(notification.title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                        ))),
                Text(notification.timestamp.difference(DateTime.now()).inDays == 0 ? l10n.today : notification.timeAgo, style: AppTypography.microCopy.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(notification.body,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (notification.actionLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.oceanBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 36),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    child: Text(notification.actionLabel!, style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () {},
                    child: Text(l10n.dismiss, style: const TextStyle(fontSize: 12)),
                  ),
                ],
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
