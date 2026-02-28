// src/routes/payment.routes.js
const express = require('express');
const { authenticateToken } = require('../middleware/auth.middleware');
const paymentController = require('../controllers/payment.controller');
const router = express.Router();

router.use(authenticateToken);

router.post('/record', paymentController.recordPayment);

router.post('/create', (req, res) => {
  res.json({ success: true, message: 'Payment creation endpoint - to be implemented' });
});

module.exports = router;
