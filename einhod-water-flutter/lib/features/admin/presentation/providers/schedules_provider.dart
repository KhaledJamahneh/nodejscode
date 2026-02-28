import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_service.dart';
import '../../data/models/schedule_model.dart';
import '../providers/admin_provider.dart';

// ── Data Provider ─────────────────────────────────────────────────────────────
final schedulesProvider = StateNotifierProvider<SchedulesNotifier, AsyncValue<List<ScheduledDelivery>>>((ref) {
  return SchedulesNotifier(ref);
});

class SchedulesNotifier extends StateNotifier<AsyncValue<List<ScheduledDelivery>>> {
  final Ref ref;

  SchedulesNotifier(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  AdminService get _service => ref.read(adminServiceProvider);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.getSchedules();
      state = AsyncValue.data(data.map((e) => ScheduledDelivery.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _service.createSchedule(payload);
    await load();
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    await _service.updateSchedule(id, payload);
    await load();
  }

  Future<void> toggleActive(ScheduledDelivery schedule) async {
    final prev = state.valueOrNull;
    if (prev != null) {
      state = AsyncData(prev.map((s) => s.id == schedule.id ? s.copyWith(isActive: !s.isActive) : s).toList());
    }
    try {
      await update(schedule.id, {'is_active': !schedule.isActive});
    } catch (e) {
      if (prev != null) state = AsyncData(prev);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    await _service.deleteSchedule(id);
    await load();
  }

  Future<void> batchDelete(List<int> ids) async {
    await _service.batchDeleteSchedules(ids);
    await load();
  }
}

// ── Filter State ──────────────────────────────────────────────────────────────
class ScheduleFilter {
  final String search;
  final ScheduleType? type;
  final bool? active;
  final DateTime? startDate;
  final DateTime? endDate;

  const ScheduleFilter({this.search = '', this.type, this.active, this.startDate, this.endDate});

  ScheduleFilter copyWith({
    String? search, 
    ScheduleType? type, 
    bool? active, 
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false, 
    bool clearActive = false,
    bool clearDates = false,
  }) {
    return ScheduleFilter(
      search: search ?? this.search,
      type: clearType ? null : (type ?? this.type),
      active: clearActive ? null : (active ?? this.active),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }

  bool get hasFilters => search.isNotEmpty || type != null || active != null || startDate != null;
}

final scheduleFilterProvider = StateProvider<ScheduleFilter>((ref) => const ScheduleFilter());

// ── Filtered List ─────────────────────────────────────────────────────────────
final filteredSchedulesProvider = Provider<AsyncValue<List<ScheduledDelivery>>>((ref) {
  final schedulesAsync = ref.watch(schedulesProvider);
  final filter = ref.watch(scheduleFilterProvider);

  return schedulesAsync.whenData((schedules) {
    var list = schedules;

    if (filter.search.isNotEmpty) {
      final q = filter.search.toLowerCase();
      list = list.where((s) =>
        s.clientName.toLowerCase().contains(q) ||
        (s.workerName?.toLowerCase().contains(q) ?? false) ||
        (s.notes?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    if (filter.type != null) {
      list = list.where((s) => s.scheduleType == filter.type).toList();
    }

    if (filter.active != null) {
      list = list.where((s) => s.isActive == filter.active).toList();
    }

    if (filter.startDate != null) {
      final start = filter.startDate!;
      final end = filter.endDate ?? start;
      
      list = list.where((s) {
        if (!s.isActive) return false;
        
        // Check each day in the range
        for (var date = start; date.isBefore(end.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
          final dayOfWeek = date.weekday % 7;
          
          switch (s.scheduleType) {
            case ScheduleType.daily:
              return true;
            case ScheduleType.weekly:
            case ScheduleType.biweekly:
              if (s.scheduleDays?.contains(dayOfWeek) ?? false) return true;
              break;
            case ScheduleType.monthly:
              if (date.day == s.startDate.day) return true;
              break;
            case ScheduleType.custom:
              return true;
          }
        }
        return false;
      }).toList();
    }

    list.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.clientName.compareTo(b.clientName);
    });

    return list;
  });
});

// ── Stats ─────────────────────────────────────────────────────────────────────
class ScheduleStats {
  final int total;
  final int active;
  final int weeklyGallons;
  final double avgGallonsPerClient;

  const ScheduleStats({
    required this.total,
    required this.active,
    required this.weeklyGallons,
    required this.avgGallonsPerClient,
  });
}

final scheduleStatsProvider = Provider<ScheduleStats>((ref) {
  final schedules = ref.watch(schedulesProvider).valueOrNull ?? [];
  final active = schedules.where((s) => s.isActive).toList();

  int weeklyGallons = 0;
  for (final s in active) {
    switch (s.scheduleType) {
      case ScheduleType.daily: weeklyGallons += s.gallons * 7; break;
      case ScheduleType.weekly: weeklyGallons += s.gallons * (s.scheduleDays?.length ?? 1); break;
      case ScheduleType.biweekly: weeklyGallons += (s.gallons * (s.scheduleDays?.length ?? 1) / 2).round(); break;
      case ScheduleType.monthly: weeklyGallons += (s.gallons * (s.frequencyPerMonth ?? 4) / 4).round(); break;
      case ScheduleType.custom: 
        // Custom: (gallons * times) / (interval_days / 7)
        if (s.frequencyPerWeek != null && s.frequencyPerMonth != null) {
          final totalGallons = s.gallons * s.frequencyPerMonth!;
          final weeks = s.frequencyPerWeek! / 7;
          weeklyGallons += (totalGallons / weeks).round();
        }
        break;
    }
  }

  final avgPerClient = active.isEmpty ? 0.0 : weeklyGallons / active.length;

  return ScheduleStats(
    total: schedules.length,
    active: active.length,
    weeklyGallons: weeklyGallons,
    avgGallonsPerClient: avgPerClient,
  );
});
