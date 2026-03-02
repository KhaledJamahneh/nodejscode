import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:einhod_water/l10n/app_localizations.dart';

enum ScheduleType { daily, weekly, biweekly, monthly, custom }

extension ScheduleTypeExt on ScheduleType {
  String get key => name;
  
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case ScheduleType.daily: return l10n.daily;
      case ScheduleType.weekly: return l10n.weekly;
      case ScheduleType.biweekly: return l10n.biweekly;
      case ScheduleType.monthly: return l10n.monthly;
      case ScheduleType.custom: return l10n.custom;
    }
  }

  static ScheduleType fromString(String value) {
    return ScheduleType.values.firstWhere(
      (e) => e.key == value,
      orElse: () => ScheduleType.custom,
    );
  }
}

class ScheduledDelivery {
  final int id;
  final List<int> clientIds;
  final int? workerId;
  final int gallons;
  final ScheduleType scheduleType;
  final String scheduleTime;
  final List<int>? scheduleDays;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? notes;
  final List<String> clientNames;
  final String? workerName;
  final int? frequencyPerWeek;
  final int? frequencyPerMonth;

  const ScheduledDelivery({
    required this.id,
    required this.clientIds,
    this.workerId,
    required this.gallons,
    required this.scheduleType,
    required this.scheduleTime,
    this.scheduleDays,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.notes,
    required this.clientNames,
    this.workerName,
    this.frequencyPerWeek,
    this.frequencyPerMonth,
  });

  String get clientName => clientNames.join(', ');

  String get repeatSummary {
    final days = _formattedDays;
    switch (scheduleType) {
      case ScheduleType.daily: return 'Every day';
      case ScheduleType.weekly: return days.isNotEmpty ? 'Every $days' : 'Weekly';
      case ScheduleType.biweekly: return days.isNotEmpty ? 'Every other $days' : 'Bi-weekly';
      case ScheduleType.monthly: return frequencyPerMonth != null ? '${frequencyPerMonth}× / month' : 'Monthly';
      case ScheduleType.custom: return 'Custom';
    }
  }

  String get _formattedDays {
    if (scheduleDays == null || scheduleDays!.isEmpty) return '';
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sorted = List<int>.from(scheduleDays!)..sort();
    return sorted.map((d) => d < names.length ? names[d] : '?').join(', ');
  }

  String get formattedTime {
    final parts = scheduleTime.split(':');
    if (parts.length < 2) return scheduleTime;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${hour12}:${m.toString().padLeft(2, '0')} $period';
  }

  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());

  String get statusLabel {
    if (isExpired) return 'Expired';
    return isActive ? 'Active' : 'Inactive';
  }

  factory ScheduledDelivery.fromJson(Map<String, dynamic> json) {
    return ScheduledDelivery(
      id: json['id'] as int,
      clientIds: List<int>.from(json['client_id'] as List),
      workerId: json['worker_id'] as int?,
      gallons: json['gallons'] as int,
      scheduleType: ScheduleTypeExt.fromString(json['schedule_type'] as String),
      scheduleTime: json['schedule_time'] as String,
      scheduleDays: json['schedule_days'] != null ? List<int>.from(json['schedule_days'] as List) : null,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      isActive: (json['is_active'] as bool?) ?? true,
      notes: json['notes'] as String?,
      clientNames: List<String>.from(json['client_names'] as List),
      workerName: json['worker_name'] as String?,
      frequencyPerWeek: json['frequency_per_week'] as int?,
      frequencyPerMonth: json['frequency_per_month'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'client_id': clientIds,
    if (workerId != null) 'worker_id': workerId,
    'gallons': gallons,
    'schedule_type': scheduleType.key,
    'schedule_time': scheduleTime,
    if (scheduleDays != null) 'schedule_days': scheduleDays,
    'start_date': DateFormat('yyyy-MM-dd').format(startDate),
    if (endDate != null) 'end_date': DateFormat('yyyy-MM-dd').format(endDate!),
    'is_active': isActive,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    if (frequencyPerWeek != null) 'frequency_per_week': frequencyPerWeek,
    if (frequencyPerMonth != null) 'frequency_per_month': frequencyPerMonth,
  };

  ScheduledDelivery copyWith({
    int? id,
    List<int>? clientIds,
    int? workerId,
    int? gallons,
    ScheduleType? scheduleType,
    String? scheduleTime,
    List<int>? scheduleDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? notes,
    List<String>? clientNames,
    String? workerName,
    int? frequencyPerWeek,
    int? frequencyPerMonth,
  }) {
    return ScheduledDelivery(
      id: id ?? this.id,
      clientIds: clientIds ?? this.clientIds,
      workerId: workerId ?? this.workerId,
      gallons: gallons ?? this.gallons,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      clientNames: clientNames ?? this.clientNames,
      workerName: workerName ?? this.workerName,
      frequencyPerWeek: frequencyPerWeek ?? this.frequencyPerWeek,
      frequencyPerMonth: frequencyPerMonth ?? this.frequencyPerMonth,
    );
  }
}
