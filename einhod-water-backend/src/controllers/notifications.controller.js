// src/controllers/notifications.controller.js
const { query } = require('../config/database');
const logger = require('../utils/logger');
const { getStatusCode } = require('../middleware/error-handler.middleware');

/**
 * GET /api/v1/notifications
 * Get user's notifications
 */
const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const { limit = 50, offset = 0, unread_only = false, view_as } = req.query;

    const roles = Array.isArray(userRole) ? userRole : [userRole];
    const isClient = roles.includes('client');
    const isWorker = roles.includes('delivery_worker') || roles.includes('onsite_worker');
    const isAdmin = roles.includes('administrator') || roles.includes('owner');

    let queryText = `
      SELECT 
        id,
        title,
        message,
        message as body,
        type,
        type as category,
        CASE 
          WHEN type IN ('important', 'urgent') THEN 'important'
          WHEN type IN ('worker_assignment', 'status_update') THEN 'mid_importance'
          ELSE 'normal'
        END as level,
        reference_id,
        reference_type,
        is_read,
        created_at,
        read_at
      FROM notifications
      WHERE user_id = $1
    `;

    const params = [userId];

    // Filter notifications by type based on current view
    const currentView = view_as || (isAdmin ? 'admin' : isWorker ? 'worker' : 'client');
    
    if (currentView === 'admin' && isAdmin) {
      queryText += " AND type IN ('low_inventory', 'new_request', 'system', 'urgent', 'important', 'announcement', 'worker_assignment', 'delivery_status')";
    } else if (currentView === 'worker' && isWorker) {
      queryText += " AND type IN ('worker_assignment', 'delivery_status', 'system', 'announcement')";
    } else if (currentView === 'client' && isClient) {
      queryText += " AND type IN ('delivery_status', 'coupon_status', 'announcement', 'system', 'payment')";
    }
    // If no filter matched, show all notifications (fallback)

    if (unread_only === 'true') {
      queryText += ' AND is_read = false';
    }

    queryText += ` ORDER BY created_at DESC LIMIT $2 OFFSET $3`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, params);

    // Get unread count
    const unreadResult = await query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({
      success: true,
      data: {
        notifications: result.rows,
        unread_count: parseInt(unreadResult.rows[0].count)
      }
    });
  } catch (error) {
    logger.error('Get notifications error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get notifications'
    });
  }
};

/**
 * GET /api/v1/notifications/unread-count
 * Get count of unread notifications
 */
const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const { view_as } = req.query;

    const roles = Array.isArray(userRole) ? userRole : [userRole];
    const isClient = roles.includes('client');
    const isWorker = roles.includes('delivery_worker') || roles.includes('onsite_worker');
    const isAdmin = roles.includes('administrator') || roles.includes('owner');

    let queryText = 'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false';
    const params = [userId];

    // Apply same filtering as getNotifications
    const currentView = view_as || (isAdmin ? 'admin' : isWorker ? 'worker' : 'client');
    
    if (currentView === 'admin' && isAdmin) {
      queryText += " AND type IN ('low_inventory', 'new_request', 'system', 'urgent', 'important', 'announcement', 'worker_assignment', 'delivery_status')";
    } else if (currentView === 'worker' && isWorker) {
      queryText += " AND type IN ('worker_assignment', 'delivery_status', 'system', 'announcement')";
    } else if (currentView === 'client' && isClient) {
      queryText += " AND type IN ('delivery_status', 'coupon_status', 'announcement', 'system', 'payment')";
    }

    const result = await query(queryText, params);

    res.json({
      success: true,
      data: {
        unread_count: parseInt(result.rows[0].count)
      }
    });
  } catch (error) {
    logger.error('Get unread count error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get unread count'
    });
  }
};

/**
 * PATCH /api/v1/notifications/:id/read
 * Mark notification as read
 */
const markAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await query(
      `UPDATE notifications 
       SET is_read = true, read_at = CURRENT_TIMESTAMP 
       WHERE id = $1 AND user_id = $2
       RETURNING *`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Mark as read error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to mark notification as read'
    });
  }
};

/**
 * PATCH /api/v1/notifications/mark-all-read
 * Mark all notifications as read
 */
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    await query(
      `UPDATE notifications 
       SET is_read = true, read_at = CURRENT_TIMESTAMP 
       WHERE user_id = $1 AND is_read = false`,
      [userId]
    );

    res.json({
      success: true,
      message: 'All notifications marked as read'
    });
  } catch (error) {
    logger.error('Mark all as read error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to mark all as read'
    });
  }
};

/**
 * DELETE /api/v1/notifications/:id
 * Delete a notification
 */
const deleteNotification = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING *',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification deleted'
    });
  } catch (error) {
    logger.error('Delete notification error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to delete notification'
    });
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification
};
