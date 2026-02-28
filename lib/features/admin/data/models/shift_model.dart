// lib/features/admin/data/models/shift_model.dart
import 'package:flutter/material.dart';
import 'package:einhod_water/l10n/app_localizations.dart';

class WorkShift {
  final int id;
  final String name;
  final List<int> daysOfWeek; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final String startTime; // HH:mm:ss
  final String endTime;
  final bool isActive;

  WorkShift({
    required this.id,
    required this.name,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory WorkShift.fromJson(Map<String, dynamic> json) {
    return WorkShift(
      id: json['id'],
      name: json['name'],
      daysOfWeek: List<int>.from(json['days_of_week'] ?? []),
      startTime: json['start_time'],
      endTime: json['end_time'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'days_of_week': daysOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
    };
  }

  String get daysDisplay {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return daysOfWeek.map((d) => days[d]).join(', ');
  }

  String daysDisplayLocalized(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = [l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat];
    return daysOfWeek.map((d) => days[d]).join(', ');
  }

  String timeDisplay([String? locale]) => 
      '${_formatTime(startTime, locale)} - ${_formatTime(endTime, locale)}';

  String _formatTime(String time, [String? locale]) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final isArabic = locale == 'ar';
    final period = hour >= 12 
        ? (isArabic ? 'م' : 'PM') 
        : (isArabic ? 'ص' : 'AM');
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class WorkerLeave {
  final int id;
  final int userId;
  final String leaveType; // vacation, sick_leave, other
  final String startDate;
  final String endDate;
  final String? reason;
  final String? username;

  WorkerLeave({
    required this.id,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.username,
  });

  factory WorkerLeave.fromJson(Map<String, dynamic> json) {
    return WorkerLeave(
      id: json['id'],
      userId: json['user_id'],
      leaveType: json['leave_type'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      reason: json['reason'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      if (reason != null) 'reason': reason,
    };
  }

  String get typeDisplay {
    switch (leaveType) {
      case 'vacation':
        return 'Vacation';
      case 'sick_leave':
        return 'Sick Leave';
      default:
        return 'Other';
    }
  }

  bool get isActive {
    final now = DateTime.now();
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    return now.isAfter(start.subtract(const Duration(days: 1))) && 
           now.isBefore(end.add(const Duration(days: 1)));
  }
}
