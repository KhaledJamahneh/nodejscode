import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class DioClient {
  static Dio? _dio;
  static bool _isRefreshing = false;
  static Future<String?>? _refreshTokenFuture;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  /// Call this after StorageService is cleared (e.g. on logout) so the next
  /// request re-creates a fresh Dio instance with no stale token.
  static void reset() => _dio = null;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    // FIX #10 — Only log in debug mode; never log sensitive tokens in release.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(responseBody: true, requestBody: true),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) => handler.next(response),
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final response = error.response;

          // Token refresh on 401 Unauthorized (proper HTTP semantics)
          // Avoids false triggers on role-based 403 Forbidden
          final isTokenError = response != null &&
              response.statusCode == 401;

          if (isTokenError &&
              path != ApiEndpoints.refreshToken &&
              path != ApiEndpoints.login) {
            if (!_isRefreshing) {
              _isRefreshing = true;
              _refreshTokenFuture = _performTokenRefresh();
            }

            final newAccessToken = await _refreshTokenFuture;

            if (newAccessToken != null) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await Dio(
                BaseOptions(
                  baseUrl: ApiConfig.baseUrl,
                  headers: opts.headers,
                ),
              ).fetch(opts);

              return handler.resolve(retryResponse);
            }
          }

          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Future<String?> _performTokenRefresh() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();

      if (refreshToken == null) {
        await StorageService.clearAll();
        return null;
      }

      final refreshResponse =
          await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (refreshResponse.statusCode == 200) {
        final newAccessToken = refreshResponse.data['data']['accessToken'];
        await StorageService.saveAccessToken(newAccessToken as String);
        return newAccessToken;
      }
    } catch (_) {
      await StorageService.clearAll();
    } finally {
      _isRefreshing = false;
      _refreshTokenFuture = null;
    }

    return null;
  }
}
