// lib/features/admin/presentation/providers/admin_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_service.dart';
import '../../data/models/dashboard_model.dart';
import 'users_provider.dart';

// Admin Service Provider
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

// Dashboard Provider
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final service = ref.read(adminServiceProvider);
  return await service.getDashboard();
});

// Requests Provider
final requestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
        (ref, status) async {
  final service = ref.read(adminServiceProvider);
  return await service.getRequests(status: status);
});

// Deliveries Provider
final deliveriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(adminServiceProvider);
  return await service.getDeliveries();
});

// Expenses Provider
final adminExpensesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.read(adminServiceProvider);
  return await service.getAllExpenses();
});


// Admin Operations Provider
class AdminOpsNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;
  final Ref _ref;

  AdminOpsNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<void> updateWorkerAdvance(int userId, double amount) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateWorkerAdvance(userId, amount);
      _ref.refresh(usersProvider);
    });
  }
}

final adminOpsProvider = StateNotifierProvider<AdminOpsNotifier, AsyncValue<void>>((ref) {
  return AdminOpsNotifier(ref.read(adminServiceProvider), ref);
});
