// lib/features/client/data/models/client_request.dart
import 'package:einhod_water/l10n/app_localizations.dart';

class ClientRequest {
  final int id;
  final String priority;
  final int requestedGallons;
  final String requestDate;
  final String status;
  final String? notes;
  final String? assignedWorkerName;
  final String? workerPhone;

  ClientRequest({
    required this.id,
    required this.priority,
    required this.requestedGallons,
    required this.requestDate,
    required this.status,
    this.notes,
    this.assignedWorkerName,
    this.workerPhone,
  });

  factory ClientRequest.fromJson(Map<String, dynamic> json) {
    return ClientRequest(
      id: json['id'],
      priority: json['priority'],
      requestedGallons: json['requested_gallons'],
      requestDate: json['request_date'],
      status: json['status'],
      notes: json['notes'],
      assignedWorkerName: json['assigned_worker_name'],
      workerPhone: json['worker_phone'],
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

  String statusDisplay(AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'in_progress':
        return l10n.inProgress;
      case 'completed':
        return l10n.completed;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return status;
    }
  }

  bool get canCancel => status == 'pending';
}
