// lib/features/admin/presentation/providers/users_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_service.dart';
import '../../data/models/user_model.dart';
import 'admin_provider.dart';

// Filter state
class UsersFilter {
  final String? role;
  final bool? isActive;
  final String? search;
  final bool? onShift;
  final String? paymentMethod; // 'coupons' or 'cash'
  final String? couponSize; // 'small', 'medium', 'large'

  UsersFilter({
    this.role,
    this.isActive,
    this.search,
    this.onShift,
    this.paymentMethod,
    this.couponSize,
  });

  UsersFilter copyWith({
    String? role,
    bool? isActive,
    String? search,
    bool? onShift,
    String? paymentMethod,
    String? couponSize,
    bool clearRole = false,
    bool clearActive = false,
    bool clearSearch = false,
    bool clearOnShift = false,
    bool clearPaymentMethod = false,
    bool clearCouponSize = false,
  }) {
    return UsersFilter(
      role: clearRole ? null : (role ?? this.role),
      isActive: clearActive ? null : (isActive ?? this.isActive),
      search: clearSearch ? null : (search ?? this.search),
      onShift: clearOnShift ? null : (onShift ?? this.onShift),
      paymentMethod: clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      couponSize: clearCouponSize ? null : (couponSize ?? this.couponSize),
    );
  }
}

// Filter provider
final usersFilterProvider = StateProvider<UsersFilter>((ref) => UsersFilter());

// Users list provider
final usersProvider = FutureProvider<List<User>>((ref) async {
  final service = ref.read(adminServiceProvider);
  final filter = ref.watch(usersFilterProvider);

  final usersData = await service.getUsers(
    role: filter.paymentMethod != null || filter.couponSize != null 
        ? 'client' 
        : filter.role,
    isActive: filter.onShift == true ? true : filter.isActive,
    search: filter.search,
    onShift: filter.onShift,
    paymentMethod: filter.paymentMethod,
    couponSize: filter.couponSize,
    limit: 10000,
  );

  return usersData.map((data) => User.fromJson(data)).toList();

// Available workers provider (for assignment)
final availableWorkersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(adminServiceProvider);
  final usersData = await service.getUsers(role: 'delivery_worker', isActive: true, limit: 100);
  return usersData;
});
});

// Coupon sizes provider
final couponSizesProvider = FutureProvider<List<int>>((ref) async {
  final service = ref.read(adminServiceProvider);
  final sizes = await service.getCouponSizes();
  return sizes.map<int>((s) => s['size'] as int).toList();
});

// User details provider
final userDetailsProvider =
    FutureProvider.family<User, int>((ref, userId) async {
  final service = ref.read(adminServiceProvider);
  final userData = await service.getUserDetails(userId);
  return User.fromJson(userData);
});

// Create user provider
final createUserProvider =
    StateNotifierProvider<CreateUserNotifier, AsyncValue<void>>((ref) {
  return CreateUserNotifier(ref.read(adminServiceProvider));
});

class CreateUserNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;

  CreateUserNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> createUser(Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.createUser(userData);
    });
  }
}

// Update user provider
final updateUserProvider =
    StateNotifierProvider<UpdateUserNotifier, AsyncValue<void>>((ref) {
  return UpdateUserNotifier(ref.read(adminServiceProvider), ref);
});

class UpdateUserNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;
  final Ref _ref;

  UpdateUserNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> updateUser(int userId, Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.updateUser(userId, userData);
      // Invalidate to refresh data
      _ref.invalidate(usersProvider);
      _ref.invalidate(userDetailsProvider(userId));
    });
  }
}

// Toggle active provider
final toggleUserActiveProvider =
    StateNotifierProvider<ToggleUserActiveNotifier, AsyncValue<void>>((ref) {
  return ToggleUserActiveNotifier(ref.read(adminServiceProvider));
});

class ToggleUserActiveNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;

  ToggleUserActiveNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> toggleActive(int userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.toggleUserActive(userId);
    });
  }
}

// Delete user provider
final deleteUserProvider =
    StateNotifierProvider<DeleteUserNotifier, AsyncValue<void>>((ref) {
  return DeleteUserNotifier(ref.read(adminServiceProvider));
});

class DeleteUserNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminService _service;

  DeleteUserNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> deleteUser(int userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.deleteUser(userId);
    });
  }
}
