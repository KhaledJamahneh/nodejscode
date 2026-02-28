const cron = require('node-cron');
const { query } = require('../config/database');
const logger = require('../utils/logger');

/**
 * Initialize background scheduled tasks
 */
const initCronJobs = () => {
  // 1. Cleanup old notifications (Every day at midnight)
  cron.schedule('0 0 * * *', async () => {
    logger.info('Running notification cleanup job...');
    try {
      const result = await query(
        `DELETE FROM notifications 
         WHERE is_read = true 
         AND created_at < NOW() - INTERVAL '90 days'`
      );
      logger.info(`Cleanup complete. Deleted ${result.rowCount} old notifications.`);
    } catch (error) {
      logger.error('Notification cleanup failed:', error);
    }
  });

  // 2. Reset monthly usage (1st of every month at midnight)
  cron.schedule('0 0 1 * *', async () => {
    logger.info('Running monthly usage reset job...');
    try {
      const result = await query(
        'UPDATE client_profiles SET monthly_usage_gallons = 0'
      );
      logger.info(`Usage reset complete. Reset ${result.rowCount} client profiles.`);
    } catch (error) {
      logger.error('Monthly usage reset failed:', error);
    }
  });

  logger.info('Background cron jobs initialized');
};

module.exports = {
  initCronJobs
};
