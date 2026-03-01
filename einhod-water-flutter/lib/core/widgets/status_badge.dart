import 'package:flutter/material.dart';
import 'package:einhod_water/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final IconData? customIcon;
  final Color? customColor;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.customIcon,
    this.customColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? StatusColors.getColor(status);
    final icon = customIcon ?? StatusColors.getIcon(status);
    final label = customLabel ?? _getLabel(status);

    return Container(
      padding: isCompact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 14 : 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'urgent':
        return 'Urgent';
      case 'mid_urgent':
        return 'Mid Urgent';
      case 'non_urgent':
        return 'Normal';
      default:
        return status;
    }
  }
}

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool isCompact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = PriorityColors.getColor(priority);
    final icon = PriorityColors.getIcon(priority);

    return StatusBadge(
      status: priority,
      customColor: color,
      customIcon: icon,
      isCompact: isCompact,
    );
  }
}
