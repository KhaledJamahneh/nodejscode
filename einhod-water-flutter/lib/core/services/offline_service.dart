// lib/core/services/offline_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService {
  static final _connectivity = Connectivity();
  static const _queueKey = 'offline_queue';
  static const _cachePrefix = 'cache_';

  static Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged.map((r) => r != ConnectivityResult.none);

  static Future<void> queueAction(Map<String, dynamic> action) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();
    queue.add(action);
    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_queueKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  static Future<void> cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefix$key', jsonEncode(data));
  }

  static Future<dynamic> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_cachePrefix$key');
    return data != null ? jsonDecode(data) : null;
  }
}
