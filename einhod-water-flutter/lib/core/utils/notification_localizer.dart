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
    
    String message;
    switch (notificationKey) {
      case 'notification.delivery.assigned':
        message = l10n.notificationDeliveryAssignedMsg;
        break;
      case 'notification.request.accepted':
        message = l10n.notificationRequestAcceptedMsg;
        break;
      case 'notification.delivery.completed':
        message = l10n.notificationDeliveryCompletedMsg;
        break;
      case 'notification.payment.received':
        message = l10n.notificationPaymentReceivedMsg;
        break;
      case 'notification.worker.nearby':
        message = l10n.notificationWorkerNearbyMsg;
        break;
      case 'notification.generic':
      default:
        return fallbackMessage;
    }

    // Replace parameters
    if (params != null) {
      params.forEach((key, value) {
        message = message.replaceAll('{$key}', value.toString());
      });
    }

    return message;
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
