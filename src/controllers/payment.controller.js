// src/controllers/payment.controller.js
const { query, transaction } = require('../config/database');
const logger = require('../utils/logger');
const { getStatusCode } = require('../middleware/error-handler.middleware');
const { t } = require('../utils/i18n');
const notificationService = require('../services/notification.service');

/**
 * POST /api/v1/payments/record
 * Record a client payment and reduce debt
 */
const recordPayment = async (req, res) => {
  try {
    const { client_id, amount, payment_method, notes } = req.body;
    const debt = req.body.debt || 0; // Safety check for null debt

    if (!client_id || !amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid client_id and positive amount are required'
      });
    }

    const result = await transaction(async (client) => {
      // 1. Lock the client profile row to prevent race conditions on debt
      const profileRes = await client.query(
        `SELECT cp.current_debt, cp.user_id, u.preferred_language 
         FROM client_profiles cp
         JOIN users u ON cp.user_id = u.id
         WHERE cp.id = $1 FOR UPDATE`,
        [client_id]
      );

      if (profileRes.rows.length === 0) {
        throw new Error('Client profile not found');
      }

      const currentDebt = parseFloat(profileRes.rows[0].current_debt) || 0; // Safety check
      const paymentAmount = Math.round(parseFloat(amount) * 100) / 100;
      const userId = profileRes.rows[0].user_id;

      // 2. Update debt (allow credit if payment > debt)
      const newDebt = Math.round((currentDebt - paymentAmount) * 100) / 100;

      await client.query(
        'UPDATE client_profiles SET current_debt = $1, updated_at = NOW() WHERE id = $2',
        [newDebt, client_id]
      );

      // 3. Record payment in history
      const paymentRes = await client.query(
        `INSERT INTO payments (
          payer_id, amount, payment_method, payment_status, payment_date, description
        ) VALUES ($1, $2, $3, 'completed', NOW(), $4)
        RETURNING id`,
        [userId, paymentAmount, payment_method || 'cash', notes || 'Manual payment record']
      );

      // 4. Create notification (Tier 1 & Tier 2)
      const lang = profileRes.rows[0].preferred_language || 'en';
      await notificationService.createNotification({
        userId,
        title: t(lang, 'payment_received_title'),
        message: t(lang, 'payment_received_body', { amount: paymentAmount, currency: '₪', quantity: '', unit: '' }),
        type: 'payment',
        referenceId: paymentRes.rows[0].id,
        referenceType: 'payment',
        notificationKey: 'notification.payment.received',
        params: { amount: paymentAmount }
      });

      return { newDebt, paymentId: paymentRes.rows[0].id };
    });

    res.json({
      success: true,
      message: 'Payment recorded successfully',
      data: result
    });
  } catch (error) {
    logger.error('Record payment error:', error);
    res.status(error.message.includes('not found') ? 404 : 500).json({
      success: false,
      message: error.message || 'Failed to record payment'
    });
  }
};

module.exports = {
  recordPayment
};
