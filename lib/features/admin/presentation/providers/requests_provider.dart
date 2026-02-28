// lib/features/admin/presentation/providers/requests_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_service.dart';
import '../../data/models/request_model.dart';
import 'admin_provider.dart';

// Filter state
class RequestsFilter {
  final String? status;
  final String? priority;

  RequestsFilter({this.status, this.priority});

  RequestsFilter copyWith({
    String? status,
    String? priority,
    bool clearStatus = false,
    bool clearPriority = false,
  }) {
    return RequestsFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
    );
  }

  bool get hasFilters => status != null || priority != null;
}

// Filter provider
final requestsFilterProvider =
    StateProvider<RequestsFilter>((ref) => RequestsFilter());

// Requests list provider
final requestsListProvider = FutureProvider<List<DeliveryRequest>>((ref) async {
  final service = ref.read(adminServiceProvider);
  final filter = ref.watch(requestsFilterProvider);

  final requestsData = await service.getRequests(
    status: filter.status,
    priority: filter.priority,
    limit: 100,
  );

  return requestsData.map((data) => DeliveryRequest.fromJson(data)).toList();
});

// Assign worker provider
final assignWorkerProvider =
    StateNotifierProvider<AssignWorkerNotifier, AsyncValue<void>>((ref) {
  return AssignWorkerNotifier(ref.read(adminServiceProvider));
});

class AssignWorkerNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;

  AssignWorkerNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> assignWorker(int requestId, int workerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.assignWorker(requestId, workerId);
    });
  }
}

// Update request status provider
final updateRequestStatusProvider =
    StateNotifierProvider<UpdateRequestStatusNotifier, AsyncValue<void>>((ref) {
  return UpdateRequestStatusNotifier(ref.read(adminServiceProvider));
});

class UpdateRequestStatusNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;

  UpdateRequestStatusNotifier(this._service)
      : super(const AsyncValue.data(null));

  Future<void> updateStatus(int requestId, String status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateRequestStatus(requestId, status);
    });
  }
}

// Delete request provider
final deleteRequestProvider =
    StateNotifierProvider<DeleteRequestNotifier, AsyncValue<void>>((ref) {
  return DeleteRequestNotifier(ref.read(adminServiceProvider));
});

class DeleteRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;

  DeleteRequestNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> deleteRequest(int requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteRequest(requestId);
    });
  }
}

// Workers list for assignment
final workersListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(adminServiceProvider);
  final users = await service.getUsers(
      role: 'delivery_worker', isActive: true, limit: 50);
  return users;
});

// Coupon Book Requests Provider
final adminCouponBookRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(adminServiceProvider);
  return await service.getCouponBookRequests();
});

// Update Coupon Book Request Status Provider
final updateCouponBookRequestStatusProvider =
    StateNotifierProvider<UpdateCouponBookRequestStatusNotifier, AsyncValue<void>>((ref) {
  return UpdateCouponBookRequestStatusNotifier(ref.read(adminServiceProvider), ref);
});

class UpdateCouponBookRequestStatusNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;
  final Ref _ref;

  UpdateCouponBookRequestStatusNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> updateStatus(int requestId, String status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateCouponBookRequestStatus(requestId, status);
      _ref.invalidate(adminCouponBookRequestsProvider);
    });
  }
}

// Delete Coupon Book Request Provider
final deleteCouponRequestProvider =
    StateNotifierProvider<DeleteCouponRequestNotifier, AsyncValue<void>>((ref) {
  return DeleteCouponRequestNotifier(ref.read(adminServiceProvider), ref);
});

class DeleteCouponRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;
  final Ref _ref;

  DeleteCouponRequestNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> deleteRequest(int requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteCouponBookRequest(requestId);
      _ref.invalidate(adminCouponBookRequestsProvider);
    });
  }
}
