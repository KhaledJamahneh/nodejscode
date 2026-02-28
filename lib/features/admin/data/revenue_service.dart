import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/storage_service.dart';
import '../../../core/config/api_config.dart';

class RevenueService {
  static Future<Map<String, dynamic>> getRevenueData(DateTime startDate, DateTime endDate) async {
    final token = await StorageService.getAccessToken();
    if (token == null) throw Exception('No auth token');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}admin/revenues').replace(queryParameters: {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      }),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load revenue data');
    }
  }
}
