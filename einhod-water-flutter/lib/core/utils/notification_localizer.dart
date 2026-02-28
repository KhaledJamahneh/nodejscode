import 'dart:convert';
import 'package:einhod_water/l10n/app_localizations.dart';

class NotificationLocalizer {
  static String getTitle(String? notificationKey, String fallbackTitle, AppLocalizations l10n) {
    if (notificationKey == null) return fallbackTitle;
    
    switch (notificationKey) {
      case 'notification.delivery.assigned':
        return l10n.notificationDeliveryAssigned;
      case 'notification.request.accepted':
        return l10n.notificationRequestAccepted;
      case 'notification.delivery.completed':
        return l10n.notificationDeliveryCompleted;
      case 'notification.payment.received':
        return l10n.notificationPaymentReceived;
      case 'notification.worker.nearby':
        return l10n.notificationWorkerNearby;
      case 'notification.generic':
      default:
        return fallbackTitle;
    }
  }

  static String getMessage(String? notificationKey, String fallbackMessage, Map<String, dynamic>? params, AppLocalizations l10n) {
    if (notificationKey == null) return fallbackMessage;
    
    switch (notificationKey) {
      case 'notification.delivery.assigned':
        return l10n.notificationDeliveryAssignedMsg;
      case 'notification.request.accepted':
        final workerName = params?['workerName']?.toString() ?? 'Worker';
        return l10n.notificationRequestAcceptedMsg(workerName);
      case 'notification.delivery.completed':
        return l10n.notificationDeliveryCompletedMsg;
      case 'notification.payment.received':
        final amount = params?['amount']?.toString() ?? '0';
        return l10n.notificationPaymentReceivedMsg(amount);
      case 'notification.worker.nearby':
        final workerName = params?['workerName']?.toString() ?? 'Worker';
        return l10n.notificationWorkerNearbyMsg(workerName);
      case 'notification.generic':
      default:
        return fallbackMessage;
    }
  }

  static Map<String, dynamic>? parseParams(dynamic paramsData) {
    if (paramsData == null) return null;
    if (paramsData is Map<String, dynamic>) return paramsData;
    if (paramsData is String) {
      try {
        return jsonDecode(paramsData) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
