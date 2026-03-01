// lib/features/client/presentation/providers/client_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/client_service.dart';
import '../../data/models/client_request.dart';
import '../../data/models/client_models.dart';

// Client Service Provider
final clientServiceProvider = Provider<ClientService>((ref) {
  return ClientService();
});

// Client Requests Provider
final clientRequestsProvider = FutureProvider<List<ClientRequest>>((ref) async {
  final service = ref.read(clientServiceProvider);
  final requestsData = await service.getRequests(limit: 100);
  return requestsData.map((data) => ClientRequest.fromJson(data)).toList();
});

// Active In-Progress Request Provider
final activeInProgressRequestProvider = Provider<ClientRequest?>((ref) {
  final requestsAsync = ref.watch(clientRequestsProvider);
  return requestsAsync.when(
    data: (requests) {
      try {
        return requests.firstWhere((r) => r.status == 'in_progress');
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Client Profile Provider
final clientProfileProvider = FutureProvider<ClientProfile>((ref) async {
  final service = ref.read(clientServiceProvider);
  final data = await service.getProfile();
  return ClientProfile.fromJson(data);
});

// Usage History Provider
final clientUsageProvider = FutureProvider<UsageHistory>((ref) async {
  final service = ref.read(clientServiceProvider);
  final data = await service.getUsageHistory();
  return UsageHistory.fromJson(data);
});

// Corrected Assets Provider
final clientAssetsListProvider = FutureProvider<List<ClientAsset>>((ref) async {
  final service = ref.read(clientServiceProvider);
  final data = await service.getAssets();
  return data.map((item) => ClientAsset.fromJson(item)).toList();
});

// Debt Info Provider
final clientDebtProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(clientServiceProvider);
  return await service.getDebtInfo();
});

// Coupon Sizes Provider
final couponSizesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(clientServiceProvider);
  return await service.getCouponSizes();
});

// Cancel Request Notifier
class CancelRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final ClientService _service;
  final Ref _ref;

  CancelRequestNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> cancelRequest(int requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.cancelRequest(requestId);
      // Invalidate the requests list to refresh after cancellation
      _ref.invalidate(clientRequestsProvider);
    });
  }
}

// Cancel Request Provider
final cancelRequestProvider =
    StateNotifierProvider<CancelRequestNotifier, AsyncValue<void>>((ref) {
  return CancelRequestNotifier(ref.read(clientServiceProvider), ref);
});

// Update Client Profile Notifier
class UpdateClientProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final ClientService _service;
  final Ref _ref;

  UpdateClientProfileNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateProfile(data);
      // Invalidate profile to refresh
      _ref.invalidate(clientProfileProvider);
    });
  }
}

// Update Client Profile Provider
final updateClientProfileProvider =
    StateNotifierProvider<UpdateClientProfileNotifier, AsyncValue<void>>((ref) {
  return UpdateClientProfileNotifier(ref.read(clientServiceProvider), ref);
});

// Create Request Notifier
class CreateRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final ClientService _service;
  final Ref _ref;

  CreateRequestNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> createRequest(int gallons, String? notes) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.createRequest(
        requestedGallons: gallons,
        paymentMethod: 'cash', // Default payment method
        notes: notes,
      );
      _ref.invalidate(clientRequestsProvider);
    });
  }
}

final createRequestProvider =
    StateNotifierProvider<CreateRequestNotifier, AsyncValue<void>>((ref) {
  return CreateRequestNotifier(ref.read(clientServiceProvider), ref);
});

// Coupon Book Requests Notifier
class CouponBookRequestsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final ClientService _service;
  final Ref _ref;

  CouponBookRequestsNotifier(this._service, this._ref)
      : super(const AsyncValue.loading()) {
    loadRequests();
  }

  Future<void> loadRequests() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.getCouponBookRequests());
  }

  Future<void> requestCouponBook(int sizeId, String bookType, String paymentMethod) async {
    await _service.createCouponBookRequest(
      bookType: bookType,
      couponSizeId: sizeId,
      paymentMethod: paymentMethod,
    );
    await loadRequests();
    // Refresh profile to get updated coupon balance
    _ref.invalidate(clientProfileProvider);
  }

  Future<void> deleteCouponBookRequest(int requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteCouponBookRequest(requestId);
      await loadRequests();
    });
  }
}

final couponBookRequestsProvider =
    StateNotifierProvider<CouponBookRequestsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return CouponBookRequestsNotifier(ref.read(clientServiceProvider), ref);
});
