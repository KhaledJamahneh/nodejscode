import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Production API URL
  static const String PRODUCTION_URL = "https://nodejscode-33ip.onrender.com/api/v1/";

  // Base URL - Uses production Render URL
  static String get baseUrl {
    return PRODUCTION_URL;
  }

  // API Endpoints
  static const String auth = 'auth';
  static const String clients = 'clients';
  static const String deliveries = 'deliveries';
  static const String workers = 'workers';
  static const String admin = 'admin';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;
}

// API Endpoints Helper
class ApiEndpoints {
  // Auth
  static const String login = 'auth/login';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';
  static const String me = 'auth/me';
  static const String changePassword = 'auth/password/change';
  static const String passwordResetRequest = 'auth/password-reset/request';
  static const String passwordResetVerify = 'auth/password-reset/verify';

  // Client
  static const String clientProfile = 'clients/profile';
  static const String clientSubscription = 'clients/subscription';
  static const String clientUsage = 'clients/usage';
  static const String clientAssets = 'clients/assets';
  static const String clientDebt = 'clients/debt';
  static const String createDeliveryRequest = 'deliveries/request';
  static const String deliveryRequests = 'deliveries/requests';
  static const String deliveryHistory = 'deliveries/history';

  // ─── Location ────────────────────────────────────────────────────────────

  /// PUT — Client saves their permanent home location.
  /// Body: { home_latitude: double, home_longitude: double }
  static const String clientHomeLocation = 'clients/location/home';

  /// PUT — Worker sends their live position (called every ~30 s).
  /// Body: { latitude, longitude, delivery_id?, timestamp }
  static const String workerLocation = 'workers/location';

  /// GET — Client polls /{delivery_id} to get their assigned worker's live position.
  /// Returns: { data: { latitude, longitude, worker_name, updated_at } } or 404
  static const String workerLiveLocation = 'workers/location/delivery';

  /// GET — Client polls /{request_id} for request-based deliveries.
  static const String workerLiveLocationRequest = 'workers/location/request';

  // Worker
  static const String workerProfile = 'workers/profile';
  static const String mainSchedule = 'workers/schedule/main';
  static const String secondaryList = 'workers/schedule/secondary';
  static const String startDelivery = 'workers/deliveries';
  static const String completeDelivery = 'workers/deliveries';
  static const String acceptRequest = 'workers/requests';
  static const String completeRequest = 'workers/requests';
  static const String updateInventory = 'workers/vehicle/inventory';
  static const String toggleGPS = 'workers/gps/toggle';

  // Worker - Onsite
  static const String onsiteStations = 'workers/onsite/stations';
  static const String onsiteStartSession = 'workers/onsite/sessions/start';
  static const String onsiteCompleteSession =
      'workers/onsite/sessions'; // Append ID/complete
  static const String onsiteRecentSessions = 'workers/onsite/sessions/recent';
  static const String updateStationStatus = 'workers/onsite/stations';

  // Notifications
  static const String notifications = 'notifications';
  static const String unreadCount = 'notifications/unread-count';
  static const String markAllRead = 'notifications/mark-all-read';

  // Admin
  static const String adminDashboard = 'admin/dashboard';
  static const String adminRequests = 'admin/requests';
  static const String assignWorker = 'admin/requests';
  static const String adminDeliveries = 'admin/deliveries';
  static const String adminUsers = 'admin/users';
  static const String adminCouponSizes = 'admin/coupon-sizes';
  static const String adminAnalytics = 'admin/analytics/overview';
  static const String adminStations = 'admin/stations';
  static const String adminSchedules = 'schedules';
  static const String adminCouponBookRequests = 'admin/coupon-book-requests';
}
