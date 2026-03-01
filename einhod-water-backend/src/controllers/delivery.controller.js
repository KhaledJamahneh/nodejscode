// src/controllers/delivery.controller.js
// Delivery request management: create, view, update, cancel requests

const { query, transaction } = require('../config/database');
const logger = require('../utils/logger');
const { getStatusCode } = require('../middleware/error-handler.middleware');
const { t, getUnit } = require('../utils/i18n');
const notificationService = require('../services/notification.service');

/**
 * POST /api/v1/deliveries/request
 * Create a new delivery request
 */
const createDeliveryRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { priority, requested_gallons, payment_method, notes } = req.body;

    logger.info('Create delivery request attempt:', { userId, body: req.body });

    // Validate required fields
    if (!payment_method) {
      logger.warn('Missing payment_method', { userId });
      return res.status(400).json({
        success: false,
        message: 'payment_method is required'
      });
    }

    if (!requested_gallons || requested_gallons <= 0) {
      logger.warn('Invalid requested_gallons', { userId, requested_gallons });
      return res.status(400).json({
        success: false,
        message: 'requested_gallons must be greater than 0'
      });
    }

    const request = await transaction(async (client) => {
      // 1. Get client profile and system config (LOCK ROW)
      const clientResult = await client.query(
        `SELECT cp.id, cp.remaining_coupons, cp.subscription_type, 
                cp.current_debt, u.is_active, u.preferred_language
         FROM client_profiles cp
         JOIN users u ON cp.user_id = u.id
         WHERE cp.user_id = $1 FOR UPDATE`,
        [userId]
      );

      if (clientResult.rows.length === 0) {
        throw new Error('Client profile not found');
      }

      const clientData = clientResult.rows[0];

      // Get system config
      const configResult = await client.query(
        `SELECT setting_key as key, setting_value as value FROM system_settings WHERE setting_key IN ('max_pending_requests', 'debt_limit_ils')`
      );
      const config = Object.fromEntries(configResult.rows.map(r => [r.key, r.value]));
      const maxPendingRequests = parseInt(config.max_pending_requests || '3');
      const debtLimit = parseFloat(config.debt_limit_ils || '10000');

      // 2. Check if client account is active
      if (!clientData.is_active) {
        const error = new Error('Your account is currently inactive. Please contact support.');
        error.status = 403;
        throw error;
      }

      // 3. Validate payment method matches subscription type
      if (payment_method === 'coupon_book' && clientData.subscription_type !== 'coupon_book') {
        const error = new Error('Cash subscription clients cannot use coupon payment.');
        error.status = 400;
        throw error;
      }

      if (payment_method !== 'coupon_book' && clientData.subscription_type === 'coupon_book') {
        const error = new Error('Coupon subscription clients must use coupon payment.');
        error.status = 400;
        throw error;
      }

      // 4. Check debt limit for cash subscriptions
      if (clientData.subscription_type === 'cash' && parseFloat(clientData.current_debt) >= debtLimit) {
        const error = new Error(`Credit limit reached. Please pay your outstanding balance of ₪${clientData.current_debt} to continue.`);
        error.status = 403;
        throw error;
      }

      // 5. Check coupon balance for coupon subscriptions (if using coupon payment)
      if (payment_method === 'coupon_book') {
        const couponsNeeded = Math.ceil(requested_gallons / 20);
        if (clientData.remaining_coupons < couponsNeeded) {
          const error = new Error(`Insufficient coupons. You need ${couponsNeeded} coupons but only have ${clientData.remaining_coupons}.`);
          error.status = 400;
          throw error;
        }
      }

      // 6. Check for pending requests limit
      const pendingRequests = await client.query(
        `SELECT COUNT(*) as count 
         FROM delivery_requests 
         WHERE client_id = $1 AND status = 'pending'`,
        [clientData.id]
      );

      if (parseInt(pendingRequests.rows[0].count) >= maxPendingRequests) {
        const error = new Error(`You already have ${maxPendingRequests} pending requests. Please wait for them to be processed.`);
        error.status = 400;
        throw error;
      }

      // 8. Create the delivery request
      const result = await client.query(
        `INSERT INTO delivery_requests (
          client_id, priority, requested_gallons, payment_method, notes, status
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, client_id, priority, requested_gallons, payment_method, request_date, status, notes`,
        [clientData.id, priority || 'non_urgent', requested_gallons, payment_method, notes, 'pending']
      );

      const newRequest = result.rows[0];

      // 9. Create notification (Tier 1 & Tier 2)
      try {
        const lang = clientData.preferred_language || 'en';
        const unit = getUnit(lang, 'gallon', requested_gallons);
        
        await notificationService.createNotification({
          userId,
          title: t(lang, 'request_submitted_title'),
          message: t(lang, 'request_submitted_body', { amount: requested_gallons, unit }),
          type: 'delivery_status',
          referenceId: newRequest.id,
          referenceType: 'delivery_request',
          notificationKey: 'notification.request.submitted', // For frontend localization
          params: { amount: requested_gallons, unit }
        });
      } catch (notifError) {
        logger.warn('Non-blocking notification failure in createDeliveryRequest:', notifError);
      }

      return newRequest;
    });

    logger.info('Delivery request created:', {
      userId,
      requestId: request.id,
      priority: request.priority,
      gallons: requested_gallons
    });

    res.status(201).json({
      success: true,
      message: 'Delivery request submitted successfully',
      data: request
    });
  } catch (error) {
    logger.error('Create delivery request error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: error.message || 'Failed to create delivery request'
    });
  }
};

/**
 * GET /api/v1/deliveries/requests
 * Get all delivery requests for the current client
 */
const getClientRequests = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, limit = 20, offset = 0 } = req.query;

    // Get client profile ID
    const clientResult = await query(
      'SELECT id FROM client_profiles WHERE user_id = $1',
      [userId]
    );

    if (clientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    const clientId = clientResult.rows[0].id;

    // Build query based on filters
    let queryText = `
      SELECT 
        dr.id,
        dr.priority,
        dr.requested_gallons,
        dr.request_date,
        dr.status,
        dr.notes,
        dr.created_at,
        dr.updated_at,
        w.full_name as assigned_worker_name,
        u.phone_number as worker_phone
      FROM delivery_requests dr
      LEFT JOIN worker_profiles w ON dr.assigned_worker_id = w.id
      LEFT JOIN users u ON w.user_id = u.id
      WHERE dr.client_id = $1
    `;

    const queryParams = [clientId];
    let paramCount = 1;

    if (status) {
      paramCount++;
      queryText += ` AND dr.status = $${paramCount}`;
      queryParams.push(status);
    }

    queryText += ` ORDER BY 
      CASE dr.priority 
        WHEN 'urgent' THEN 1 
        WHEN 'mid_urgent' THEN 2 
        WHEN 'non_urgent' THEN 3 
      END,
      dr.request_date DESC
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;

    const safeLimit = Math.min(parseInt(limit) || 20, 100);
    const safeOffset = Math.max(parseInt(offset) || 0, 0);
    queryParams.push(safeLimit, safeOffset);

    const result = await query(queryText, queryParams);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM delivery_requests WHERE client_id = $1';
    const countParams = [clientId];

    if (status) {
      countQuery += ' AND status = $2';
      countParams.push(status);
    }

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        requests: result.rows,
        pagination: {
          total,
          limit: safeLimit,
          offset: safeOffset,
          has_more: safeOffset + result.rows.length < total
        }
      }
    });
  } catch (error) {
    logger.error('Get client requests error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get delivery requests'
    });
  }
};

/**
 * GET /api/v1/deliveries/requests/:id
 * Get a specific delivery request by ID
 */
const getRequestById = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;

    // Get client profile ID
    const clientResult = await query(
      'SELECT id FROM client_profiles WHERE user_id = $1',
      [userId]
    );

    if (clientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    const clientId = clientResult.rows[0].id;

    // Get the request
    const result = await query(
      `SELECT 
        dr.id,
        dr.priority,
        dr.requested_gallons,
        dr.request_date,
        dr.status,
        dr.notes,
        dr.created_at,
        dr.updated_at,
        w.full_name as assigned_worker_name,
        u.phone_number as worker_phone,
        u.email as worker_email
      FROM delivery_requests dr
      LEFT JOIN worker_profiles w ON dr.assigned_worker_id = w.id
      LEFT JOIN users u ON w.user_id = u.id
      WHERE dr.id = $1 AND dr.client_id = $2`,
      [requestId, clientId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Delivery request not found'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Get request by ID error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get delivery request'
    });
  }
};

/**
 * PATCH /api/v1/deliveries/requests/:id
 * Update a delivery request (only if pending)
 */
const updateDeliveryRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;
    const { priority, requested_gallons, notes } = req.body;

    // Get client profile ID
    const clientResult = await query(
      'SELECT id FROM client_profiles WHERE user_id = $1',
      [userId]
    );

    if (clientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    const clientId = clientResult.rows[0].id;

    // Check if request exists and is pending
    const checkResult = await query(
      'SELECT id, status FROM delivery_requests WHERE id = $1 AND client_id = $2',
      [requestId, clientId]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Delivery request not found'
      });
    }

    if (checkResult.rows[0].status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Can only update pending requests'
      });
    }

    // Build update query
    const updateFields = [];
    const updateValues = [];
    let paramCounter = 1;

    if (priority) {
      updateFields.push(`priority = $${paramCounter++}`);
      updateValues.push(priority);
    }
    if (requested_gallons) {
      updateFields.push(`requested_gallons = $${paramCounter++}`);
      updateValues.push(requested_gallons);
    }
    if (notes !== undefined) {
      updateFields.push(`notes = $${paramCounter++}`);
      updateValues.push(notes);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }

    updateValues.push(requestId, clientId);

    const result = await query(
      `UPDATE delivery_requests 
       SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $${paramCounter++} AND client_id = $${paramCounter++}
       RETURNING *`,
      updateValues
    );

    logger.info('Delivery request updated:', {
      userId,
      requestId,
      updates: { priority, requested_gallons }
    });

    res.json({
      success: true,
      message: 'Delivery request updated successfully',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Update delivery request error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update delivery request'
    });
  }
};

/**
 * DELETE /api/v1/deliveries/requests/:id
 * Cancel a delivery request (only if pending)
 */
const cancelDeliveryRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;

    // Get client profile ID
    const clientResult = await query(
      'SELECT id FROM client_profiles WHERE user_id = $1',
      [userId]
    );

    if (clientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    const clientId = clientResult.rows[0].id;

    // Check if request exists and is pending
    const checkResult = await query(
      `SELECT dr.id, dr.status, dr.priority, u.preferred_language 
       FROM delivery_requests dr
       JOIN client_profiles cp ON dr.client_id = cp.id
       JOIN users u ON cp.user_id = u.id
       WHERE dr.id = $1 AND dr.client_id = $2 FOR UPDATE`,
      [requestId, clientId]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Delivery request not found'
      });
    }

    if (checkResult.rows[0].status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Can only cancel pending requests'
      });
    }

    // Update status to cancelled
    await query(
      `UPDATE delivery_requests 
       SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1`,
      [requestId]
    );

    // Create notification
    const lang = checkResult.rows[0].preferred_language || 'en';
    await query(
      `INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
       VALUES ($1, $2, $3, 'delivery_status', $4, 'delivery_request')`,
      [userId, t(lang, 'request_cancelled_title'), t(lang, 'request_cancelled_body'), requestId]
    );

    logger.info('Delivery request cancelled:', { userId, requestId });

    res.json({
      success: true,
      message: 'Delivery request cancelled successfully'
    });
  } catch (error) {
    logger.error('Cancel delivery request error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to cancel delivery request'
    });
  }
};

/**
 * GET /api/v1/deliveries/history
 * Get completed delivery history for the client
 */
const getDeliveryHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 20, offset = 0, start_date, end_date } = req.query;

    // Get client profile ID
    const clientResult = await query(
      'SELECT id FROM client_profiles WHERE user_id = $1',
      [userId]
    );

    if (clientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    const clientId = clientResult.rows[0].id;

    // Build query
    let queryText = `
      SELECT 
        d.id,
        d.delivery_date,
        d.actual_delivery_time,
        d.gallons_delivered,
        d.status,
        d.notes,
        d.photo_url,
        w.full_name as worker_name,
        u.phone_number as worker_phone
      FROM deliveries d
      LEFT JOIN worker_profiles w ON d.worker_id = w.id
      LEFT JOIN users u ON w.user_id = u.id
      WHERE d.client_id = $1
    `;

    const queryParams = [clientId];
    let paramCount = 1;

    if (start_date) {
      paramCount++;
      queryText += ` AND d.delivery_date >= $${paramCount}`;
      queryParams.push(start_date);
    }

    if (end_date) {
      paramCount++;
      queryText += ` AND d.delivery_date <= $${paramCount}`;
      queryParams.push(end_date);
    }

    queryText += ` ORDER BY d.delivery_date DESC, d.actual_delivery_time DESC
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;

    const safeLimit = Math.min(parseInt(limit) || 20, 100);
    const safeOffset = Math.max(parseInt(offset) || 0, 0);
    queryParams.push(safeLimit, safeOffset);

    const result = await query(queryText, queryParams);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM deliveries WHERE client_id = $1';
    const countParams = [clientId];

    if (start_date) {
      countQuery += ' AND delivery_date >= $2';
      countParams.push(start_date);
    }
    if (end_date) {
      countQuery += ` AND delivery_date <= $${countParams.length + 1}`;
      countParams.push(end_date);
    }

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        deliveries: result.rows,
        pagination: {
          total,
          limit: safeLimit,
          offset: safeOffset,
          has_more: safeOffset + result.rows.length < total
        }
      }
    });
  } catch (error) {
    logger.error('Get delivery history error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get delivery history'
    });
  }
};

module.exports = {
  createDeliveryRequest,
  getClientRequests,
  getRequestById,
  updateDeliveryRequest,
  cancelDeliveryRequest,
  getDeliveryHistory
};
