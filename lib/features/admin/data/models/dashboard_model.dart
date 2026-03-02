// lib/features/admin/data/models/dashboard_model.dart
import '../../../../core/utils/double_utils.dart';

class DashboardMetrics {
  final int onShiftWorkers;
  final int pendingDeliveries;
  final int todayDeliveries;
  final int pendingRequests;
  final int urgentRequests;
  final int activeClients;
  final int lowInventoryWorkers;
  final int clientsWithDebt;
  final int pendingCouponRequests;

  DashboardMetrics({
    required this.onShiftWorkers,
    required this.pendingDeliveries,
    required this.todayDeliveries,
    required this.pendingRequests,
    required this.urgentRequests,
    required this.activeClients,
    required this.lowInventoryWorkers,
    required this.clientsWithDebt,
    required this.pendingCouponRequests,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      onShiftWorkers: json['on_shift_workers'] ?? 0,
      pendingDeliveries: json['pending_deliveries'] ?? 0,
      todayDeliveries: json['today_deliveries'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
      urgentRequests: json['urgent_requests'] ?? 0,
      activeClients: json['active_clients'] ?? 0,
      lowInventoryWorkers: json['low_inventory_workers'] ?? 0,
      clientsWithDebt: json['clients_with_debt'] ?? 0,
      pendingCouponRequests: json['pending_coupon_requests'] ?? 0,
    );
  }
}

class DashboardDetails {
  final List<dynamic> onShiftWorkers;
  final List<dynamic> pendingDeliveries;
  final List<dynamic> todayDeliveries;
  final List<dynamic> pendingRequests;
  final List<dynamic> activeClients;
  final List<dynamic> lowInventoryWorkers;
  final List<dynamic> clientsWithDebt;

  DashboardDetails({
    required this.onShiftWorkers,
    required this.pendingDeliveries,
    required this.todayDeliveries,
    required this.pendingRequests,
    required this.activeClients,
    required this.lowInventoryWorkers,
    required this.clientsWithDebt,
  });

  factory DashboardDetails.fromJson(Map<String, dynamic> json) {
    return DashboardDetails(
      onShiftWorkers: json['on_shift_workers'] ?? [],
      pendingDeliveries: json['pending_deliveries'] ?? [],
      todayDeliveries: json['today_deliveries'] ?? [],
      pendingRequests: json['pending_requests'] ?? [],
      activeClients: json['active_clients'] ?? [],
      lowInventoryWorkers: json['low_inventory_workers'] ?? [],
      clientsWithDebt: json['clients_with_debt'] ?? [],
    );
  }
}

class DashboardRevenue {
  final double today;
  final double thisMonth;

  DashboardRevenue({
    required this.today,
    required this.thisMonth,
  });

  factory DashboardRevenue.fromJson(Map<String, dynamic> json) {
    return DashboardRevenue(
      today: DoubleUtils.toDouble(json['today']),
      thisMonth: DoubleUtils.toDouble(json['this_month']),
    );
  }
}

class DashboardData {
  final DashboardMetrics metrics;
  final DashboardDetails details;
  final DashboardRevenue revenue;

  DashboardData({
    required this.metrics,
    required this.details,
    required this.revenue,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      metrics: DashboardMetrics.fromJson(json['metrics']),
      details: DashboardDetails.fromJson(json['details'] ?? {}),
      revenue: DashboardRevenue.fromJson(json['revenue']),
    );
  }
}
