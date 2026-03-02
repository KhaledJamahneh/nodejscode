// lib/features/admin/data/admin_service.dart
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/config/api_config.dart';
import 'models/dashboard_model.dart';

class AdminService {
  Dio get _dio => DioClient.instance;

  Future<DashboardData> getDashboard() async {
    final response = await _dio.get(ApiEndpoints.adminDashboard);
    return DashboardData.fromJson(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> getRequests({
    String? status,
    String? priority,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.adminRequests,
      queryParameters: {
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        'limit': limit,
        'offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(response.data['data']['requests']);
  }

  Future<void> assignWorker(int requestId, int workerId) async {
    await _dio.post(
      '${ApiEndpoints.assignWorker}/$requestId/assign',
      data: {'worker_id': workerId},
    );
  }

  Future<void> updateRequestStatus(int requestId, String status) async {
    await _dio.patch(
      '${ApiEndpoints.adminRequests}/$requestId/status',
      data: {'status': status},
    );
  }

  Future<void> updateDeliveryStatus(int deliveryId, String status) async {
    await _dio.patch(
      '${ApiEndpoints.adminDeliveries}/$deliveryId/status',
      data: {'status': status},
    );
  }

  Future<void> assignWorkerToDelivery(int deliveryId, int workerId) async {
    await _dio.post(
      '${ApiEndpoints.adminDeliveries}/$deliveryId/assign',
      data: {'worker_id': workerId},
    );
  }

  Future<void> deleteRequest(int requestId) async {
    await _dio.delete('${ApiEndpoints.adminRequests}/$requestId');
  }

  Future<void> deleteDelivery(int deliveryId) async {
    await _dio.delete('${ApiEndpoints.adminDeliveries}/$deliveryId');
  }

  Future<void> createQuickDelivery(Map<String, dynamic> data) async {
    await _dio.post('${ApiEndpoints.adminDeliveries}/quick', data: data);
  }

  Future<void> updateDelivery(int deliveryId, Map<String, dynamic> data) async {
    await _dio.patch('${ApiEndpoints.adminDeliveries}/$deliveryId', data: data);
  }

  Future<List<Map<String, dynamic>>> getDeliveries({
    String? status,
    int? workerId,
    String? date,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.adminDeliveries,
      queryParameters: {
        if (status != null) 'status': status,
        if (workerId != null) 'worker_id': workerId,
        if (date != null) 'date': date,
        'limit': limit,
        'offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(response.data['data']['deliveries']);
  }

  Future<List<Map<String, dynamic>>> getUsers({
    String? role,
    bool? isActive,
    String? search,
    bool? onShift,
    String? paymentMethod,
    String? couponSize,
    int limit = 1000,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.adminUsers,
      queryParameters: {
        if (role != null) 'role': role,
        if (isActive != null) 'is_active': isActive.toString(),
        if (search != null) 'search': search,
        if (onShift != null) 'on_shift': onShift.toString(),
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (couponSize != null) 'coupon_size': couponSize,
        'limit': limit,
        'offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(response.data['data']['users']);
  }

  Future<Map<String, dynamic>> getUserDetails(int userId) async {
    final response = await _dio.get('${ApiEndpoints.adminUsers}/$userId');
    return response.data['data'];
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    await _dio.post(
      ApiEndpoints.adminUsers,
      data: userData,
    );
  }

  Future<void> updateUser(int userId, Map<String, dynamic> userData) async {
    await _dio.patch(
      '${ApiEndpoints.adminUsers}/$userId',
      data: userData,
    );
  }

  Future<List<Map<String, dynamic>>> getCouponSizes() async {
    final response = await _dio.get('${ApiConfig.baseUrl}admin/coupon-sizes');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<void> createCouponSize(int size) async {
    await _dio.post(ApiEndpoints.adminCouponSizes, data: {'size': size});
  }

  Future<void> updateCouponSize(int id, Map<String, dynamic> data) async {
    await _dio.patch('${ApiConfig.baseUrl}admin/coupon-sizes/$id', data: data);
  }

  Future<void> deleteCouponSize(int id) async {
    await _dio.delete('${ApiEndpoints.adminCouponSizes}/$id');
  }

  Future<void> toggleUserActive(int userId) async {
    await _dio.put('${ApiEndpoints.adminUsers}/$userId/toggle-active');
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _dio.delete('${ApiEndpoints.adminUsers}/$userId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Return a key that will be localized in the UI
        throw Exception('cannotDeleteUserWithRecords');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAnalytics(
      {String? startDate, String? endDate}) async {
    final response = await _dio.get(
      ApiEndpoints.adminAnalytics,
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return response.data['data'];
  }

  // Station Management
  Future<void> createStation({
    required String name,
    String? address,
  }) async {
    await _dio.post(
      ApiEndpoints.adminStations,
      data: {
        'name': name,
        if (address != null) 'address': address,
      },
    );
  }

  Future<void> updateStation({
    required int stationId,
    required String name,
    String? address,
  }) async {
    await _dio.put(
      '${ApiEndpoints.adminStations}/$stationId',
      data: {
        'name': name,
        if (address != null) 'address': address,
      },
    );
  }

  Future<void> deleteStation(int stationId) async {
    await _dio.delete('${ApiEndpoints.adminStations}/$stationId');
  }

  // Scheduled Deliveries
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final response = await _dio.get(ApiEndpoints.adminSchedules);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<void> createSchedule(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.adminSchedules, data: data);
  }

  Future<void> updateSchedule(int id, Map<String, dynamic> data) async {
    await _dio.put('${ApiEndpoints.adminSchedules}/$id', data: data);
  }

  Future<void> deleteSchedule(int id) async {
    await _dio.delete('${ApiEndpoints.adminSchedules}/$id');
  }

  Future<void> batchDeleteSchedules(List<int> ids) async {
    await _dio.post('${ApiEndpoints.adminSchedules}/batch-delete', data: {'ids': ids});
  }

  // Worker Salary Advance
  Future<void> updateWorkerAdvance(int userId, double amount) async {
    await _dio.patch('/admin/users/$userId/advance', data: {'amount': amount});
  }

  // Worker Expenses
  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final response = await _dio.get('/admin/expenses');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<void> updateExpenseStatus(int expenseId, String status) async {
    await _dio.patch('/admin/expenses/$expenseId/status', data: {'payment_status': status});
  }

  Future<void> updateExpense(int expenseId, Map<String, dynamic> data) async {
    await _dio.put('/admin/expenses/$expenseId', data: data);
  }

  // Work Shifts
  Future<List<Map<String, dynamic>>> getShifts() async {
    final response = await _dio.get('/admin/shifts');
    return List<Map<String, dynamic>>.from(response.data['shifts']);
  }

  Future<void> createShift(Map<String, dynamic> data) async {
    await _dio.post('/admin/shifts', data: data);
  }

  Future<void> updateShift(int id, Map<String, dynamic> data) async {
    await _dio.put('/admin/shifts/$id', data: data);
  }

  Future<void> deleteShift(int id) async {
    await _dio.delete('/admin/shifts/$id');
  }

  Future<void> assignShift(int userId, int shiftId) async {
    await _dio.post('/admin/shifts/assign', data: {'userId': userId, 'shiftId': shiftId});
  }

  // Worker Leaves
  Future<List<Map<String, dynamic>>> getLeaves({int? userId, bool? activeOnly}) async {
    final response = await _dio.get('/admin/leaves', queryParameters: {
      if (userId != null) 'user_id': userId,
      if (activeOnly != null) 'active_only': activeOnly,
    });
    return List<Map<String, dynamic>>.from(response.data['leaves']);
  }

  Future<void> createLeave(Map<String, dynamic> data) async {
    await _dio.post('/admin/leaves', data: data);
  }

  Future<void> updateLeave(int id, Map<String, dynamic> data) async {
    await _dio.put('/admin/leaves/$id', data: data);
  }

  Future<void> deleteLeave(int id) async {
    await _dio.delete('/admin/leaves/$id');
  }

  // Dispensers
  Future<List<Map<String, dynamic>>> getDispensers() async {
    final response = await _dio.get('/admin/dispensers');
    return List<Map<String, dynamic>>.from(response.data['dispensers']);
  }

  Future<List<Map<String, dynamic>>> getDispenserTypes() async {
    final response = await _dio.get('/admin/dispenser-types');
    return List<Map<String, dynamic>>.from(response.data['types']);
  }

  Future<List<Map<String, dynamic>>> getDispenserFeatures() async {
    final response = await _dio.get('/admin/dispenser-features');
    return List<Map<String, dynamic>>.from(response.data['features']);
  }

  Future<void> createDispenserType(String name) async {
    await _dio.post('${ApiConfig.baseUrl}admin/dispenser-types', data: {'name': name});
  }

  Future<void> updateDispenserType(int id, String name) async {
    await _dio.put('${ApiConfig.baseUrl}admin/dispenser-types/$id', data: {'name': name});
  }

  Future<void> deleteDispenserType(int id) async {
    await _dio.delete('${ApiConfig.baseUrl}admin/dispenser-types/$id');
  }

  Future<void> createDispenserFeature(String name) async {
    await _dio.post('${ApiConfig.baseUrl}admin/dispenser-features', data: {'name': name});
  }

  Future<void> updateDispenserFeature(int id, String name) async {
    await _dio.put('${ApiConfig.baseUrl}admin/dispenser-features/$id', data: {'name': name});
  }

  Future<void> deleteDispenserFeature(int id) async {
    await _dio.delete('${ApiConfig.baseUrl}admin/dispenser-features/$id');
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final response = await _dio.get('/admin/clients');
    return List<Map<String, dynamic>>.from(response.data['clients']);
  }

  Future<void> createDispenser(String serialNumber, int? typeId, List<int> features, String status, int? clientId) async {
    await _dio.post('/admin/dispensers', data: {
      'serial_number': serialNumber,
      'type_id': typeId,
      'features': features,
      'status': status,
      'current_client_id': clientId,
    });
  }

  Future<void> updateDispenser(int id, String serialNumber, int? typeId, List<int> features, String status, int? clientId) async {
    await _dio.put('${ApiConfig.baseUrl}admin/dispensers/$id', data: {
      'serial_number': serialNumber,
      'type_id': typeId,
      'features': features,
      'status': status,
      'current_client_id': clientId,
    });
  }

  Future<void> deleteDispenser(int id) async {
    await _dio.delete('${ApiConfig.baseUrl}admin/dispensers/$id');
  }

  // Client Assets
  Future<List<Map<String, dynamic>>> getClientAssets(int clientId) async {
    final response = await _dio.get('/admin/clients/$clientId/assets');
    return List<Map<String, dynamic>>.from(response.data['assets']);
  }

  Future<void> createClientAsset(int clientId, String assetType, int quantity) async {
    await _dio.post('/admin/clients/$clientId/assets', data: {
      'asset_type': assetType,
      'quantity': quantity,
    });
  }

  Future<void> updateClientAsset(int assetId, String assetType, int quantity) async {
    await _dio.put('/admin/assets/$assetId', data: {
      'asset_type': assetType,
      'quantity': quantity,
    });
  }

  Future<void> deleteClientAsset(int assetId) async {
    await _dio.delete('/admin/assets/$assetId');
  }

  // Coupon Book Requests
  Future<List<Map<String, dynamic>>> getCouponBookRequests({String? status}) async {
    final response = await _dio.get(
      ApiEndpoints.adminCouponBookRequests,
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    return List<Map<String, dynamic>>.from(response.data['data']['requests']);
  }

  Future<void> updateCouponBookRequestStatus(int requestId, String status) async {
    await _dio.patch(
      '${ApiEndpoints.adminCouponBookRequests}/$requestId/status',
      data: {'status': status},
    );
  }

  Future<void> deleteCouponBookRequest(int requestId) async {
    await _dio.delete('${ApiEndpoints.adminCouponBookRequests}/$requestId');
  }
}
