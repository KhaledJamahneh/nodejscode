import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/user_model.dart';

class UserCard extends StatelessWidget {
  final User user;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleActive;
  final VoidCallback? onViewShifts;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onToggleActive,
    this.onViewShifts,
    this.onEdit,
    this.onDelete,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return AppTheme.iosPurple;
      case 'administrator':
        return AppTheme.iosBlue;
      case 'delivery_worker':
        return AppTheme.iosTeal;
      case 'onsite_worker':
        return AppTheme.iosOrange;
      case 'client':
      default:
        return AppTheme.iosGreen;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.shield_rounded;
      case 'administrator':
        return Icons.admin_panel_settings_rounded;
      case 'delivery_worker':
        return Icons.local_shipping_rounded;
      case 'onsite_worker':
        return Icons.factory_rounded;
      case 'client':
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryRole = user.roles.isNotEmpty ? user.roles.first : 'client';
    final roleColor = _getRoleColor(primaryRole);
    final isWorker = user.roles.any((r) => ['delivery_worker', 'onsite_worker'].contains(r));

    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: isSelected ? AppTheme.primary : null,
      borderWidth: isSelected ? 2.5 : null,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getRoleIcon(primaryRole),
                  color: roleColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              // User Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.phoneNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.iosGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              
              // Status Badge
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? AppTheme.iosGreen.withOpacity(0.1)
                        : AppTheme.iosRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    user.statusDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: user.isActive ? AppTheme.iosGreen : AppTheme.iosRed,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              
              // Actions Menu
              PopupMenuButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppTheme.iosGray,
                  size: 20,
                ),
                itemBuilder: (context) => [
                  if (onToggleActive != null)
                    PopupMenuItem(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                            color: user.isActive
                                ? AppTheme.iosOrange
                                : AppTheme.iosGreen,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              user.isActive ? l10n.deactivate : l10n.activate,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: onToggleActive,
                    ),
                  if (isWorker && onViewShifts != null)
                    PopupMenuItem(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppTheme.iosBlue,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              l10n.viewShifts,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: onViewShifts,
                    ),
                  if (onEdit != null)
                    PopupMenuItem(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppTheme.iosBlue,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              l10n.edit,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: onEdit,
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_rounded,
                            size: 18,
                            color: AppTheme.iosRed,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              l10n.delete,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      onTap: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
