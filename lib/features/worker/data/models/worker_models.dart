// lib/features/worker/data/models/worker_models.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/double_utils.dart';

enum WorkerViewType {
  delivery,
  onsite,
  unknown;

  factory WorkerViewType.fromString(String? value) {
    if (value == null || value.isEmpty) return WorkerViewType.unknown;
    final lower = value.toLowerCase().trim();
    if (lower.contains('onsite') ||
        lower.contains('station') ||
        lower.contains('fill') ||
        lower.contains('production')) {
      return WorkerViewType.onsite;
    }
    if (lower.contains('delivery') ||
        lower.contains('driver') ||
        lower.contains('transport')) {
      return WorkerViewType.delivery;
    }
    return WorkerViewType.unknown;
  }
}

enum StationStatus {
  open,
  temporarilyClosed,
  closedUntilTomorrow;

  String get displayName {
    switch (this) {
      case StationStatus.open:
        return 'Open';
      case StationStatus.temporarilyClosed:
        return 'Temporarily Closed';
      case StationStatus.closedUntilTomorrow:
        return 'Closed Until Tomorrow';
    }
  }

  Color get color {
    switch (this) {
      case StationStatus.open:
        return AppTheme.successGreen;
      case StationStatus.temporarilyClosed:
        return AppTheme.midUrgentOrange;
      case StationStatus.closedUntilTomorrow:
        return AppTheme.criticalRed;
    }
  }
}

class WorkerProfile {
  final int userId;
  final int profileId;
  final String username;
  final String fullName;
  final String workerType;
  final WorkerViewType viewType;
  final List<String> roles;
  final String hireDate;
  final double currentSalary;
  final double debtAdvances;
  final int vehicleCurrentGallons;
  final bool gpsSharingEnabled;
  final bool isDualRole;

  WorkerProfile({
    required this.userId,
    required this.profileId,
    required this.username,
    required this.fullName,
    required this.workerType,
    required this.viewType,
    required this.roles,
    required this.hireDate,
    required this.currentSalary,
    required this.debtAdvances,
    required this.vehicleCurrentGallons,
    required this.gpsSharingEnabled,
    required this.isDualRole,
  });

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    final rawType = (json['worker_type'] ?? json['type'] ?? '').toString();
    final rolesList = List<String>.from(json['role'] ?? json['roles'] ?? []);

    return WorkerProfile(
      userId: json['user_id'] ?? 0,
      profileId: json['profile_id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      workerType: rawType,
      viewType: WorkerViewType.fromString(rawType),
      roles: rolesList.map((r) => r.toLowerCase().trim()).toList(),
      hireDate: json['hire_date'] ?? '',
      currentSalary: DoubleUtils.toDouble(json['current_salary']),
      debtAdvances: DoubleUtils.toDouble(json['debt_advances']),
      vehicleCurrentGallons: json['vehicle_current_gallons'] ?? 0,
      gpsSharingEnabled: json['gps_sharing_enabled'] ?? false,
      isDualRole: json['is_dual_role'] ?? false,
    );
  }

  bool get isOnsite => viewType == WorkerViewType.onsite;
  bool get isDelivery => viewType == WorkerViewType.delivery;
}

class WorkerDelivery {
  final int id;
  final String deliveryDate;
  final String? scheduledTime;
  final int scheduledGallons;
  final int emptyGallonsReturned;
  final String status;
  final String? notes;
  final String clientName;
  final String clientAddress;
  final String? latitude;
  final String? longitude;
  final String clientPhone;
  final int remainingCoupons;
  final String subscriptionType;
  // FIX: New field — number of coupon-book coupons used (paid) for this delivery
  final int paidCouponsCount;
  final bool isRequest;

  WorkerDelivery({
    required this.id,
    required this.deliveryDate,
    this.scheduledTime,
    required this.scheduledGallons,
    this.emptyGallonsReturned = 0,
    required this.status,
    this.notes,
    required this.clientName,
    required this.clientAddress,
    this.latitude,
    this.longitude,
    required this.clientPhone,
    required this.remainingCoupons,
    required this.subscriptionType,
    this.paidCouponsCount = 0,
    this.isRequest = false,
  });

  factory WorkerDelivery.fromJson(Map<String, dynamic> json) {
    return WorkerDelivery(
      id: json['id'],
      deliveryDate: json['delivery_date'] ?? '',
      scheduledTime: json['scheduled_time'],
      scheduledGallons: json['scheduled_gallons'] ?? 0,
      emptyGallonsReturned: json['empty_gallons_returned'] ?? 0,
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      clientName: json['client_name'] ?? 'Unknown',
      clientAddress: json['client_address'] ?? 'No address',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      clientPhone: json['client_phone'] ?? '',
      remainingCoupons: json['remaining_coupons'] ?? 0,
      subscriptionType: json['subscription_type'] ?? 'cash',
      // FIX: parse paid_coupons_count from API, defaulting to 0
      paidCouponsCount: json['paid_coupons_count'] ?? 0,
      isRequest: json['is_request'] ?? false,
    );
  }

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';

  /// Whether the client pays by coupon book.
  bool get isCouponBook => subscriptionType == 'coupon_book';
}

class WorkerRequest {
  final int id;
  final String priority;
  final int requestedGallons;
  final int emptyGallonsReturned;
  final String requestDate;
  final String status;
  final String? notes;
  final String clientName;
  final String clientAddress;
  final String? latitude;
  final String? longitude;
  final String clientPhone;
  final bool assignedToMe;
  final bool isRequest;

  WorkerRequest({
    required this.id,
    required this.priority,
    required this.requestedGallons,
    this.emptyGallonsReturned = 0,
    required this.requestDate,
    required this.status,
    this.notes,
    required this.clientName,
    required this.clientAddress,
    this.latitude,
    this.longitude,
    required this.clientPhone,
    required this.assignedToMe,
    this.isRequest = true,
  });

  factory WorkerRequest.fromJson(Map<String, dynamic> json) {
    return WorkerRequest(
      id: json['id'],
      priority: json['priority'] ?? 'non_urgent',
      requestedGallons: json['requested_gallons'] ?? 0,
      emptyGallonsReturned: json['empty_gallons_returned'] ?? 0,
      requestDate: json['request_date'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      clientName: json['client_name'] ?? 'Unknown',
      clientAddress: json['client_address'] ?? 'No address',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      clientPhone: json['client_phone'] ?? '',
      assignedToMe: json['assigned_to_me'] ?? false,
      isRequest: json['is_request'] ?? true,
    );
  }

  WorkerDelivery toDelivery() {
    return WorkerDelivery(
      id: id,
      deliveryDate: requestDate,
      scheduledTime: 'ASAP',
      scheduledGallons: requestedGallons,
      status: status,
      notes: notes,
      clientName: clientName,
      clientAddress: clientAddress,
      latitude: latitude,
      longitude: longitude,
      clientPhone: clientPhone,
      remainingCoupons: 0, // Will be updated by API if needed
      subscriptionType: 'cash', // Will be updated by API if needed
      isRequest: true,
    );
  }
}

class FillingStation {
  final int id;
  final String name;
  final String? address;
  final StationStatus currentStatus;

  FillingStation({
    required this.id,
    required this.name,
    this.address,
    required this.currentStatus,
  });

  factory FillingStation.fromJson(Map<String, dynamic> json) {
    String rawStatus = json['current_status'] ?? json['status'] ?? 'open';
    StationStatus status = StationStatus.open;

    if (rawStatus == 'closed_temporarily' || rawStatus == 'temporarilyClosed') {
      status = StationStatus.temporarilyClosed;
    } else if (rawStatus == 'closed_until_tomorrow' ||
        rawStatus == 'closedUntilTomorrow') {
      status = StationStatus.closedUntilTomorrow;
    }

    return FillingStation(
      id: json['id'],
      name: json['name'] ?? 'Unknown Station',
      address: json['address'],
      currentStatus: status,
    );
  }

  bool get isOpen => currentStatus == StationStatus.open;
}

class FillingSession {
  final int id;
  final String stationName;
  final int gallonsFilled;
  final String completionTime;

  FillingSession({
    required this.id,
    required this.stationName,
    required this.gallonsFilled,
    required this.completionTime,
  });

  factory FillingSession.fromJson(Map<String, dynamic> json) {
    return FillingSession(
      id: json['id'],
      stationName: json['station_name'] ?? 'Unknown',
      gallonsFilled: json['gallons_filled'] ?? 0,
      completionTime: json['completion_time'] ?? '',
    );
  }
}

class WorkerExpense {
  final int id;
  final double amount;
  final String paymentMethod;
  final String paymentStatus;
  final String? destination;
  final String? notes;
  final String date;

  WorkerExpense({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.destination,
    this.notes,
    required this.date,
  });

  factory WorkerExpense.fromJson(Map<String, dynamic> json) {
    return WorkerExpense(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      destination: json['destination'],
      notes: json['notes'],
      date: json['date'] ?? '',
    );
  }
}
