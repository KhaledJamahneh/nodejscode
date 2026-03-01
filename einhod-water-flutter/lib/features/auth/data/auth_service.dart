// lib/features/auth/data/auth_service.dart
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';

class AuthService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];

        // Save tokens
        await StorageService.saveAccessToken(data['accessToken']);
        await StorageService.saveRefreshToken(data['refreshToken']);

        // Save user data
        await StorageService.saveUserData(
          userId: data['user']['id'],
          username: data['user']['username'],
          role: data['user']['roles'] ?? data['user']['role'],
          fullName: data['user']['full_name'],
        );

        // Clear view override to force re-evaluation for the new user
        await StorageService.clearWorkerView();

        return data;
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Login failed');
      } else {
        throw Exception(
            'Cannot connect to server. Please check your internet connection.');
      }
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();

      await _dio.post(
        ApiEndpoints.logout,
        data: {'refreshToken': refreshToken},
      );
    } catch (e) {
      // Ignore logout errors as we clear local storage anyway
    } finally {
      await StorageService.clearAll();
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.me);
    return response.data['data'];
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<void> requestPasswordReset(String phoneNumber) async {
    await _dio.post(
      ApiEndpoints.passwordResetRequest,
      data: {'phone_number': phoneNumber},
    );
  }

  Future<void> verifyAndResetPassword({
    required String phoneNumber,
    required String verificationCode,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.passwordResetVerify,
      data: {
        'phone_number': phoneNumber,
        'verification_code': verificationCode,
        'new_password': newPassword,
      },
    );
  }

  Future<void> updateLanguage(String language) async {
    await _dio.put(
      'users/language',
      data: {'language': language},
    );
  }
}
