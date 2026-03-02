// lib/features/worker/presentation/providers/worker_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/worker_service.dart';
import '../../data/models/worker_models.dart';

final workerServiceProvider = Provider<WorkerService>((ref) {
  return WorkerService();
});

final workerProfileProvider = FutureProvider<WorkerProfile>((ref) async {
  final service = ref.read(workerServiceProvider);
  final data = await service.getProfile();
  return WorkerProfile.fromJson(data);
});

final workerScheduleProvider =
    FutureProvider<List<WorkerDelivery>>((ref) async {
  final service = ref.read(workerServiceProvider);
  final data = await service.getMainSchedule();
  return data.map((e) => WorkerDelivery.fromJson(e)).toList();
});

final workerRequestsProvider = FutureProvider<List<WorkerRequest>>((ref) async {
  final service = ref.read(workerServiceProvider);
  final data = await service.getSecondaryList();
  return data.map((e) => WorkerRequest.fromJson(e)).toList();
});

final fillingStationsProvider =
    FutureProvider<List<FillingStation>>((ref) async {
  final service = ref.read(workerServiceProvider);
  final data = await service.getFillingStations();
  return data.map((e) => FillingStation.fromJson(e)).toList();
});

final recentFillingSessionsProvider =
    FutureProvider<List<FillingSession>>((ref) async {
  final service = ref.read(workerServiceProvider);
  final data = await service.getRecentFillingSessions();
  return data.map((e) => FillingSession.fromJson(e)).toList();
});

final stationStatusProvider =
    StateProvider<StationStatus>((ref) => StationStatus.open);

final activeFillingSessionProvider = StateProvider<int?>((ref) => null);

final workerExpensesProvider = StateNotifierProvider<WorkerExpensesNotifier, List<WorkerExpense>>((ref) {
  return WorkerExpensesNotifier(ref.read(workerServiceProvider));
});

class WorkerExpensesNotifier extends StateNotifier<List<WorkerExpense>> {
  final WorkerService _service;

  WorkerExpensesNotifier(this._service) : super([]) {
    print('WorkerExpensesNotifier created');
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    try {
      final data = await _service.getExpenses();
      print('Loaded expenses: ${data.length} items');
      print('Raw data: $data');
      state = data.map((e) => WorkerExpense.fromJson(e)).toList();
      print('Parsed expenses: ${state.length} items');
    } catch (e) {
      print('Error loading expenses: $e');
      // Keep empty state if backend fails
      state = [];
    }
  }

  Future<void> refresh() async {
    await _loadExpenses();
  }

  Future<void> addExpense(Map<String, dynamic> data) async {
    await _service.submitExpense(data);
    await _loadExpenses();
  }

  Future<void> updateExpense(int id, Map<String, dynamic> data) async {
    await _service.updateExpense(id, data);
    await _loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _service.deleteExpense(id);
    await _loadExpenses();
  }
}

// Operations Notifiers
class WorkerOpsNotifier extends StateNotifier<AsyncValue<void>> {
  final WorkerService _service;
  final Ref _ref;

  WorkerOpsNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  void invalidateAll() {
    _ref.invalidate(workerProfileProvider);
    _ref.invalidate(workerScheduleProvider);
    _ref.invalidate(workerRequestsProvider);
    _ref.invalidate(fillingStationsProvider);
    _ref.invalidate(recentFillingSessionsProvider);
  }

  Future<void> updateStationStatus(int stationId, String status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateStationStatus(stationId, status);

      StationStatus statusEnum = StationStatus.open;
      if (status == 'temporarilyClosed')
        statusEnum = StationStatus.temporarilyClosed;
      if (status == 'closedUntilTomorrow')
        statusEnum = StationStatus.closedUntilTomorrow;

      _ref.read(stationStatusProvider.notifier).state = statusEnum;
      _ref.invalidate(fillingStationsProvider);
    });
  }

  Future<void> startDelivery(int deliveryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.startDelivery(deliveryId);
      _ref.invalidate(workerScheduleProvider);
    });
  }

  Future<void> acceptDelivery(int deliveryId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.acceptDelivery(deliveryId);
      _ref.invalidate(workerRequestsProvider);
      _ref.invalidate(workerScheduleProvider);
    });
  }

  /// FIX: now accepts paid_coupons_count and empty_gallons_returned
  Future<void> completeDelivery(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _service.completeDelivery(
          deliveryId: data['delivery_id'],
          gallonsDelivered: data['gallons_delivered'],
          emptyGallonsReturned: data['empty_gallons_returned'],
          latitude: data['latitude'],
          longitude: data['longitude'],
          notes: data['notes'],
          paidAmount: data['paid_amount'],
          totalPrice: data['total_price'],
        );
        _ref.invalidate(workerScheduleProvider);
        _ref.invalidate(workerProfileProvider);
      } catch (e) {
        print('❌ Complete Delivery Error: $e');
        if (e is DioException) {
          print('Response data: ${e.response?.data}');
          print('Status code: ${e.response?.statusCode}');
        }
        rethrow;
      }
    });
  }

  Future<void> acceptRequest(int requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.acceptRequest(requestId);
      _ref.invalidate(workerRequestsProvider);
      _ref.invalidate(workerScheduleProvider);
    });
  }

  /// FIX: now accepts paid_coupons_count and empty_gallons_returned
  Future<void> completeRequest(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.completeRequest(
        requestId: data['request_id'],
        gallonsDelivered: data['gallons_delivered'],
        emptyGallonsReturned: data['empty_gallons_returned'],
        latitude: data['latitude'],
        longitude: data['longitude'],
        notes: data['notes'],
        // FIX: pass paid_coupons_count if present
        paidCouponsCount: data['paid_coupons_count'],
        paidAmount: data['paid_amount'],
        totalPrice: data['total_price'],
      );
      _ref.invalidate(workerRequestsProvider);
      _ref.invalidate(workerScheduleProvider);
      _ref.invalidate(workerProfileProvider);
    });
  }

  Future<void> updateInventory(int gallons) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateInventory(gallons);
      _ref.invalidate(workerProfileProvider);
    });
  }

  Future<void> toggleGPS(bool enabled) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.toggleGPS(enabled);
      _ref.invalidate(workerProfileProvider);
    });
  }

  // On-site Operations
  Future<void> startFillingSession(int stationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final sessionData = await _service.startFillingSession(stationId);
      _ref.read(activeFillingSessionProvider.notifier).state = sessionData['id'];
      _ref.invalidate(recentFillingSessionsProvider);
    });
  }

  Future<void> completeFillingSession(int sessionId, int gallons) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.completeFillingSession(
        sessionId: sessionId,
        gallonsFilled: gallons,
      );
      _ref.read(activeFillingSessionProvider.notifier).state = null;
      _ref.invalidate(recentFillingSessionsProvider);
      _ref.invalidate(workerProfileProvider);
    });
  }

  Future<void> updateFillingSession(int sessionId, int gallons) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateFillingSession(
        sessionId: sessionId,
        gallonsFilled: gallons,
      );
      _ref.invalidate(recentFillingSessionsProvider);
    });
  }

  Future<void> deleteFillingSession(int sessionId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteFillingSession(sessionId);
      _ref.invalidate(recentFillingSessionsProvider);
    });
  }

  Future<void> submitExpense(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(workerExpensesProvider.notifier).addExpense(data);
    });
  }

  Future<void> updateExpense(int id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(workerExpensesProvider.notifier).updateExpense(id, data);
    });
  }

  Future<void> deleteExpense(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(workerExpensesProvider.notifier).deleteExpense(id);
    });
  }
}

final workerOpsProvider =
    StateNotifierProvider<WorkerOpsNotifier, AsyncValue<void>>((ref) {
  return WorkerOpsNotifier(ref.read(workerServiceProvider), ref);
});
