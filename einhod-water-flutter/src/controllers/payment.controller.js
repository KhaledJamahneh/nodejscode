// src/controllers/payment.controller.js
const { query, transaction } = require('../config/database');
const logger = require('../utils/logger');

/**
 * POST /api/v1/payments/record
 * Record a client payment and reduce debt
 */
const recordPayment = async (req, res) => {
  try {
    const { client_id, amount, payment_method, notes } = req.body;

    if (!client_id || !amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid client_id and positive amount are required'
      });
    }

    const result = await transaction(async (client) => {
      // 1. Lock the client profile row to prevent race conditions on debt
      const profileRes = await client.query(
        'SELECT current_debt, user_id FROM client_profiles WHERE id = $1 FOR UPDATE',
        [client_id]
      );

      if (profileRes.rows.length === 0) {
        throw new Error('Client profile not found');
      }

      const currentDebt = parseFloat(profileRes.rows[0].current_debt);
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

      // 4. Create notification
      await client.query(
        `INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
         VALUES ($1, 'Payment Received', $2, 'payment', $3, 'payment')`,
        [
          userId,
          `We have received your payment of ₪${paymentAmount}. Your new balance is ₪${newDebt}.`,
          paymentRes.rows[0].id
        ]
      );

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
