// src/routes/notifications.routes.js
const express = require('express');
const router = express.Router();
const notificationsController = require('../controllers/notifications.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

// All routes require authentication
router.use(authenticateToken);

/**
 * GET /api/v1/notifications
 * Get user's notifications
 */
router.get('/', notificationsController.getNotifications);

/**
 * GET /api/v1/notifications/unread-count
 * Get count of unread notifications
 */
router.get('/unread-count', notificationsController.getUnreadCount);

/**
 * PATCH /api/v1/notifications/mark-all-read
 * Mark all notifications as read
 */
router.patch('/mark-all-read', notificationsController.markAllAsRead);

/**
 * PATCH /api/v1/notifications/:id/read
 * Mark notification as read
 */
router.patch('/:id/read', notificationsController.markAsRead);

/**
 * DELETE /api/v1/notifications/:id
 * Delete a notification
 */
router.delete('/:id', notificationsController.deleteNotification);

module.exports = router;
