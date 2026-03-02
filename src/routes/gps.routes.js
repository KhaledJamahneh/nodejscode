// src/routes/gps.routes.js
const express = require('express');
const { authenticateToken } = require('../middleware/auth.middleware');
const router = express.Router();

router.use(authenticateToken);

router.post('/update-location', (req, res) => {
  res.json({ success: true, message: 'GPS update endpoint - to be implemented' });
});

module.exports = router;
