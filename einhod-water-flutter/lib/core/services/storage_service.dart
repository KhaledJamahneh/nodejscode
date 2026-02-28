// lib/core/services/storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/worker/data/models/worker_models.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();

  // Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _fullNameKey = 'full_name';
  static const String _roleKey = 'role';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _localeKey = 'locale';
  static const String _workerViewKey = 'active_worker_view';
  static const String _themeModeKey = 'theme_mode';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme Management
  static Future<void> setThemeMode(bool isDark) async {
    await _prefs.setBool(_themeModeKey, isDark);
  }

  static bool getThemeMode() => _prefs.getBool(_themeModeKey) ?? false;

  // View Management
  static Future<void> saveWorkerView(String view) async {
    await _prefs.setString(_workerViewKey, view);
  }

  static String? getWorkerView() => _prefs.getString(_workerViewKey);

  static Future<void> clearWorkerView() async {
    await _prefs.remove(_workerViewKey);
  }

  // Locale Management
  static Future<void> saveLocale(String languageCode) async {
    await _prefs.setString(_localeKey, languageCode);
  }

  static String? getLocale() => _prefs.getString(_localeKey);

  // Token Management
  static Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  // User Data
  static Future<void> saveUserData({
    required int userId,
    required String username,
    required dynamic role,
    String? fullName,
  }) async {
    await _prefs.setInt(_userIdKey, userId);
    await _prefs.setString(_usernameKey, username);
    if (fullName != null) await _prefs.setString(_fullNameKey, fullName);

    String roleToSave = '';
    if (role is List) {
      roleToSave = role.join(',');
    } else {
      roleToSave = role.toString();
    }

    await _prefs.setString(_roleKey, roleToSave);
    await _prefs.setBool(_isLoggedInKey, true);
  }

  static int? getUserId() => _prefs.getInt(_userIdKey);
  static String? getUsername() => _prefs.getString(_usernameKey);
  static String? getFullName() => _prefs.getString(_fullNameKey);
  static String? getRole() => _prefs.getString(_roleKey);

  static List<String> getRoles() {
    final roleStr = _prefs.getString(_roleKey);
    if (roleStr == null || roleStr.isEmpty) return [];
    return roleStr.split(',').map((r) => r.trim().toLowerCase()).toList();
  }

  static bool hasRole(String role) {
    final roles = getRoles();
    final r = role.toLowerCase().trim();

    if (r == 'admin' || r == 'administrator') {
      return roles.contains('admin') ||
          roles.contains('administrator') ||
          roles.contains('owner');
    }

    if (r == 'worker') {
      return roles.contains('worker') ||
          roles.contains('delivery_worker') ||
          roles.contains('onsite_worker');
    }

    return roles.contains(r);
  }

  static bool hasAnyRole(List<String> rolesToCheck) {
    return rolesToCheck.any((r) => hasRole(r));
  }

  static bool isAdmin() => hasRole('admin') || hasRole('owner');
  static bool isWorker() => hasRole('worker');
  static bool isClient() => hasRole('client');

  static bool isLoggedIn() => _prefs.getBool(_isLoggedInKey) ?? false;

  // Logout
  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }

  // ─── Reliable Worker View Helpers (fixes Gemini issue) ─────────────────
  static WorkerViewType getPreferredWorkerView() {
    final saved = getWorkerView();
    if (saved != null) {
      return saved == 'onsite'
          ? WorkerViewType.onsite
          : WorkerViewType.delivery;
    }

    final roles = getRoles();
    if (roles.contains('onsite_worker') ||
        roles.contains('station_worker') ||
        roles.contains('fill_worker')) {
      return WorkerViewType.onsite;
    }
    if (roles.contains('delivery_worker') || roles.contains('driver')) {
      return WorkerViewType.delivery;
    }
    return WorkerViewType.delivery;
  }

  static bool isOnsiteWorker() =>
      getPreferredWorkerView() == WorkerViewType.onsite;
  static bool isDeliveryWorker() =>
      getPreferredWorkerView() == WorkerViewType.delivery;
}
