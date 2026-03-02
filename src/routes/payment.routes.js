// src/routes/payment.routes.js
const express = require('express');
const { body } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const paymentController = require('../controllers/payment.controller');
const router = express.Router();

router.use(authenticateToken);

// Validation rules for recording a payment
const recordPaymentValidation = [
  body('payer_id').isInt({ min: 1 }).withMessage('Payer ID must be a positive integer'),
  body('receiver_type').isIn(['company', 'worker']).withMessage('Invalid receiver type'),
  body('receiver_id').optional().isInt({ min: 1 }).withMessage('Receiver ID must be a positive integer if provided'),
  body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be a positive number'),
  body('payment_method').isIn(['cash', 'credit_card', 'bank_transfer']).withMessage('Invalid payment method'),
  body('payment_status').isIn(['pending', 'completed', 'failed', 'refunded']).withMessage('Invalid payment status'),
  body('transaction_id').optional().isString().isLength({ max: 255 }).withMessage('Transaction ID too long'),
  body('description').optional().isString().isLength({ max: 500 }).withMessage('Description too long'),
];

router.post(
  '/record',
  authorizeRoles('administrator', 'owner'), // Only admin/owner can record payments
  recordPaymentValidation,
  validate,
  paymentController.recordPayment
);

router.post('/create', (req, res) => {
  res.json({ success: true, message: 'Payment creation endpoint - to be implemented (will also need auth and validation)' });
});

module.exports = router;
