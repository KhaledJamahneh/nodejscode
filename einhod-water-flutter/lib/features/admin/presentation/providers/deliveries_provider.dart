// lib/features/admin/presentation/providers/deliveries_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_model.dart';
import 'admin_provider.dart';

// Filter state
class DeliveriesFilter {
  final String? status;
  final int? workerId;
  final String? startDate;
  final String? endDate;

  DeliveriesFilter({this.status, this.workerId, this.startDate, this.endDate});

  DeliveriesFilter copyWith({
    String? status,
    int? workerId,
    String? startDate,
    String? endDate,
    bool clearStatus = false,
    bool clearWorker = false,
    bool clearDates = false,
  }) {
    return DeliveriesFilter(
      status: clearStatus ? null : (status ?? this.status),
      workerId: clearWorker ? null : (workerId ?? this.workerId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }

  bool get hasFilters => status != null || workerId != null || startDate != null;
}

// Filter provider
final deliveriesFilterProvider =
    StateProvider<DeliveriesFilter>((ref) => DeliveriesFilter());

// Deliveries list provider
final deliveriesListProvider = FutureProvider<List<Delivery>>((ref) async {
  final service = ref.read(adminServiceProvider);
  final filter = ref.watch(deliveriesFilterProvider);

  final deliveriesData = await service.getDeliveries(
    status: filter.status,
    workerId: filter.workerId,
    date: filter.startDate, // Use startDate for single date or range start
    limit: 100,
  );

  return deliveriesData.map((data) => Delivery.fromJson(data)).toList();
});

// Update delivery status provider
final updateDeliveryStatusProvider =
    StateNotifierProvider<UpdateDeliveryStatusNotifier, AsyncValue<void>>(
        (ref) {
  return UpdateDeliveryStatusNotifier(ref);
});

class UpdateDeliveryStatusNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  UpdateDeliveryStatusNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> updateStatus(int deliveryId, String status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = _ref.read(adminServiceProvider);
      await service.updateDeliveryStatus(deliveryId, status);
      // Invalidate the deliveries list to refresh
      _ref.invalidate(deliveriesListProvider);
    });
  }
}

// Assign worker to delivery provider
final assignWorkerToDeliveryProvider =
    StateNotifierProvider<AssignWorkerToDeliveryNotifier, AsyncValue<void>>(
        (ref) {
  return AssignWorkerToDeliveryNotifier(ref);
});

class AssignWorkerToDeliveryNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AssignWorkerToDeliveryNotifier(this._ref)
      : super(const AsyncValue.data(null));

  Future<void> assignWorker(int deliveryId, int workerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = _ref.read(adminServiceProvider);
      await service.assignWorkerToDelivery(deliveryId, workerId);
      _ref.invalidate(deliveriesListProvider);
    });
  }
}
