import '../../../../core/utils/double_utils.dart';

class ClientProfile {
  final int userId;
  final int profileId;
  final String fullName;
  final String address;
  final String subscriptionType;
  final String? subscriptionExpiryDate;
  final int remainingCoupons;
  final int bonusGallons;
  final int gallonsOnHand;
  final double currentDebt;
  final String subscriptionStatus;

  // ─── Home Location ────────────────────────────────────────────────────────
  /// Saved once by the client. Used to calculate proximity to the delivery worker.
  final double? homeLatitude;
  final double? homeLongitude;

  ClientProfile({
    required this.userId,
    required this.profileId,
    required this.fullName,
    required this.address,
    required this.subscriptionType,
    this.subscriptionExpiryDate,
    required this.remainingCoupons,
    required this.bonusGallons,
    required this.gallonsOnHand,
    required this.currentDebt,
    required this.subscriptionStatus,
    this.homeLatitude,
    this.homeLongitude,
  });

  bool get hasHomeLocation => homeLatitude != null && homeLongitude != null;

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      userId: json['user_id'],
      profileId: json['profile_id'],
      fullName: json['full_name'],
      address: json['address'],
      subscriptionType: json['subscription_type'],
      subscriptionExpiryDate: json['subscription_expiry_date'],
      remainingCoupons: json['remaining_coupons'] ?? 0,
      bonusGallons: json['bonus_gallons'] ?? 0,
      gallonsOnHand: json['gallons_on_hand'] ?? 0,
      currentDebt: DoubleUtils.toDouble(json['current_debt']),
      subscriptionStatus: json['subscription_status'] ?? 'active',
      homeLatitude: json['home_latitude'] != null
          ? DoubleUtils.toDouble(json['home_latitude'])
          : null,
      homeLongitude: json['home_longitude'] != null
          ? DoubleUtils.toDouble(json['home_longitude'])
          : null,
    );
  }
}

class ClientAsset {
  final int id;
  final String assetType;
  final int quantity;
  final String assignedDate;
  final String? serialNumber;
  final String? dispenserType;
  final String? status;

  ClientAsset({
    required this.id,
    required this.assetType,
    required this.quantity,
    required this.assignedDate,
    this.serialNumber,
    this.dispenserType,
    this.status,
  });

  factory ClientAsset.fromJson(Map<String, dynamic> json) {
    return ClientAsset(
      id: json['id'],
      assetType: json['asset_type'],
      quantity: json['quantity'],
      assignedDate: json['assigned_date'],
      serialNumber: json['serial_number'],
      dispenserType: json['dispenser_type'],
      status: json['dispenser_status'],
    );
  }
}

class UsageHistory {
  final List<dynamic> monthlyUsage;
  final List<dynamic> recentDeliveries;
  final Map<String, dynamic> statistics;

  UsageHistory({
    required this.monthlyUsage,
    required this.recentDeliveries,
    required this.statistics,
  });

  factory UsageHistory.fromJson(Map<String, dynamic> json) {
    return UsageHistory(
      monthlyUsage: json['monthly_usage'] ?? [],
      recentDeliveries: json['recent_deliveries'] ?? [],
      statistics: json['statistics'] ?? {},
    );
  }
}
