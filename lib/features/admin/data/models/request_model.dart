// lib/features/admin/data/models/request_model.dart
class DeliveryRequest {
  final int id;
  final String priority;
  final int requestedGallons;
  final String requestDate;
  final String status;
  final String? notes;
  final String clientName;
  final String clientAddress;
  final String clientPhone;
  final String? assignedWorkerName;

  DeliveryRequest({
    required this.id,
    required this.priority,
    required this.requestedGallons,
    required this.requestDate,
    required this.status,
    this.notes,
    required this.clientName,
    required this.clientAddress,
    required this.clientPhone,
    this.assignedWorkerName,
  });

  factory DeliveryRequest.fromJson(Map<String, dynamic> json) {
    return DeliveryRequest(
      id: json['id'],
      priority: json['priority'],
      requestedGallons: json['requested_gallons'],
      requestDate: json['request_date'],
      status: json['status'],
      notes: json['notes'],
      clientName: json['client_name'],
      clientAddress: json['client_address'],
      clientPhone: json['client_phone'],
      assignedWorkerName: json['assigned_worker_name'],
    );
  }

  String get priorityDisplay {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'mid_urgent':
        return 'Mid-Urgent';
      case 'non_urgent':
        return 'Normal';
      default:
        return priority;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get canAssignWorker => status == 'pending' && assignedWorkerName == null;
  bool get isUrgent => priority == 'urgent';
}
