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
 * @param {object} [params.dbClient] - Optional database client for transaction support
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
  sendPush = true,
  dbClient // Optional client for transaction support
}) => {
  try {
    // 1. Tier 1: Store in Database (Guaranteed)
    // Use the provided transaction client if available, otherwise use the pool
    const executor = dbClient || { query };
    const result = await executor.query(
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
      this.sendPush(userId, notification);
    }

    return notification;
  } catch (error) {
    logger.error('Failed to create notification:', error);
    throw error; // Rethrow to allow caller to handle database failure
  }
};

/**
 * Send a best-effort push notification for an existing database notification
 * @param {number} userId 
 * @param {object} notification 
 */
exports.sendPush = (userId, notification) => {
  // Fire-and-forget push notification to avoid blocking the main flow
  (async () => {
    try {
      await fcmService.sendToUser(userId, {
        title: notification.title,
        body: notification.message,
        data: {
          id: (notification.id || '').toString(),
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
