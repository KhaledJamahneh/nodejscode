// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_service.dart';
import '../../../worker/presentation/providers/worker_provider.dart';
import '../../../../core/providers/locale_provider.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current User Provider
final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(authServiceProvider);
  return await service.getCurrentUser();
});

// Login State Provider
final loginProvider =
    StateNotifierProvider<LoginNotifier, AsyncValue<void>>((ref) {
  return LoginNotifier(ref.read(authServiceProvider), ref);
});

class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  LoginNotifier(this._authService, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final data = await _authService.login(username, password);
      
      // Sync language from backend (single source of truth)
      final preferredLanguage = data['user']['preferred_language'] ?? 'en';
      _ref.read(localeProvider.notifier).setLocale(Locale(preferredLanguage));
      
      // Invalidate worker data after login to ensure fresh data for the new user
      _ref.read(workerOpsProvider.notifier).invalidateAll();
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _authService.logout();
      // Clear worker data on logout
      _ref.read(workerOpsProvider.notifier).invalidateAll();
      // Invalidate all providers to clear cached data
      _ref.invalidate(currentUserProvider);
    });
  }
}

// Change Password Notifier
class ChangePasswordNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  ChangePasswordNotifier(this._authService)
      : super(const AsyncValue.data(null));

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }
}

final changePasswordProvider =
    StateNotifierProvider<ChangePasswordNotifier, AsyncValue<void>>((ref) {
  return ChangePasswordNotifier(ref.read(authServiceProvider));
});

// Password Reset Notifier
class PasswordResetNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  PasswordResetNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> requestReset(String phoneNumber) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.requestPasswordReset(phoneNumber));
  }

  Future<void> verifyAndReset({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.verifyAndResetPassword(
      phoneNumber: phoneNumber,
      verificationCode: code,
      newPassword: newPassword,
    ));
  }
}

final passwordResetProvider =
    StateNotifierProvider<PasswordResetNotifier, AsyncValue<void>>((ref) {
  return PasswordResetNotifier(ref.read(authServiceProvider));
});
