// src/services/notification.service.js
const logger = require('../utils/logger');
const { getLanguageMetadata } = require('../utils/i18n');

/**
 * Send notification to a user
 * @param {number} userId - User ID
 * @param {object} notification - { title, body, lang }
 * 
 * Example usage:
 *   const { t } = require('../utils/i18n');
 *   
 *   // Safe - HTML escaped by default
 *   await sendNotification(userId, {
 *     title: t(userLang, 'water_delivered_title'),
 *     body: t(userLang, 'water_delivered_body', { amount: 5, unit: 'gallon' }),
 *     lang: userLang
 *   });
 *   
 *   // Unsafe worker name from user input - automatically escaped
 *   await sendNotification(userId, {
 *     title: t(userLang, 'request_accepted_title'),
 *     body: t(userLang, 'request_accepted_body', { 
 *       worker: unsafeWorkerName // Will be escaped: "<script>alert('xss')</script>" → "&lt;script&gt;..."
 *     }),
 *     lang: userLang
 *   });
 *   
 *   // Opt-out of escaping (only if you're sure data is safe)
 *   await sendNotification(userId, {
 *     body: t(userLang, 'some_key', { html: '<b>Bold</b>' }, { escape: false }),
 *     lang: userLang
 *   });
 * 
 * TODO: Implement FCM/push notification service
 */
exports.sendNotification = async (userId, notification) => {
  try {
    // Add language metadata for frontend RTL support
    const langMetadata = getLanguageMetadata(notification.lang || 'en');
    const enrichedNotification = {
      ...notification,
      dir: langMetadata.dir,
      locale: langMetadata.locale
    };
    
    logger.info('Notification sent:', { userId, notification: enrichedNotification });
    
    // TODO: Implement actual push notification
    // - Get user's FCM token from database
    // - Send via Firebase Cloud Messaging with dir/locale metadata
    // - Store notification in database for history
    
    return { success: true };
  } catch (error) {
    logger.error('Error sending notification:', error);
    return { success: false, error };
  }
};
