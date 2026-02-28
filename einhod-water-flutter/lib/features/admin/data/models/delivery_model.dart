// lib/features/admin/data/models/delivery_model.dart
class Delivery {
  final int id;
  final String deliveryDate;
  final String? scheduledTime;
  final String? actualDeliveryTime;
  final int gallonsDelivered;
  final int? gallonsReturned;
  final String status;
  final String? notes;
  final String clientName;
  final String clientAddress;
  final String clientPhone;
  final String workerName;

  Delivery({
    required this.id,
    required this.deliveryDate,
    this.scheduledTime,
    this.actualDeliveryTime,
    required this.gallonsDelivered,
    this.gallonsReturned,
    required this.status,
    this.notes,
    required this.clientName,
    required this.clientAddress,
    required this.clientPhone,
    required this.workerName,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      deliveryDate: json['delivery_date'],
      scheduledTime: json['scheduled_time'],
      actualDeliveryTime: json['actual_delivery_time'],
      gallonsDelivered: json['gallons_delivered'],
      gallonsReturned: json['empty_gallons_returned'] ?? json['gallons_returned'],
      status: json['status'],
      notes: json['notes'],
      clientName: json['client_name'],
      clientAddress: json['client_address'],
      clientPhone: json['client_phone'],
      workerName: json['worker_name'],
    );
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

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
}
