// lib/core/services/smart_defaults_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SmartDefaultsService {
  static const _historyKey = 'delivery_history';

  static Future<Map<String, dynamic>> predictDelivery() async {
    final history = await _getHistory();
    if (history.isEmpty) {
      return {'gallons': 100, 'priority': 'normal'};
    }

    // Calculate average
    final avgGallons = history.fold<int>(0, (sum, h) => sum + (h['gallons'] as int)) ~/ history.length;
    final mostCommonPriority = _mostCommon(history.map((h) => h['priority'] as String).toList());

    return {
      'gallons': avgGallons,
      'priority': mostCommonPriority,
    };
  }

  static Future<void> saveDelivery(Map<String, dynamic> delivery) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _getHistory();
    history.add(delivery);
    if (history.length > 10) history.removeAt(0); // Keep last 10
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  static Future<List<Map<String, dynamic>>> _getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static String _mostCommon(List<String> items) {
    if (items.isEmpty) return 'normal';
    final counts = <String, int>{};
    for (var item in items) {
      counts[item] = (counts[item] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static Future<DateTime?> predictNextDeliveryDate() async {
    final history = await _getHistory();
    if (history.length < 2) return null;

    // Calculate average days between deliveries
    final dates = history.map((h) => DateTime.parse(h['date'] as String)).toList()..sort();
    var totalDays = 0;
    for (var i = 1; i < dates.length; i++) {
      totalDays += dates[i].difference(dates[i - 1]).inDays;
    }
    final avgDays = totalDays ~/ (dates.length - 1);

    return dates.last.add(Duration(days: avgDays));
  }
}
