// src/services/notification.service.js
const { query } = require('../config/database');
const logger = require('../utils/logger');
const { getLanguageMetadata, t } = require('../utils/i18n');
const fcmService = require('./fcm.service');

/**
 * Creates a notification in the system, handling both database storage (Tier 1)
 * and optional push notification (Tier 2).
 * 
 * @param {object} params - Notification parameters
 * @param {number} params.userId - Recipient user ID
 * @param {string} params.title - Notification title
 * @param {string} params.message - Notification message/body
 * @param {string} params.type - Notification type (e.g., 'delivery_status', 'worker_assignment')
 * @param {number} [params.referenceId] - Optional reference ID (e.g., delivery_request_id)
 * @param {string} [params.referenceType] - Optional reference type (e.g., 'delivery_request')
 * @param {string} [params.notificationKey] - Optional key for frontend localization
 * @param {object} [params.params] - Optional parameters for localization
 * @param {boolean} [params.sendPush=true] - Whether to attempt a push notification
 * 
 * @returns {Promise<object>} - The created notification from the database
 */
exports.createNotification = async ({
  userId,
  title,
  message,
  type,
  referenceId,
  referenceType,
  notificationKey,
  params = {},
  sendPush = true
}) => {
  try {
    // 1. Tier 1: Store in Database (Guaranteed)
    const result = await query(
      `INSERT INTO notifications (
        user_id, title, message, type, reference_id, reference_type, 
        notification_key, params
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        userId,
        title,
        message,
        type,
        referenceId,
        referenceType,
        notificationKey,
        JSON.stringify(params)
      ]
    );

    const notification = result.rows[0];
    logger.debug('Notification stored in database:', { id: notification.id, userId, type });

    // 2. Tier 2: Best-effort Push Notification
    if (sendPush) {
      // Fire-and-forget push notification to avoid blocking the main flow
      // This matches the "best-effort" guarantee in the docs
      (async () => {
        try {
          // In a real implementation, we would fetch user's preferred language metadata
          // and send localized push or include metadata for the app to localize
          await fcmService.sendToUser(userId, {
            title: notification.title,
            body: notification.message,
            data: {
              id: notification.id.toString(),
              type: notification.type,
              reference_id: (notification.reference_id || '').toString(),
              reference_type: notification.reference_type || '',
              notification_key: notification.notification_key || ''
            }
          });
        } catch (pushError) {
          logger.warn('Best-effort push notification failed:', pushError);
        }
      })();
    }

    return notification;
  } catch (error) {
    logger.error('Failed to create notification:', error);
    throw error; // Rethrow to allow caller to handle database failure
  }
};

/**
 * Backwards compatible method for sending notifications
 * @deprecated Use createNotification instead
 */
exports.sendNotification = async (userId, notification) => {
  try {
    const lang = notification.lang || 'en';
    const langMetadata = getLanguageMetadata(lang);
    
    // Attempt to store and send
    await this.createNotification({
      userId,
      title: notification.title,
      message: notification.body,
      type: notification.type || 'system',
      notificationKey: notification.notificationKey,
      params: notification.params
    });
    
    return { success: true };
  } catch (error) {
    logger.error('Error sending notification:', error);
    return { success: false, error };
  }
};
