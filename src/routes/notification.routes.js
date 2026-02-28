// src/routes/notification.routes.js
const express = require('express');
const { authenticateToken } = require('../middleware/auth.middleware');
const notificationsController = require('../controllers/notifications.controller');
const router = express.Router();

router.use(authenticateToken);

router.get('/', notificationsController.getNotifications);
router.get('/unread-count', notificationsController.getUnreadCount);
router.put('/:id/read', notificationsController.markAsRead);
router.put('/mark-all-read', notificationsController.markAllAsRead);

module.exports = router;
