import 'package:flutter/material.dart';
import 'package:einhod_water/l10n/app_localizations.dart';
import 'package:einhod_water/core/theme/app_theme.dart';

// ─── App Bar with language toggle ────────────────────────────────────────────
class EinhodAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showNotificationBell;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final bool showLanguageToggle;
  final bool isArabic;
  final VoidCallback? onLanguageToggle;

  const EinhodAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showNotificationBell = true,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.showLanguageToggle = true,
    this.isArabic = false,
    this.onLanguageToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        overflow: TextOverflow.ellipsis, // FIX: prevent title overflow
      ),
      actions: [
        if (showLanguageToggle)
          // FIX: replaced GestureDetector with InkWell and enforced 48×48 touch target
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: SizedBox(
              width: 48,
              height: 48,
              child: InkWell(
                onTap: onLanguageToggle,
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      isArabic ? 'EN' : 'ع',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.oceanBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (showNotificationBell)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotificationTap,
                tooltip: 'Notifications',
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      notificationCount > 99 ? '99+' : '$notificationCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: (isLoading
              ? AppColors.oceanBlue.withOpacity(0.7)
              : (backgroundColor ?? AppColors.oceanBlue)),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: isLoading ? [] : AppShadows.button,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: AppTypography.labelLarge
                            .copyWith(color: Colors.white, fontSize: 16),
                        overflow: TextOverflow
                            .ellipsis, // FIX: prevent button label overflow
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip(
      {super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── EinHod Card ─────────────────────────────────────────────────────────────
class EinhodCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Border? border;

  const EinhodCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: color ?? AppColors.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.base),
          boxShadow: AppShadows.card,
          border: border,
        ),
        child: child,
      ),
    );
  }
}

// ─── Skeleton Loader ──────────────────────────────────────────────────────────
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.divider.withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Text(title,
                style: AppTypography.headlineMedium,
                overflow: TextOverflow.ellipsis)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.oceanBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Priority Badge ───────────────────────────────────────────────────────────
class PriorityBadge extends StatelessWidget {
  final String priority; // urgent | mid_urgent | midUrgent | normal

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    String emoji;

    switch (priority) {
      case 'urgent':
        color = AppColors.urgent;
        label = 'URGENT';
        emoji = '🔴';
        break;
      case 'midUrgent':  // legacy camelCase (mock / local data)
      case 'mid_urgent': // ✅ FIX #8: API snake_case
        color = AppColors.midUrgent;
        label = 'MID';
        emoji = '🟡';
        break;
      default:
        color = AppColors.normal;
        label = 'NORMAL';
        emoji = '🟢';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '$emoji $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── GPS Toggle Banner ────────────────────────────────────────────────────────
class GpsToggleBanner extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const GpsToggleBanner(
      {super.key, required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md),
      color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.divider,
      child: Row(
        children: [
          if (isActive)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.success.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 2)
                ],
              ),
            ),
          if (!isActive)
            const Icon(Icons.location_off,
                size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Sharing / مشاركة الموقع',
                  style: AppTypography.labelLarge.copyWith(
                    color:
                        isActive ? AppColors.success : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (isActive)
                  Text(
                    'Active — Admin can see your location',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.success),
                  ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onToggle,
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

// ─── Offline Banner ───────────────────────────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  final int pendingItems;

  const OfflineBanner({super.key, required this.pendingItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      color: AppColors.warning.withOpacity(0.15),
      child: Row(
        children: [
          const Text('📡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Offline — Changes will sync when connected / غير متصل بالإنترنت',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning, fontWeight: FontWeight.w600),
            ),
          ),
          if (pendingItems > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$pendingItems pending',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Inventory Level Bar ──────────────────────────────────────────────────────
class GallonsIndicator extends StatelessWidget {
  final int current;
  final int max;
  final VoidCallback? onTap;

  const GallonsIndicator(
      {super.key, required this.current, required this.max, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // FIX #1: avoid division by zero when max == 0
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final color = current <= 10
        ? AppColors.danger
        : current <= 20
            ? AppColors.warning
            : AppColors.oceanBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.sm),
        color: AppColors.white,
        child: Row(
          children: [
            const Text('🪣', style: TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${l10n.gallonsRemaining}: ',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '$current',
              style:
                  AppTypography.labelLarge.copyWith(color: color, fontSize: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            if (current <= 20) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.warning_rounded, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.base),
            Text(title,
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!,
                  style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: actionLabel!, onTap: onAction, width: 200),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────
class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepIndicator(
      {super.key, required this.totalSteps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isDone = index < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive || isDone ? AppColors.oceanBlue : AppColors.divider,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────
class KpiCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final String? trend;
  final bool trendUp;
  final Color? color;

  const KpiCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.trend,
    this.trendUp = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return EinhodCard(
      child: Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trendUp ? AppColors.success : AppColors.danger)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      '${trendUp ? '↑' : '↓'} $trend',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: trendUp ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTypography.displayMedium
                      .copyWith(color: color ?? AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Delivery Card (shared between worker and admin) ──────────────────────────
class DeliveryCard extends StatelessWidget {
  final String clientName;
  final String address;
  final int gallons;
  final String priority; // urgent, midUrgent, normal
  final String status;
  final VoidCallback? onRecord;
  final bool isDimmed;

  const DeliveryCard({
    super.key,
    required this.clientName,
    required this.address,
    required this.gallons,
    required this.priority,
    required this.status,
    this.onRecord,
    this.isDimmed = false,
  });

  Color get _priorityBorderColor {
    switch (priority) {
      case 'urgent':
        return AppColors.urgent;
      case 'midUrgent':
        return AppColors.midUrgent;
      default:
        return AppColors.normal;
    }
  }

  Color get _statusColor {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'inProgress':
        return AppColors.oceanBlue;
      case 'skipped':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDimmed ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
          border:
              Border(left: BorderSide(color: _priorityBorderColor, width: 4)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (priority != 'normal') ...[
                                    PriorityBadge(priority: priority),
                                    const SizedBox(width: AppSpacing.sm),
                                  ],
                                  Expanded(
                                    child: Text(
                                      clientName,
                                      style: AppTypography.titleLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: AppTypography.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text('🪣', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Text('$gallons gallons',
                                      style: AppTypography.bodySmall
                                          .copyWith(fontWeight: FontWeight.w500)),
                                  const SizedBox(width: AppSpacing.sm),
                                  StatusChip(
                                    label: status
                                        .replaceAll('InProgress', 'In Progress')
                                        .replaceAllMapped(
                                          RegExp(r'([A-Z])'),
                                          (m) => ' ${m[0]}',
                                        )
                                        .trim(),
                                    color: _statusColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),            if (onRecord != null && status != 'completed')
              GestureDetector(
                onTap: onRecord,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.oceanBlue,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Record',
                    style: AppTypography.bodySmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
