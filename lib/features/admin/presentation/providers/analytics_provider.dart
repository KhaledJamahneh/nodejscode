// lib/features/admin/presentation/providers/analytics_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_provider.dart';

class AnalyticsFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  AnalyticsFilter({this.startDate, this.endDate});

  AnalyticsFilter copyWith(
      {DateTime? startDate, DateTime? endDate, bool clear = false}) {
    if (clear) return AnalyticsFilter();
    return AnalyticsFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  bool get hasFilter => startDate != null && endDate != null;
}

final analyticsFilterProvider =
    StateProvider<AnalyticsFilter>((ref) => AnalyticsFilter());

final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(adminServiceProvider);
  final filter = ref.watch(analyticsFilterProvider);

  // Format dates for API if present
  String? startStr;
  String? endStr;

  if (filter.startDate != null) {
    startStr = filter.startDate!.toIso8601String().split('T')[0];
  }

  if (filter.endDate != null) {
    endStr = filter.endDate!.toIso8601String().split('T')[0];
  }

  return await service.getAnalytics(startDate: startStr, endDate: endStr);
});
