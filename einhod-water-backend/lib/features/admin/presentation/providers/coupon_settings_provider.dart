// lib/features/admin/presentation/providers/coupon_settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_service.dart';
import 'admin_provider.dart';

final adminCouponSizesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(adminServiceProvider);
  return await service.getCouponSizes();
});

final updateCouponSizeProvider = StateNotifierProvider<UpdateCouponSizeNotifier, AsyncValue<void>>((ref) {
  return UpdateCouponSizeNotifier(ref.read(adminServiceProvider));
});

class UpdateCouponSizeNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;

  UpdateCouponSizeNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> updateSize(int id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.updateCouponSize(id, data));
  }
}
