// src/routes/notification.routes.js
const express = require('express');
const { authenticateToken } = require('../middleware/auth.middleware');
const router = express.Router();

router.use(authenticateToken);

router.get('/', (req, res) => {
  res.json({ success: true, message: 'Notifications endpoint - to be implemented' });
});

module.exports = router;
