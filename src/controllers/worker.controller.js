// src/controllers/worker.controller.js
// Worker schedule and delivery management

const { query, transaction } = require('../config/database');
const { getMessage: t, getUnit } = require('../utils/i18n');
const logger = require('../utils/logger');
const notificationService = require('../services/notification.service');
const { ValidationError, NotFoundError, AuthorizationError } = require('../utils/errors');

/**
 * Helper function to determine error status code
 */
const getErrorStatus = (error) => {
  if (error.statusCode) return error.statusCode;
  
  const msg = error.message || '';
  
  if (
    msg.includes('Insufficient inventory') ||
    msg.includes('Insufficient coupons') ||
    msg.includes('already completed') ||
    msg.includes('already assigned') ||
    msg.includes('exceeds request') ||
    msg.includes('cannot be negative') ||
    msg.includes('cannot exceed') ||
    msg.includes('must be') ||
    msg.includes('no longer in pending')
  ) return 400;
  
  if (
    msg.includes('not found') ||
    msg.includes('not assigned')
  ) return 404;
  
  if (
    msg.includes('inactive') ||
    msg.includes('cannot deliver to themselves')
  ) return 403;
  
  return 500;
};

/**
 * GET /api/v1/workers/profile
 * Get worker profile information
 */
const getWorkerProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT 
        u.id as user_id,
        u.username,
        u.email,
        u.phone_number,
        u.role,
        u.last_login,
        wp.id as profile_id,
        wp.full_name,
        wp.worker_type,
        wp.hire_date,
        wp.current_salary,
        wp.debt_advances,
        wp.vehicle_current_gallons,
        wp.gps_sharing_enabled,
        wp.is_dual_role,
        wp.created_at,
        wp.updated_at
      FROM users u
      JOIN worker_profiles wp ON u.id = wp.user_id
      WHERE u.id = $1 AND u.role && ARRAY['delivery_worker', 'onsite_worker']::user_role[]`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Get worker profile error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to get worker profile'
    });
  }
};

/**
 * GET /api/v1/workers/schedule/main
 * Get main delivery list (scheduled deliveries for today)
 */
const getMainSchedule = async (req, res) => {
  try {
    const userId = req.user.id;
    const { date } = req.query;

    // Get worker profile ID
    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;
    const targetDate = date || new Date().toISOString().split('T')[0];

    // Get scheduled deliveries and accepted requests
    const result = await query(
      `SELECT 
        d.id,
        d.delivery_date::text,
        d.scheduled_time::text,
        d.gallons_delivered as scheduled_gallons,
        d.status::text,
        d.notes,
        c.full_name as client_name,
        c.address as client_address,
        c.home_latitude as latitude,
        c.home_longitude as longitude,
        u.phone_number as client_phone,
        cp.remaining_coupons,
        cp.subscription_type::text,
        d.paid_coupons_count,
        false as is_request,
        'delivery' as task_type
      FROM deliveries d
      JOIN client_profiles c ON d.client_id = c.id
      JOIN users u ON c.user_id = u.id
      JOIN client_profiles cp ON c.id = cp.id
      WHERE d.worker_id = $1 
        AND d.delivery_date = $2
        AND d.is_main_list = true
        AND d.status::text = ANY($3::text[])

      UNION ALL

      SELECT 
        dr.id,
        $2::text as delivery_date,
        'ASAP' as scheduled_time,
        dr.requested_gallons as scheduled_gallons,
        dr.status::text,
        dr.notes,
        c.full_name as client_name,
        c.address as client_address,
        c.home_latitude as latitude,
        c.home_longitude as longitude,
        u.phone_number as client_phone,
        cp.remaining_coupons,
        cp.subscription_type::text,
        NULL::integer as paid_coupons_count,
        true as is_request,
        'delivery_request' as task_type
      FROM delivery_requests dr
      JOIN client_profiles c ON dr.client_id = c.id
      JOIN users u ON c.user_id = u.id
      JOIN client_profiles cp ON c.id = cp.id
      WHERE dr.assigned_worker_id = $1
        AND dr.status IN ('in_progress', 'completed')

      UNION ALL

      SELECT 
        cbr.id,
        $2::text as delivery_date,
        'COUPON' as scheduled_time,
        0 as scheduled_gallons,
        cbr.status::text,
        cbr.book_type as notes,
        c.full_name as client_name,
        c.address as client_address,
        c.home_latitude as latitude,
        c.home_longitude as longitude,
        u.phone_number as client_phone,
        cp.remaining_coupons,
        cp.subscription_type::text,
        NULL::integer as paid_coupons_count,
        true as is_request,
        'coupon_request' as task_type
      FROM coupon_book_requests cbr
      JOIN client_profiles c ON cbr.client_id = c.id
      JOIN users u ON c.user_id = u.id
      JOIN client_profiles cp ON c.id = cp.id
      WHERE cbr.assigned_worker_id = $1
        AND cbr.status IN ('assigned', 'in_progress')

      ORDER BY is_request ASC, scheduled_time ASC NULLS LAST`,
      [workerId, targetDate, ['pending', 'in_progress', 'completed']]
    );
    res.json({
      success: true,
      data: {
        date: targetDate,
        deliveries: result.rows,
        total: result.rows.length
      }
    });
  } catch (error) {
    logger.error('Get main schedule error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to get main schedule'
    });
  }
};

/**
 * GET /api/v1/workers/schedule/secondary
 * Get secondary list (on-demand delivery requests)
 */
const getSecondaryList = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get worker profile ID
    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;

    // Get delivery requests and unassigned scheduled deliveries
    const result = await query(
      `SELECT * FROM (
        SELECT 
          dr.id,
          dr.priority::text,
          dr.requested_gallons,
          dr.request_date::text,
          dr.status::text,
          dr.notes,
          c.full_name as client_name,
          c.address as client_address,
          c.home_latitude as latitude,
          c.home_longitude as longitude,
          u.phone_number as client_phone,
          cp.remaining_coupons,
          cp.subscription_type::text,
          CASE 
            WHEN dr.assigned_worker_id = $1 THEN true 
            ELSE false 
          END as assigned_to_me,
          true as is_request,
          'delivery_request' as task_type
        FROM delivery_requests dr
        JOIN client_profiles c ON dr.client_id = c.id
        JOIN users u ON c.user_id = u.id
        JOIN client_profiles cp ON c.id = cp.id
        WHERE dr.status = 'pending'
          AND (dr.assigned_worker_id IS NULL OR dr.assigned_worker_id = $1)
        
        UNION ALL
        
        SELECT 
          d.id,
          'non_urgent' as priority,
          d.gallons_delivered as requested_gallons,
          d.delivery_date::text as request_date,
          d.status::text,
          d.notes,
          c.full_name as client_name,
          c.address as client_address,
          c.home_latitude as latitude,
          c.home_longitude as longitude,
          u.phone_number as client_phone,
          cp.remaining_coupons,
          cp.subscription_type::text,
          false as assigned_to_me,
          false as is_request,
          'delivery' as task_type
        FROM deliveries d
        JOIN client_profiles c ON d.client_id = c.id
        JOIN users u ON c.user_id = u.id
        JOIN client_profiles cp ON c.id = cp.id
        WHERE d.status = 'pending'
          AND d.worker_id IS NULL
          AND d.is_main_list = true

        UNION ALL

        SELECT 
          cbr.id,
          'non_urgent' as priority,
          0 as requested_gallons,
          cbr.created_at::date::text as request_date,
          cbr.status::text,
          cbr.book_type as notes,
          c.full_name as client_name,
          c.address as client_address,
          c.home_latitude as latitude,
          c.home_longitude as longitude,
          u.phone_number as client_phone,
          cp.remaining_coupons,
          cp.subscription_type::text,
          CASE 
            WHEN cbr.assigned_worker_id = $1 THEN true 
            ELSE false 
          END as assigned_to_me,
          true as is_request,
          'coupon_request' as task_type
        FROM coupon_book_requests cbr
        JOIN client_profiles c ON cbr.client_id = c.id
        JOIN users u ON c.user_id = u.id
        JOIN client_profiles cp ON c.id = cp.id
        WHERE cbr.status = 'approved'
          AND (cbr.assigned_worker_id IS NULL OR cbr.assigned_worker_id = $1)
      ) AS combined_tasks
      ORDER BY 
        CASE priority 
          WHEN 'urgent' THEN 1 
          WHEN 'mid_urgent' THEN 2 
          WHEN 'non_urgent' THEN 3 
        END,
        request_date ASC`,
      [workerId]
    );

    res.json({
      success: true,
      data: {
        requests: result.rows,
        total: result.rows.length,
        urgent_count: result.rows.filter(r => r.priority === 'urgent').length,
        assigned_to_me: result.rows.filter(r => r.assigned_to_me).length
      }
    });
  } catch (error) {
    logger.error('Get secondary list error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to get secondary list'
    });
  }
};

/**
 * POST /api/v1/workers/deliveries/:id/start
 * Mark delivery as in progress
 */
const startDelivery = async (req, res) => {
  try {
    const userId = req.user.id;
    const deliveryId = req.params.id;

    // Get worker profile ID
    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;

    // Check if delivery exists and belongs to this worker
    const deliveryCheck = await query(
      'SELECT id, status FROM deliveries WHERE id = $1 AND worker_id = $2',
      [deliveryId, workerId]
    );

    if (deliveryCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Delivery not found or not assigned to you'
      });
    }

    if (deliveryCheck.rows[0].status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Delivery is not in pending status'
      });
    }

    // Update status to in_progress
    await query(
      `UPDATE deliveries 
       SET status = 'in_progress', updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1`,
      [deliveryId]
    );

    logger.info('Delivery started:', { userId, deliveryId });

    res.json({
      success: true,
      message: 'Delivery marked as in progress'
    });
  } catch (error) {
    logger.error('Start delivery error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to start delivery'
    });
  }
};

/**
 * POST /api/v1/workers/deliveries/:id/accept
 * Accept an unassigned scheduled delivery
 */
const acceptScheduledDelivery = async (req, res) => {
  try {
    const userId = req.user.id;
    const deliveryId = req.params.id;

    // Get worker profile ID
    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;

    await transaction(async (client) => {
      // 1. Lock delivery row and get details
      const deliveryRes = await client.query(
        `SELECT d.*, cp.user_id as client_user_id 
         FROM deliveries d
         JOIN client_profiles cp ON d.client_id = cp.id
         WHERE d.id = $1 FOR UPDATE`,
        [deliveryId]
      );

      if (deliveryRes.rows.length === 0) {
        throw new Error('Delivery not found');
      }

      const delivery = deliveryRes.rows[0];

      // 2. Self-delivery check
      const workerUser = await client.query('SELECT user_id FROM worker_profiles WHERE id = $1', [workerId]);
      if (workerUser.rows[0].user_id === delivery.client_user_id) {
        throw new Error('Workers cannot deliver to themselves');
      }

      // 3. Assignment check
      if (delivery.worker_id !== null && delivery.worker_id !== workerId) {
        throw new Error('Delivery is already assigned to another worker');
      }

      // 4. Update assignment and set to in_progress
      await client.query(
        `UPDATE deliveries 
         SET worker_id = $1, status = 'in_progress', updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [workerId, deliveryId]
      );

      // Notify client
      const clientDelivery = await client.query(
        `SELECT cp.user_id, u.preferred_language, wp.full_name as worker_name 
         FROM deliveries d
         JOIN client_profiles cp ON d.client_id = cp.id
         JOIN users u ON cp.user_id = u.id
         JOIN worker_profiles wp ON wp.id = $1
         WHERE d.id = $2`,
        [workerId, deliveryId]
      );
      
      const notification = await notificationService.createNotification({
        userId: clientDelivery.rows[0].user_id,
        title: t(clientDelivery.rows[0].preferred_language, 'scheduled_accepted_title'),
        message: t(clientDelivery.rows[0].preferred_language, 'scheduled_accepted_body', clientDelivery.rows[0].worker_name),
        type: 'delivery_status',
        referenceId: deliveryId,
        referenceType: 'delivery',
        dbClient: client,
        sendPush: false
      });

      return {
        userId: clientDelivery.rows[0].user_id,
        notification
      };
    });

    // Send push notification after transaction commits
    notificationService.sendPush(result.userId, result.notification);

    logger.info('Scheduled delivery accepted by worker and client notified:', { userId, deliveryId });

    res.json({
      success: true,
      message: 'Delivery accepted and client notified'
    });
  } catch (error) {
    logger.error('Accept scheduled delivery error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to accept delivery'
    });
  }
};

/**
 * POST /api/v1/workers/deliveries/:id/complete
 * Mark delivery as completed and record details
 */
const completeDelivery = async (req, res) => {
  try {
    const userId = req.user.id;
    const deliveryId = req.params.id;
    const {
      gallons_delivered,
      empty_gallons_returned,
      delivery_latitude,
      delivery_longitude,
      notes,
      photo_url,
      paid_coupons_count,
      paid_amount,
      total_price
    } = req.body;

    // Validate numeric inputs
    if (gallons_delivered === undefined || gallons_delivered === null) {
      return res.status(400).json({
        success: false,
        message: 'gallons_delivered is required'
      });
    }

    const gallonsNum = Number(gallons_delivered);
    if (isNaN(gallonsNum) || gallonsNum <= 0) {
      return res.status(400).json({
        success: false,
        message: 'gallons_delivered must be a positive number'
      });
    }

    if (empty_gallons_returned !== undefined && empty_gallons_returned !== null) {
      const emptyNum = Number(empty_gallons_returned);
      if (isNaN(emptyNum) || emptyNum < 0) {
        return res.status(400).json({
          success: false,
          message: 'empty_gallons_returned must be a non-negative number'
        });
      }
    }

    if (paid_amount !== undefined && paid_amount !== null) {
      const paidNum = Number(paid_amount);
      if (isNaN(paidNum) || paidNum < 0) {
        return res.status(400).json({
          success: false,
          message: 'paid_amount must be a non-negative number'
        });
      }
    }

    if (total_price !== undefined && total_price !== null) {
      const priceNum = Number(total_price);
      if (isNaN(priceNum) || priceNum < 0) {
        return res.status(400).json({
          success: false,
          message: 'total_price must be a non-negative number'
        });
      }
    }

    if (paid_coupons_count !== undefined && paid_coupons_count !== null) {
      const couponsNum = Number(paid_coupons_count);
      if (isNaN(couponsNum) || couponsNum < 0 || !Number.isInteger(couponsNum)) {
        return res.status(400).json({
          success: false,
          message: 'paid_coupons_count must be a non-negative integer'
        });
      }
    }

    // Get worker profile and language
    const workerResult = await query(
      "SELECT wp.id, COALESCE(u.preferred_language, 'en') as preferred_language FROM worker_profiles wp JOIN users u ON wp.user_id = u.id WHERE wp.user_id = $1",
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;
    const workerLang = workerResult.rows[0].preferred_language;

    const effectiveTotalPrice = total_price !== undefined ? total_price : (gallons_delivered * 10);

    await transaction(async (client) => {
      // 1. Lock worker profile to check and update inventory safely
      const workerLock = await client.query(
        'SELECT vehicle_current_gallons FROM worker_profiles WHERE id = $1 FOR UPDATE',
        [workerId]
      );
      
      const currentGallons = workerLock.rows[0].vehicle_current_gallons;
      if (currentGallons < gallons_delivered) {
        throw new ValidationError(t('error_insufficient_inventory', workerLang, { 
          current: currentGallons, 
          delivered: gallons_delivered, 
          unit: 'gallon',
          amount: currentGallons 
        }));
      }

      // 2. Check if delivery exists and belongs to this worker (LOCK client profile)
      const deliveryResult = await client.query(
        `SELECT d.id, d.client_id, d.status, d.gallons_delivered as requested_gallons, 
                c.subscription_type, c.remaining_coupons, c.gallons_on_hand, c.preferred_language, u.is_active
         FROM deliveries d
         JOIN client_profiles c ON d.client_id = c.id
         JOIN users u ON c.user_id = u.id
         WHERE d.id = $1 AND d.worker_id = $2
         FOR UPDATE OF c`,
        [deliveryId, workerId]
      );

      if (deliveryResult.rows.length === 0) {
        throw new NotFoundError(t('error_delivery_not_found', workerLang));
      }

      const delivery = deliveryResult.rows[0];

      if (!delivery.is_active) {
        throw new AuthorizationError(t('error_client_inactive', workerLang));
      }

      if (delivery.status === 'completed') {
        throw new ValidationError(t('error_already_completed', workerLang));
      }

      // 3. Business Logic Validations
      if (gallons_delivered > delivery.requested_gallons * 1.1) {
        throw new ValidationError(`Delivered amount (${gallons_delivered}) significantly exceeds request (${delivery.requested_gallons}). Max 10% over-delivery allowed.`);
      }
      if (paid_amount !== undefined && paid_amount > effectiveTotalPrice) {
        throw new ValidationError('Amount paid cannot exceed total price');
      }
      
      const maxReturnable = parseInt(gallons_delivered) + parseInt(delivery.gallons_on_hand || 0);
      if (empty_gallons_returned !== undefined && empty_gallons_returned > maxReturnable) {
        throw new ValidationError(`Empty gallons returned (${empty_gallons_returned}) cannot exceed total reserved gallons (${maxReturnable} = ${gallons_delivered} delivered + ${delivery.gallons_on_hand || 0} on hand)`);
      }

      // Check if payment columns exist
      const columnCheck = await client.query(
        "SELECT column_name FROM information_schema.columns WHERE table_name = 'deliveries' AND column_name = 'paid_amount'"
      );
      const hasPaymentColumns = columnCheck.rows.length > 0;
      
      logger.info('Completing delivery:', { 
        deliveryId, 
        hasPaymentColumns,
        paid_amount,
        total_price: effectiveTotalPrice,
        paid_coupons_count 
      });

      // Update delivery with idempotency check (enforce state transition)
      let updateResult;
      if (hasPaymentColumns) {
        updateResult = await client.query(
          `UPDATE deliveries 
           SET status = 'completed',
               gallons_delivered = $1,
               empty_gallons_returned = $2,
               actual_delivery_time = CURRENT_TIMESTAMP,
               delivery_latitude = $3,
               delivery_longitude = $4,
               notes = $5,
               photo_url = $6,
               paid_amount = $7,
               total_price = $8,
               paid_coupons_count = $9,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $10 AND status != 'completed'`,
          [gallons_delivered, empty_gallons_returned || 0, delivery_latitude, delivery_longitude, notes, photo_url, paid_amount || 0, effectiveTotalPrice, paid_coupons_count || 0, deliveryId]
        );
      } else {
        updateResult = await client.query(
          `UPDATE deliveries 
           SET status = 'completed',
               gallons_delivered = $1,
               empty_gallons_returned = $2,
               actual_delivery_time = CURRENT_TIMESTAMP,
               delivery_latitude = $3,
               delivery_longitude = $4,
               notes = $5,
               photo_url = $6,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $7 AND status != 'completed'`,
          [gallons_delivered, empty_gallons_returned || 0, delivery_latitude, delivery_longitude, notes, photo_url, deliveryId]
        );
      }
      
      // Idempotency check: If no rows updated, delivery was already completed
      if (updateResult.rowCount === 0) {
        throw new Error('Delivery is already completed');
      }

      // 5. Update client coupons/debt
      if (delivery.subscription_type === 'coupon_book') {
        const couponsUsed = paid_coupons_count !== undefined ? 
          parseInt(paid_coupons_count) : 
          Math.ceil(gallons_delivered / 20);
        
        // Re-check balance with fresh data from the locked row
        const freshBalance = await client.query(
          'SELECT remaining_coupons FROM client_profiles WHERE id = $1 FOR UPDATE',
          [delivery.client_id]
        );
        
        const currentCoupons = freshBalance.rows[0].remaining_coupons;
        if (currentCoupons < couponsUsed) {
          throw new Error(t('error_insufficient_coupons', workerLang, { remaining: currentCoupons, required: couponsUsed }));
        }

        await client.query(
          `UPDATE client_profiles 
           SET remaining_coupons = remaining_coupons - $1,
               monthly_usage_gallons = monthly_usage_gallons + $2,
               gallons_on_hand = gallons_on_hand + $2 - $3,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $4`,
          [couponsUsed, gallons_delivered, empty_gallons_returned || 0, delivery.client_id]
        );
      } else {
        // For cash subscriptions, update usage and debt if columns exist
        const price = Math.round((effectiveTotalPrice || 0) * 100) / 100;
        const paid = Math.round((paid_amount || 0) * 100) / 100;
        const debtChange = Math.round((price - paid) * 100) / 100;

        // Explicit lock for debt update
        await client.query(
          'SELECT current_debt FROM client_profiles WHERE id = $1 FOR UPDATE',
          [delivery.client_id]
        );

        await client.query(
          `UPDATE client_profiles 
           SET monthly_usage_gallons = monthly_usage_gallons + $1,
               current_debt = current_debt + $2,
               gallons_on_hand = gallons_on_hand + $1 - $3,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $4`,
          [gallons_delivered, debtChange, empty_gallons_returned || 0, delivery.client_id]
        );
      }

      // Update worker vehicle inventory
      await client.query(
        `UPDATE worker_profiles 
         SET vehicle_current_gallons = vehicle_current_gallons - $1,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        [gallons_delivered, workerId]
      );

      // Create notification for client (database insert is fast, OK inside transaction)
      const clientUser = await client.query(
        'SELECT user_id FROM client_profiles WHERE id = $1',
        [delivery.client_id]
      );

      if (clientUser.rows.length === 0) {
        throw new Error('Client profile not found');
      }

      const notification = await notificationService.createNotification({
        userId: clientUser.rows[0].user_id,
        title: t(delivery.preferred_language, 'delivery_completed_title'),
        message: t(delivery.preferred_language, 'delivery_completed_body', {
          amount: gallons_delivered,
          unit: getUnit(delivery.preferred_language, 'gallon', gallons_delivered)
        }),
        type: 'delivery_status',
        referenceId: deliveryId,
        referenceType: 'delivery',
        notificationKey: 'notification.delivery.completed',
        params: { amount: gallons_delivered },
        dbClient: client, // INSIDE transaction
        sendPush: false // DON'T send push yet, wait for commit
      });
      
      // Return data needed for deferred push
      return {
        userId: clientUser.rows[0].user_id,
        notification
      };
    });

    // ✅ CORRECT: External push notification AFTER transaction commits
    // Database state is permanent (delivery marked completed)
    notificationService.sendPush(result.userId, result.notification);

    logger.info('Delivery completed:', { userId, deliveryId, gallons_delivered });

    res.json({
      success: true,
      message: 'Delivery completed successfully'
    });
  } catch (error) {
    logger.error('Complete delivery error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: error.message || 'Failed to complete delivery'
    });
  }
};

/**
 * POST /api/v1/workers/requests/:id/accept
 * Accept a delivery request from secondary list
 */
const acceptRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;

    // Get worker profile ID
    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;

    await transaction(async (client) => {
      // 1. Lock request row and get details
      const requestRes = await client.query(
        `SELECT dr.*, cp.user_id as client_user_id 
         FROM delivery_requests dr
         JOIN client_profiles cp ON dr.client_id = cp.id
         WHERE dr.id = $1 FOR UPDATE`,
        [requestId]
      );

      if (requestRes.rows.length === 0) {
        throw new Error('Delivery request not found');
      }

      const request = requestRes.rows[0];

      // 2. Self-delivery check
      const workerUser = await client.query('SELECT user_id FROM worker_profiles WHERE id = $1', [workerId]);
      if (workerUser.rows[0].user_id === request.client_user_id) {
        throw new Error('Workers cannot deliver to themselves');
      }

      // 3. Status/Assignment check
      if (request.status !== 'pending') {
        throw new Error('Request is no longer in pending status');
      }

      if (request.assigned_worker_id && request.assigned_worker_id !== workerId) {
        throw new Error('Request is already assigned to another worker');
      }

      // 4. Update assignment
      await client.query(
        `UPDATE delivery_requests 
         SET assigned_worker_id = $1, 
             status = 'in_progress',
             updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [workerId, requestId]
      );

      // Notify client
      const clientRequest = await client.query(
        `SELECT cp.user_id, u.preferred_language, wp.full_name as worker_name 
         FROM delivery_requests dr
         JOIN client_profiles cp ON dr.client_id = cp.id
         JOIN users u ON cp.user_id = u.id
         JOIN worker_profiles wp ON wp.id = $1
         WHERE dr.id = $2`,
        [workerId, requestId]
      );
      
      const notification = await notificationService.createNotification({
        userId: clientRequest.rows[0].user_id,
        title: t(clientRequest.rows[0].preferred_language, 'request_accepted_title'),
        message: t(clientRequest.rows[0].preferred_language, 'request_accepted_body', clientRequest.rows[0].worker_name),
        type: 'delivery_status',
        referenceId: requestId,
        referenceType: 'delivery_request',
        dbClient: client,
        sendPush: false
      });

      return {
        userId: clientRequest.rows[0].user_id,
        notification
      };
    });

    // Send push notification after transaction commits
    notificationService.sendPush(result.userId, result.notification);

    logger.info('Request accepted and client notified:', { userId, requestId });

    res.json({
      success: true,
      message: 'Delivery request accepted and client notified'
    });
  } catch (error) {
    logger.error('Accept request error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to accept request'
    });
  }
};

/**
 * POST /api/v1/workers/requests/:id/complete
 * Complete a delivery request from secondary list
 */
const completeRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;
    const {
      gallons_delivered,
      empty_gallons_returned,
      delivery_latitude,
      delivery_longitude,
      notes,
      photo_url,
      paid_coupons_count,
      paid_amount,
      total_price
    } = req.body;

    // Get worker profile and language
    const workerResult = await query(
      "SELECT wp.id, COALESCE(u.preferred_language, 'en') as preferred_language FROM worker_profiles wp JOIN users u ON wp.user_id = u.id WHERE wp.user_id = $1",
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;
    const workerLang = workerResult.rows[0].preferred_language;

    const result = await transaction(async (client) => {
      // 1. Lock worker profile to check and update inventory safely
      const workerLock = await client.query(
        'SELECT vehicle_current_gallons FROM worker_profiles WHERE id = $1 FOR UPDATE',
        [workerId]
      );
      
      const currentGallons = workerLock.rows[0].vehicle_current_gallons;
      if (currentGallons < gallons_delivered) {
        throw new Error(t('error_insufficient_inventory', workerLang, { 
          current: currentGallons, 
          delivered: gallons_delivered, 
          unit: 'gallon',
          amount: currentGallons 
        }));
      }

      // 2. Get request details
      const requestResult = await client.query(
        `SELECT dr.id, dr.client_id, dr.assigned_worker_id, dr.status, dr.requested_gallons,
                c.subscription_type, c.remaining_coupons, c.gallons_on_hand, u.preferred_language, u.is_active
         FROM delivery_requests dr
         JOIN client_profiles c ON dr.client_id = c.id
         JOIN users u ON c.user_id = u.id
         WHERE dr.id = $1
         FOR UPDATE OF c`,
        [requestId]
      );

      if (requestResult.rows.length === 0) {
        throw new Error(t('error_request_not_found', workerLang));
      }

      const request = requestResult.rows[0];

      if (!request.is_active) {
        throw new Error(t('error_client_inactive', workerLang));
      }

      if (request.assigned_worker_id !== workerId) {
        throw new Error(t('error_not_assigned', workerLang));
      }

      if (request.status === 'completed') {
        throw new Error(t('error_already_completed', workerLang));
      }

      // 3. Business Logic Validations
      const effectiveTotalPrice = total_price !== undefined ? total_price : (gallons_delivered * 10);

      if (gallons_delivered > request.requested_gallons * 1.1) {
        throw new Error(`Delivered amount (${gallons_delivered}) significantly exceeds request (${request.requested_gallons}). Max 10% over-delivery allowed.`);
      }
      if (paid_amount !== undefined && paid_amount < 0) {
        throw new Error('Amount paid cannot be negative');
      }
      if (paid_amount !== undefined && effectiveTotalPrice !== undefined && paid_amount > effectiveTotalPrice) {
        throw new Error('Amount paid cannot exceed total price');
      }
      if (empty_gallons_returned !== undefined && empty_gallons_returned < 0) {
        throw new Error('Empty gallons returned cannot be negative');
      }
      
      const maxReturnable = parseInt(gallons_delivered) + parseInt(request.gallons_on_hand || 0);
      if (empty_gallons_returned !== undefined && empty_gallons_returned > maxReturnable) {
        throw new Error(`Empty gallons returned (${empty_gallons_returned}) cannot exceed total reserved gallons (${maxReturnable} = ${gallons_delivered} delivered + ${request.gallons_on_hand || 0} on hand)`);
      }

      // Check if payment columns exist
      const columnCheck = await client.query(
        "SELECT column_name FROM information_schema.columns WHERE table_name = 'deliveries' AND column_name = 'paid_amount'"
      );
      const hasPaymentColumns = columnCheck.rows.length > 0;

      // Create delivery record
      let deliveryResult;
      if (hasPaymentColumns) {
        deliveryResult = await client.query(
          `INSERT INTO deliveries (
            client_id, worker_id, delivery_date, actual_delivery_time,
            gallons_delivered, empty_gallons_returned, delivery_latitude, delivery_longitude,
            status, notes, photo_url, is_main_list, request_id, paid_amount, total_price
          ) VALUES ($1, $2, CURRENT_DATE, CURRENT_TIMESTAMP, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
          RETURNING id`,
          [
            request.client_id, workerId, gallons_delivered,
            empty_gallons_returned || 0,
            delivery_latitude, delivery_longitude, 'completed',
            notes, photo_url, false, requestId,
            paid_amount || 0, effectiveTotalPrice
          ]
        );
      } else {
        deliveryResult = await client.query(
          `INSERT INTO deliveries (
            client_id, worker_id, delivery_date, actual_delivery_time,
            gallons_delivered, empty_gallons_returned, delivery_latitude, delivery_longitude,
            status, notes, photo_url, is_main_list, request_id
          ) VALUES ($1, $2, CURRENT_DATE, CURRENT_TIMESTAMP, $3, $4, $5, $6, $7, $8, $9, $10, $11)
          RETURNING id`,
          [
            request.client_id, workerId, gallons_delivered,
            empty_gallons_returned || 0,
            delivery_latitude, delivery_longitude, 'completed',
            notes, photo_url, false, requestId
          ]
        );
      }

      // Update request status
      await client.query(
        `UPDATE delivery_requests 
         SET status = 'completed', updated_at = CURRENT_TIMESTAMP 
         WHERE id = $1`,
        [requestId]
      );

      // Update worker vehicle inventory
      await client.query(
        `UPDATE worker_profiles 
         SET vehicle_current_gallons = vehicle_current_gallons - $1,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        [gallons_delivered, workerId]
      );

      // Update client coupons if using coupon book
      if (request.subscription_type === 'coupon_book') {
        const couponsUsed = paid_coupons_count !== undefined ? 
          parseInt(paid_coupons_count) : 
          Math.ceil(gallons_delivered / 20);
        
        // Re-check balance with fresh data from the locked row
        const freshBalance = await client.query(
          'SELECT remaining_coupons FROM client_profiles WHERE id = $1 FOR UPDATE',
          [request.client_id]
        );
        
        const currentCoupons = freshBalance.rows[0].remaining_coupons;
        if (currentCoupons < couponsUsed) {
          throw new Error(t('error_insufficient_coupons', workerLang, { remaining: currentCoupons, required: couponsUsed }));
        }

        await client.query(
          `UPDATE client_profiles 
           SET remaining_coupons = remaining_coupons - $1,
               monthly_usage_gallons = monthly_usage_gallons + $2,
               gallons_on_hand = gallons_on_hand + $2 - $3,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $4`,
          [couponsUsed, gallons_delivered, empty_gallons_returned || 0, request.client_id]
        );
      } else {
        const price = Math.round((effectiveTotalPrice || 0) * 100) / 100;
        const paid = Math.round((paid_amount || 0) * 100) / 100;
        const debtChange = Math.round((price - paid) * 100) / 100;

        // Explicit lock for debt update
        await client.query(
          'SELECT current_debt FROM client_profiles WHERE id = $1 FOR UPDATE',
          [request.client_id]
        );

        await client.query(
          `UPDATE client_profiles 
           SET monthly_usage_gallons = monthly_usage_gallons + $1,
               current_debt = current_debt + $2,
               gallons_on_hand = gallons_on_hand + $1 - $3,
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $4`,
          [gallons_delivered, debtChange, empty_gallons_returned || 0, request.client_id]
        );
      }

      // Create notification for client
      const clientUser = await client.query(
        'SELECT user_id FROM client_profiles WHERE id = $1',
        [request.client_id]
      );

      const notification = await notificationService.createNotification({
        userId: clientUser.rows[0].user_id,
        title: t(request.preferred_language, 'delivery_completed_title'),
        message: t(request.preferred_language, 'delivery_completed_body', {
          amount: gallons_delivered,
          unit: getUnit(request.preferred_language, 'gallon', gallons_delivered)
        }),
        type: 'delivery_status',
        referenceId: requestId,
        referenceType: 'delivery_request',
        dbClient: client,
        sendPush: false
      });

      return {
        userId: clientUser.rows[0].user_id,
        notification
      };
    });

    // Send push notification after transaction commits
    notificationService.sendPush(result.userId, result.notification);

    logger.info('Request completed:', { userId, requestId, gallons_delivered });

    res.json({
      success: true,
      message: 'Delivery request completed successfully'
    });
  } catch (error) {
    logger.error('Complete request error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: error.message || 'Failed to complete request'
    });
  }
};

/**
 * PUT /api/v1/workers/vehicle/inventory
 * Update vehicle gallons inventory
 */
const updateVehicleInventory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { current_gallons } = req.body;

    await query(
      `UPDATE worker_profiles 
       SET vehicle_current_gallons = $1, updated_at = CURRENT_TIMESTAMP 
       WHERE user_id = $2`,
      [current_gallons, userId]
    );

    logger.info('Vehicle inventory updated:', { userId, current_gallons });

    res.json({
      success: true,
      message: 'Vehicle inventory updated',
      data: { current_gallons }
    });
  } catch (error) {
    logger.error('Update vehicle inventory error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to update vehicle inventory'
    });
  }
};

/**
 * PUT /api/v1/workers/gps/toggle
 * Toggle GPS sharing on/off
 */
const toggleGPSSharing = async (req, res) => {
  try {
    const userId = req.user.id;
    const { enabled } = req.body;

    await query(
      `UPDATE worker_profiles 
       SET gps_sharing_enabled = $1, updated_at = CURRENT_TIMESTAMP 
       WHERE user_id = $2`,
      [enabled, userId]
    );

    logger.info('GPS sharing toggled:', { userId, enabled });

    res.json({
      success: true,
      message: `GPS sharing ${enabled ? 'enabled' : 'disabled'}`,
      data: { gps_sharing_enabled: enabled }
    });
  } catch (error) {
    logger.error('Toggle GPS sharing error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to toggle GPS sharing'
    });
  }
};

/**
 * GET /api/v1/workers/onsite/stations
 * Get all filling stations
 */
const getFillingStations = async (req, res) => {
  try {
    const result = await query(
      'SELECT id, name, address, current_status FROM filling_stations ORDER BY name ASC'
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    logger.error('Get filling stations error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to get filling stations'
    });
  }
};

/**
 * POST /api/v1/workers/onsite/sessions/start
 * Start a filling session
 */
const startFillingSession = async (req, res) => {
  try {
    const userId = req.user.id;
    const { station_id } = req.body;

    // Get worker profile ID
    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    const workerId = workerResult.rows[0].id;

    const result = await query(
      `INSERT INTO filling_sessions (station_id, worker_id, start_time, gallons_filled)
       VALUES ($1, $2, CURRENT_TIMESTAMP, 0)
       RETURNING id, start_time`,
      [station_id, workerId]
    );

    res.status(201).json({
      success: true,
      message: 'Filling session started',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Start filling session error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to start filling session'
    });
  }
};

/**
 * POST /api/v1/workers/onsite/sessions/:id/complete
 * Complete a filling session
 */
const completeFillingSession = async (req, res) => {
  try {
    const sessionId = req.params.id;
    const { gallons_filled } = req.body;

    const result = await query(
      `UPDATE filling_sessions 
       SET completion_time = CURRENT_TIMESTAMP, 
           gallons_filled = $1 
       WHERE id = $2
       RETURNING *`,
      [gallons_filled, sessionId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Filling session not found'
      });
    }

    res.json({
      success: true,
      message: 'Filling session completed',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Complete filling session error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to complete filling session'
    });
  }
};

/**
 * GET /api/v1/workers/onsite/sessions/recent
 * Get recent filling sessions for the worker
 */
const getRecentFillingSessions = async (req, res) => {
  try {
    const userId = req.user.id;

    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    const workerId = workerResult.rows[0].id;

    const result = await query(
      `SELECT fs.id, fs.gallons_filled, fs.completion_time, st.name as station_name
       FROM filling_sessions fs
       JOIN filling_stations st ON fs.station_id = st.id
       WHERE fs.worker_id = $1 AND fs.completion_time IS NOT NULL
       ORDER BY fs.completion_time DESC
       LIMIT 20`,
      [workerId]
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    logger.error('Get recent filling sessions error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to get filling history'
    });
  }
};

/**
 * PATCH /api/v1/workers/onsite/sessions/:id
 * Update an existing filling session (edit gallons)
 */
const updateFillingSession = async (req, res) => {
  try {
    const sessionId = req.params.id;
    const { gallons_filled } = req.body;
    const userId = req.user.id;

    // Get worker profile ID to verify ownership
    const workerResult = await query('SELECT id FROM worker_profiles WHERE user_id = $1', [userId]);
    const workerId = workerResult.rows[0].id;

    const result = await query(
      `UPDATE filling_sessions 
       SET gallons_filled = $1, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $2 AND worker_id = $3
       RETURNING *`,
      [gallons_filled, sessionId, workerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Filling session not found or access denied'
      });
    }

    res.json({
      success: true,
      message: 'Filling session updated',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Update filling session error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to update filling session'
    });
  }
};

/**
 * DELETE /api/v1/workers/onsite/sessions/:id
 * Delete a filling session
 */
const deleteFillingSession = async (req, res) => {
  try {
    const sessionId = req.params.id;
    const userId = req.user.id;

    // Get worker profile ID to verify ownership
    const workerResult = await query('SELECT id FROM worker_profiles WHERE user_id = $1', [userId]);
    const workerId = workerResult.rows[0].id;

    const result = await query(
      'DELETE FROM filling_sessions WHERE id = $1 AND worker_id = $2 RETURNING id',
      [sessionId, workerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Filling session not found or access denied'
      });
    }

    res.json({
      success: true,
      message: 'Filling session deleted'
    });
  } catch (error) {
    logger.error('Delete filling session error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to delete filling session'
    });
  }
};

/**
 * PUT /api/v1/workers/onsite/stations/:id
 * Update filling station status
 */
const updateFillingStationStatus = async (req, res) => {
  try {
    const { id } = req.params;
    let { status } = req.body;

    // Map camelCase status to snake_case DB enum if necessary
    const statusMap = {
      'open': 'open',
      'temporarilyClosed': 'closed_temporarily',
      'closedUntilTomorrow': 'closed_until_tomorrow',
      'closed_temporarily': 'closed_temporarily',
      'closed_until_tomorrow': 'closed_until_tomorrow'
    };

    const dbStatus = statusMap[status];

    if (!dbStatus) {
      return res.status(400).json({
        success: false,
        message: 'Invalid station status'
      });
    }

    const result = await query(
      'UPDATE filling_stations SET current_status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [dbStatus, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Filling station not found'
      });
    }

    logger.info(`Station ${id} status updated to ${dbStatus}`);

    res.json({
      success: true,
      message: 'Station status updated',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Update filling station status error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to update filling station status'
    });
  }
};

/**
 * PUT /api/v1/workers/location
 * Update worker's live location
 */
const updateLiveLocation = async (req, res) => {
  try {
    const userId = req.user.id;
    const { latitude, longitude, delivery_id } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    // UPSERT worker_locations
    await query(
      `INSERT INTO worker_locations (worker_id, delivery_id, latitude, longitude, updated_at)
       VALUES ($1, $2, $3, $4, NOW())
       ON CONFLICT (worker_id) DO UPDATE SET
         latitude = EXCLUDED.latitude,
         longitude = EXCLUDED.longitude,
         delivery_id = EXCLUDED.delivery_id,
         updated_at = NOW()`,
      [userId, delivery_id || null, latitude, longitude]
    );

    res.json({
      success: true,
      message: 'Location updated'
    });
  } catch (error) {
    logger.error('Update live location error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to update location'
    });
  }
};

/**
 * GET /api/v1/workers/expenses
 * Get worker expenses
 */
const getExpenses = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT id, amount, payment_method, payment_status, destination, notes, 
              TO_CHAR(created_at, 'YYYY-MM-DD') as date
       FROM worker_expenses
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userId]
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    logger.error('Get expenses error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to get expenses'
    });
  }
};

/**
 * POST /api/v1/workers/expenses
 * Submit a new expense
 */
const submitExpense = async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount, payment_method, payment_status, destination, notes } = req.body;

    const result = await query(
      `INSERT INTO worker_expenses (user_id, amount, payment_method, payment_status, destination, notes)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, amount, payment_method, payment_status, destination, notes, 
                 TO_CHAR(created_at, 'YYYY-MM-DD') as date`,
      [userId, amount, payment_method, payment_status || 'unpaid', destination, notes]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Submit expense error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to submit expense'
    });
  }
};

/**
 * PUT /api/v1/workers/expenses/:id
 * Update an expense
 */
const updateExpense = async (req, res) => {
  try {
    const userId = req.user.id;
    const expenseId = req.params.id;
    const { amount, payment_method, payment_status, destination, notes } = req.body;

    const result = await query(
      `UPDATE worker_expenses
       SET amount = $1, payment_method = $2, payment_status = $3, destination = $4, notes = $5, updated_at = NOW()
       WHERE id = $6 AND user_id = $7
       RETURNING id, amount, payment_method, payment_status, destination, notes, 
                 TO_CHAR(created_at, 'YYYY-MM-DD') as date`,
      [amount, payment_method, payment_status, destination, notes, expenseId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Update expense error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to update expense'
    });
  }
};

/**
 * DELETE /api/v1/workers/expenses/:id
 * Delete an expense
 */
const deleteExpense = async (req, res) => {
  try {
    const userId = req.user.id;
    const expenseId = req.params.id;

    const result = await query(
      `DELETE FROM worker_expenses
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [expenseId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    res.json({
      success: true,
      message: 'Expense deleted successfully'
    });
  } catch (error) {
    logger.error('Delete expense error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: 'Failed to delete expense'
    });
  }
};

/**
 * POST /api/v1/workers/coupon-requests/:id/accept
 * Accept a coupon book request
 */
const acceptCouponBookRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;

    // Get worker profile ID
    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;

    await transaction(async (client) => {
      // 1. Lock request row
      const requestRes = await client.query(
        'SELECT * FROM coupon_book_requests WHERE id = $1 FOR UPDATE',
        [requestId]
      );

      if (requestRes.rows.length === 0) {
        throw new Error('Coupon book request not found');
      }

      const request = requestRes.rows[0];

      // 2. Status/Assignment check
      if (request.status !== 'approved') {
        throw new Error('Request is not in approved status');
      }

      if (request.assigned_worker_id && request.assigned_worker_id !== workerId) {
        throw new Error('Request is already assigned to another worker');
      }

      // 3. Update assignment
      await client.query(
        `UPDATE coupon_book_requests 
         SET assigned_worker_id = $1, 
             status = 'assigned',
             updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [workerId, requestId]
      );
    });

    logger.info('Coupon book request accepted:', { userId, requestId });

    res.json({
      success: true,
      message: 'Coupon book request accepted'
    });
  } catch (error) {
    logger.error('Accept coupon book request error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: error.message || 'Failed to accept coupon book request'
    });
  }
};

/**
 * POST /api/v1/workers/coupon-requests/:id/complete
 * Complete a coupon book request (deliver physical book)
 */
const completeCouponBookRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;
    const {
      delivery_latitude,
      delivery_longitude,
      notes
    } = req.body;

    // Get worker profile
    const workerResult = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker profile not found'
      });
    }

    const workerId = workerResult.rows[0].id;

    await transaction(async (client) => {
      // 1. Lock request and get details
      const requestResult = await client.query(
        `SELECT cbr.*, cs.size, cs.bonus_gallons, cp.user_id as client_user_id, u.preferred_language
         FROM coupon_book_requests cbr
         JOIN coupon_sizes cs ON cbr.coupon_size_id = cs.id
         JOIN client_profiles cp ON cbr.client_id = cp.id
         JOIN users u ON cp.user_id = u.id
         WHERE cbr.id = $1
         FOR UPDATE OF cbr, cp`,
        [requestId]
      );

      if (requestResult.rows.length === 0) {
        throw new Error('Coupon book request not found');
      }

      const request = requestResult.rows[0];

      if (request.assigned_worker_id !== workerId) {
        throw new Error('Request is not assigned to you');
      }

      if (request.status === 'completed') {
        throw new Error('Request is already completed');
      }

      // 2. Credit coupons to client (Physical book delivered)
      const totalCoupons = request.size + (request.bonus_gallons || 0);
      await client.query(
        `UPDATE client_profiles 
         SET remaining_coupons = remaining_coupons + $1,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        [totalCoupons, request.client_id]
      );

      // 3. Update request status
      await client.query(
        `UPDATE coupon_book_requests 
         SET status = 'completed', 
             processed_at = CURRENT_TIMESTAMP,
             processed_by = $2
         WHERE id = $1`,
        [requestId, userId]
      );

      // 4. Create notification for client
      await notificationService.createNotification({
        userId: request.client_user_id,
        title: t(request.preferred_language, 'coupon_delivered_title'),
        message: t(request.preferred_language, 'coupon_delivered_body', request.size),
        type: 'coupon_status',
        referenceId: requestId,
        referenceType: 'coupon_book_request',
        dbClient: client
      });
    });

    logger.info('Coupon book request completed and coupons credited:', { userId, requestId });

    res.json({
      success: true,
      message: 'Coupon book delivered and coupons credited successfully'
    });
  } catch (error) {
    logger.error('Complete coupon book request error:', error);
    res.status(getErrorStatus(error)).json({
      success: false,
      message: error.message || 'Failed to complete coupon book request'
    });
  }
};

// ============================================================================
// WORKER PROFILE MANAGEMENT
// ============================================================================

async function getProfile(req, res) {
  try {
    const workerId = req.user.workerId;
    
    const result = await pool.query(
      `SELECT wp.*, u.username, u.phone_number, u.email
       FROM worker_profiles wp
       JOIN users u ON wp.user_id = u.id
       WHERE wp.id = $1`,
      [workerId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Worker profile not found' });
    }
    
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    logger.error('Get worker profile error:', error);
    res.status(500).json({ success: false, message: 'Failed to get profile' });
  }
}

async function updateProfile(req, res) {
  try {
    const workerId = req.user.workerId;
    const { full_name, vehicle_plate_number, vehicle_capacity } = req.body;
    
    const updates = [];
    const values = [];
    let paramCount = 1;
    
    if (full_name) {
      updates.push(`full_name = $${paramCount++}`);
      values.push(full_name);
    }
    if (vehicle_plate_number !== undefined) {
      updates.push(`vehicle_plate_number = $${paramCount++}`);
      values.push(vehicle_plate_number);
    }
    if (vehicle_capacity !== undefined) {
      updates.push(`vehicle_capacity = $${paramCount++}`);
      values.push(vehicle_capacity);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }
    
    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(workerId);
    
    await pool.query(
      `UPDATE worker_profiles SET ${updates.join(', ')} WHERE id = $${paramCount}`,
      values
    );
    
    res.json({ success: true, message: 'Profile updated successfully' });
  } catch (error) {
    logger.error('Update worker profile error:', error);
    res.status(500).json({ success: false, message: 'Failed to update profile' });
  }
}

// ============================================================================
// SHIFT MANAGEMENT
// ============================================================================

async function getShifts(req, res) {
  try {
    const workerId = req.user.workerId;
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;
    
    const result = await pool.query(
      `SELECT * FROM worker_shifts 
       WHERE worker_id = $1 
       ORDER BY shift_start DESC 
       LIMIT $2 OFFSET $3`,
      [workerId, limit, offset]
    );
    
    const countResult = await pool.query(
      'SELECT COUNT(*) FROM worker_shifts WHERE worker_id = $1',
      [workerId]
    );
    
    res.json({
      success: true,
      data: {
        shifts: result.rows,
        total: parseInt(countResult.rows[0].count),
        limit,
        offset
      }
    });
  } catch (error) {
    logger.error('Get shifts error:', error);
    res.status(500).json({ success: false, message: 'Failed to get shifts' });
  }
}

async function startShift(req, res) {
  try {
    const workerId = req.user.workerId;
    
    // Check if already on shift
    const activeShift = await pool.query(
      'SELECT id FROM worker_shifts WHERE worker_id = $1 AND shift_end IS NULL',
      [workerId]
    );
    
    if (activeShift.rows.length > 0) {
      return res.status(400).json({ success: false, message: 'Shift already active' });
    }
    
    const result = await pool.query(
      `INSERT INTO worker_shifts (worker_id, shift_start) 
       VALUES ($1, CURRENT_TIMESTAMP) 
       RETURNING *`,
      [workerId]
    );
    
    await pool.query(
      'UPDATE worker_profiles SET is_on_shift = true, shift_start_time = CURRENT_TIMESTAMP WHERE id = $1',
      [workerId]
    );
    
    res.json({ success: true, message: 'Shift started', data: result.rows[0] });
  } catch (error) {
    logger.error('Start shift error:', error);
    res.status(500).json({ success: false, message: 'Failed to start shift' });
  }
}

async function endShift(req, res) {
  try {
    const workerId = req.user.workerId;
    
    const result = await pool.query(
      `UPDATE worker_shifts 
       SET shift_end = CURRENT_TIMESTAMP 
       WHERE worker_id = $1 AND shift_end IS NULL 
       RETURNING *`,
      [workerId]
    );
    
    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'No active shift found' });
    }
    
    await pool.query(
      'UPDATE worker_profiles SET is_on_shift = false, shift_start_time = NULL WHERE id = $1',
      [workerId]
    );
    
    res.json({ success: true, message: 'Shift ended', data: result.rows[0] });
  } catch (error) {
    logger.error('End shift error:', error);
    res.status(500).json({ success: false, message: 'Failed to end shift' });
  }
}

async function getCurrentShift(req, res) {
  try {
    const workerId = req.user.workerId;
    
    const result = await pool.query(
      'SELECT * FROM worker_shifts WHERE worker_id = $1 AND shift_end IS NULL',
      [workerId]
    );
    
    if (result.rows.length === 0) {
      return res.json({ success: true, data: null, message: 'No active shift' });
    }
    
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    logger.error('Get current shift error:', error);
    res.status(500).json({ success: false, message: 'Failed to get current shift' });
  }
}

// ============================================================================
// EARNINGS
// ============================================================================

async function getEarnings(req, res) {
  try {
    const workerId = req.user.workerId;
    const startDate = req.query.start_date || new Date(new Date().setDate(1)).toISOString();
    const endDate = req.query.end_date || new Date().toISOString();
    
    const deliveries = await pool.query(
      `SELECT COUNT(*) as count, SUM(gallons_delivered) as total_gallons
       FROM delivery_requests
       WHERE worker_id = $1 AND status = 'completed'
       AND completed_at BETWEEN $2 AND $3`,
      [workerId, startDate, endDate]
    );
    
    const advances = await pool.query(
      'SELECT debt_advances FROM worker_profiles WHERE id = $1',
      [workerId]
    );
    
    res.json({
      success: true,
      data: {
        deliveries_completed: parseInt(deliveries.rows[0].count) || 0,
        total_gallons_delivered: parseFloat(deliveries.rows[0].total_gallons) || 0,
        debt_advances: parseFloat(advances.rows[0]?.debt_advances) || 0,
        period: { start: startDate, end: endDate }
      }
    });
  } catch (error) {
    logger.error('Get earnings error:', error);
    res.status(500).json({ success: false, message: 'Failed to get earnings' });
  }
}

// ============================================================================
// INVENTORY MANAGEMENT
// ============================================================================

async function loadInventory(req, res) {
  try {
    const workerId = req.user.workerId;
    const { gallons } = req.body;
    
    const worker = await pool.query(
      'SELECT vehicle_capacity, vehicle_current_gallons FROM worker_profiles WHERE id = $1',
      [workerId]
    );
    
    if (worker.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Worker not found' });
    }
    
    const { vehicle_capacity, vehicle_current_gallons } = worker.rows[0];
    const newTotal = parseInt(vehicle_current_gallons) + parseInt(gallons);
    
    if (newTotal > vehicle_capacity) {
      return res.status(400).json({ 
        success: false, 
        message: `Cannot load ${gallons} gallons. Capacity: ${vehicle_capacity}, Current: ${vehicle_current_gallons}` 
      });
    }
    
    await pool.query(
      'UPDATE worker_profiles SET vehicle_current_gallons = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newTotal, workerId]
    );
    
    res.json({ 
      success: true, 
      message: 'Inventory loaded successfully',
      data: {
        previous: parseInt(vehicle_current_gallons),
        loaded: parseInt(gallons),
        current: newTotal,
        capacity: parseInt(vehicle_capacity),
        available: parseInt(vehicle_capacity) - newTotal
      }
    });
  } catch (error) {
    logger.error('Load inventory error:', error);
    res.status(500).json({ success: false, message: 'Failed to load inventory' });
  }
}

module.exports = {
  getWorkerProfile,
  getMainSchedule,
  getSecondaryList,
  startDelivery,
  acceptScheduledDelivery,
  completeDelivery,
  acceptRequest,
  completeRequest,
  acceptCouponBookRequest,
  completeCouponBookRequest,
  createQuickDelivery: require('./admin.controller').createQuickDelivery,
  updateVehicleInventory,
  toggleGPSSharing,
  getFillingStations,
  startFillingSession,
  completeFillingSession,
  getRecentFillingSessions,
  updateFillingSession,
  deleteFillingSession,
  updateFillingStationStatus,
  updateLiveLocation,
  getExpenses,
  submitExpense,
  updateExpense,
  deleteExpense,
  getProfile,
  updateProfile,
  getShifts,
  startShift,
  endShift,
  getCurrentShift,
  getEarnings,
  loadInventory
};
