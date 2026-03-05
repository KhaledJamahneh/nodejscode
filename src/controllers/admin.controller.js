// src/controllers/admin.controller.js
// Admin dashboard, management, and analytics

const { query, transaction } = require('../config/database');
const { getMessage: t, localizeResponse } = require('../utils/i18n');
const logger = require('../utils/logger');
const notificationService = require('../services/notification.service');
const bcrypt = require('bcrypt');
const { isValidTransition } = require('../utils/state-machine');
const { getStatusCode } = require('../middleware/error-handler.middleware');

/**
 * GET /api/v1/admin/coupon-book-requests
 * Get all coupon book requests with filtering
 */
const getAllCouponBookRequests = async (req, res) => {
  try {
    const { status, search, limit = 50, offset = 0 } = req.query;

    let queryText = `
      SELECT 
        cbr.id,
        cbr.book_type,
        cbr.total_price,
        cbr.status,
        cbr.created_at,
        cbr.assigned_worker_id,
        cs.size as book_size,
        cp.id as client_id,
        cp.full_name as client_name,
        cp.address as client_address,
        cp.home_latitude,
        cp.home_longitude,
        u.phone_number as client_phone,
        w.full_name as worker_name
      FROM coupon_book_requests cbr
      JOIN coupon_sizes cs ON cbr.coupon_size_id = cs.id
      JOIN client_profiles cp ON cbr.client_id = cp.id
      JOIN users u ON cp.user_id = u.id
      LEFT JOIN worker_profiles w ON cbr.assigned_worker_id = w.id
      WHERE 1=1
    `;

    const queryParams = [];
    let paramCount = 0;

    if (status) {
      paramCount++;
      queryText += ` AND cbr.status = $${paramCount}`;
      queryParams.push(status);
    }

    if (search) {
      paramCount++;
      queryText += ` AND (cp.full_name ILIKE $${paramCount} OR cp.address ILIKE $${paramCount} OR u.phone_number ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    queryText += ` ORDER BY cbr.created_at DESC
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;

    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, queryParams);

    res.json({
      success: true,
      data: {
        requests: result.rows
      }
    });
  } catch (error) {
    logger.error('Get all coupon book requests error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get coupon book requests'
    });
  }
};

/**
 * PATCH /api/v1/admin/coupon-book-requests/:id/assign
 * Assign worker to coupon book request
 */
const assignCouponBookWorker = async (req, res) => {
  try {
    const { id } = req.params;
    const { worker_id } = req.body;

    const result = await query(
      `UPDATE coupon_book_requests 
       SET assigned_worker_id = $1, status = 'assigned'
       WHERE id = $2
       RETURNING *`,
      [worker_id, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Coupon book request not found'
      });
    }

    // Notify worker
    try {
      const details = await query(
        `SELECT u.full_name as client_name, cbr.book_type, cbr.total_price 
         FROM coupon_book_requests cbr 
         JOIN client_profiles cp ON cbr.client_id = cp.id 
         JOIN users u ON cp.user_id = u.id 
         WHERE cbr.id = $1`,
        [id]
      );

      const workerRes = await query(
        'SELECT user_id, preferred_language FROM users JOIN worker_profiles ON users.id = worker_profiles.user_id WHERE worker_profiles.id = $1',
        [worker_id]
      );
      
      if (workerRes.rows.length > 0 && details.rows.length > 0) {
        const worker = workerRes.rows[0];
        const detail = details.rows[0];
        const lang = worker.preferred_language || 'en';
        
        const titleKey = detail.book_type === 'physical' ? 'physical_coupon_assigned_title' : 'coupon_assigned_title';
        const bodyKey = detail.book_type === 'physical' ? 'physical_coupon_assigned_body' : 'coupon_assigned_body';

        await notificationService.createNotification({
          userId: worker.user_id,
          title: t(titleKey, lang),
          message: t(bodyKey, lang, { 
            clientName: detail.client_name,
            amount: detail.total_price 
          }),
          type: 'assignment',
          referenceId: id,
          referenceType: 'coupon_book_request'
        });
      }
    } catch (notifyError) {
      logger.error('Failed to notify worker of coupon assignment:', notifyError);
      // Don't fail the request if notification fails
    }

    res.json({
      success: true,
      message: 'Worker assigned successfully',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Assign coupon book worker error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to assign worker'
    });
  }
};

/**
 * POST /api/v1/admin/coupon-book-requests/:id/unassign
 */
const unassignWorkerFromCouponBookRequest = async (req, res) => {
  try {
    const { id } = req.params;
    await query(
      "UPDATE coupon_book_requests SET assigned_worker_id = NULL, status = 'pending', updated_at = CURRENT_TIMESTAMP WHERE id = $1",
      [id]
    );
    res.json({ success: true, message: 'Worker unassigned from coupon book request' });
  } catch (error) {
    logger.error('Unassign coupon worker error:', error);
    res.status(500).json({ success: false, message: 'Failed to unassign worker' });
  }
};

/**
 * PATCH /api/v1/admin/coupon-book-requests/:id/status
 * Update status of a coupon book request
 */
const updateCouponBookRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { status: nextStatus, total_price, book_type, notes } = req.body;

    const result = await transaction(async (client) => {
      // 1. Get current data
      const currentRes = await client.query(
        'SELECT status, client_id FROM coupon_book_requests WHERE id = $1 FOR UPDATE',
        [id]
      );

      if (currentRes.rows.length === 0) {
        throw new Error('Coupon book request not found');
      }

      const currentStatus = currentRes.rows[0].status;

      // 2. Validate transition if status is changing
      if (nextStatus && nextStatus !== currentStatus) {
        if (!isValidTransition('coupon_request', currentStatus, nextStatus)) {
          throw new Error(`Invalid status transition from ${currentStatus} to ${nextStatus}`);
        }
      }

      // 3. Handle special transitions (e.g., completion credits coupons)
      if (nextStatus === 'completed' && currentStatus !== 'completed') {
        const requestData = await client.query(
          `SELECT cbr.client_id, cs.size, cs.bonus_gallons 
           FROM coupon_book_requests cbr
           JOIN coupon_sizes cs ON cbr.coupon_size_id = cs.id
           WHERE cbr.id = $1`,
          [id]
        );
        
        if (requestData.rows.length > 0) {
          const { client_id, size, bonus_gallons } = requestData.rows[0];
          
          await client.query(
            `UPDATE client_profiles 
             SET remaining_coupons = remaining_coupons + $1,
                 bonus_gallons = bonus_gallons + $2
             WHERE user_id = $3`,
            [size, bonus_gallons || 0, client_id]
          );
        }
      }

      // 4. Update fields
      const fields = [];
      const values = [];
      let paramIdx = 1;

      if (nextStatus !== undefined) { fields.push(`status = $${paramIdx++}`); values.push(nextStatus); }
      if (total_price !== undefined) { fields.push(`total_price = $${paramIdx++}`); values.push(total_price); }
      if (book_type !== undefined) { fields.push(`book_type = $${paramIdx++}`); values.push(book_type); }
      if (notes !== undefined) { fields.push(`notes = $${paramIdx++}`); values.push(notes); }

      if (fields.length > 0) {
        values.push(id);
        const updateRes = await client.query(
          `UPDATE coupon_book_requests 
           SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP 
           WHERE id = $${paramIdx}
           RETURNING *`,
          values
        );
        return updateRes.rows[0];
      }
      
      return currentRes.rows[0];
    });

    res.json({
      success: true,
      message: 'Coupon book request updated successfully',
      data: result
    });
  } catch (error) {
    logger.error('Update coupon book request error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to update request'
    });
  }
};

/**
 * DELETE /api/v1/admin/coupon-book-requests/:id
 * Delete a coupon book request
 */
const deleteCouponBookRequest = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      'DELETE FROM coupon_book_requests WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Coupon book request not found'
      });
    }

    res.json({
      success: true,
      message: 'Coupon book request deleted successfully'
    });
  } catch (error) {
    logger.error('Delete coupon book request error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to delete coupon book request'
    });
  }
};

/**
 * GET /api/v1/admin/coupon-sizes
 * Get all coupon sizes for admin management
 */
const getCouponSizes = async (req, res) => {
  try {
    const result = await query(
      `SELECT 
        id,
        size,
        price_per_page,
        bonus_gallons,
        (size * price_per_page) as total_price,
        (size + COALESCE(bonus_gallons, 0)) as total_gallons
      FROM coupon_sizes
      ORDER BY size ASC`
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    logger.error('Get coupon sizes error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to retrieve coupon sizes'
    });
  }
};

/**
 * POST /api/v1/admin/coupon-sizes
 * Create a new coupon size
 */
const createCouponSize = async (req, res) => {
  try {
    const { size, price_per_page, bonus_gallons, available_stock } = req.body;

    if (!size) {
      return res.status(400).json({ success: false, message: 'Size is required' });
    }

    const result = await query(
      `INSERT INTO coupon_sizes (size, price_per_page, bonus_gallons, available_stock) 
       VALUES ($1, $2, $3, $4) 
       RETURNING *`,
      [size, price_per_page || 0.50, bonus_gallons || 0, available_stock || 100]
    );

    res.status(201).json({
      success: true,
      message: 'Coupon size created successfully',
      data: result.rows[0]
    });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(400).json({ success: false, message: 'Coupon size already exists' });
    }
    logger.error('Create coupon size error:', error);
    res.status(500).json({ success: false, message: 'Failed to create coupon size' });
  }
};

/**
 * PATCH /api/v1/admin/coupon-sizes/:id
 * Update coupon size price and bonus
 */
const updateCouponSize = async (req, res) => {
  try {
    const { id } = req.params;
    const { price_per_page, bonus_gallons } = req.body;

    const result = await query(
      `UPDATE coupon_sizes 
       SET price_per_page = COALESCE($1, price_per_page),
           bonus_gallons = COALESCE($2, bonus_gallons)
       WHERE id = $3
       RETURNING *`,
      [price_per_page, bonus_gallons, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Coupon size not found'
      });
    }

    res.json({
      success: true,
      message: 'Coupon size updated successfully',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Update coupon size error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update coupon size'
    });
  }
};


/**
 * GET /api/v1/admin/dashboard
 * Get comprehensive dashboard overview
 */
const getDashboard = async (req, res) => {
  try {
    // Get key metrics and detailed lists in parallel
    const [
      activeWorkersCount,
      pendingDeliveriesCount,
      todayDeliveriesCount,
      pendingRequestsCount,
      urgentRequestsCount,
      activeClientsCount,
      lowInventoryCount,
      overduePaymentsCount,
      todayRevenueCount,
      monthRevenueCount,
      pendingCouponRequestsCount,
      
      // Detailed lists
      activeWorkersList,
      pendingDeliveriesList,
      todayDeliveriesList,
      pendingRequestsList,
      activeClientsList,
      lowInventoryWorkersList,
      clientsWithDebtList
    ] = await Promise.all([
      // Counts - Active workers currently on shift
      query(`SELECT COUNT(*) as count FROM worker_profiles wp
             JOIN users u ON wp.user_id = u.id
             WHERE u.is_active = true 
             AND u.role && $1::user_role[]
             AND is_worker_active_now(u.id) = true`, [['delivery_worker', 'onsite_worker']]),
      query(`SELECT COUNT(*) as count FROM deliveries WHERE status = 'pending'`),
      query(`SELECT COUNT(*) as count FROM deliveries WHERE delivery_date = CURRENT_DATE`),
      query(`SELECT COUNT(*) as count FROM delivery_requests WHERE status = 'pending'`),
      query(`SELECT COUNT(*) as count FROM delivery_requests WHERE status = 'pending' AND priority = 'urgent'`),
      query(`SELECT COUNT(*) as count FROM users WHERE is_active = true AND role && $1::user_role[]`, [['client']]),
      query(`SELECT COUNT(*) as count FROM worker_profiles WHERE vehicle_current_gallons < 10`),
      query(`SELECT COUNT(*) as count FROM client_profiles WHERE current_debt > 0`),
      query(`SELECT COALESCE(SUM(amount), 0) as total FROM payments 
             WHERE payment_status = 'completed' AND DATE(payment_date) = CURRENT_DATE`),
      query(`SELECT COALESCE(SUM(amount), 0) as total FROM payments 
             WHERE payment_status = 'completed' AND DATE_TRUNC('month', payment_date) = DATE_TRUNC('month', CURRENT_DATE)`),
      query(`SELECT COUNT(*) as count FROM coupon_book_requests WHERE status IN ('pending', 'approved')`),
      
      // Active workers details - currently on shift
      query(`SELECT wp.id, wp.full_name, wp.worker_type, wp.vehicle_current_gallons,
             ws.name as shift_name, ws.start_time, ws.end_time
             FROM worker_profiles wp 
             JOIN users u ON wp.user_id = u.id
             LEFT JOIN work_shifts ws ON wp.shift_id = ws.id
             WHERE u.is_active = true 
             AND u.role && $1::user_role[]
             AND is_worker_active_now(u.id) = true
             ORDER BY wp.full_name ASC`, [['delivery_worker', 'onsite_worker']]),
      
      // Pending deliveries details
      query(`SELECT d.id, c.full_name as client_name, d.scheduled_time, d.gallons_delivered 
             FROM deliveries d 
             JOIN client_profiles c ON d.client_id = c.id 
             WHERE d.status = 'pending'
             ORDER BY d.scheduled_time ASC NULLS LAST`),
      
      // Today's completed deliveries details
      query(`SELECT d.id, c.full_name as client_name, d.actual_delivery_time, d.gallons_delivered 
             FROM deliveries d 
             JOIN client_profiles c ON d.client_id = c.id 
             WHERE d.delivery_date = CURRENT_DATE AND d.status = 'completed'
             ORDER BY d.actual_delivery_time DESC`),
      
      // Pending requests details
      query(`SELECT dr.id, c.full_name as client_name, dr.priority, dr.requested_gallons 
             FROM delivery_requests dr 
             JOIN client_profiles c ON dr.client_id = c.id 
             WHERE dr.status = 'pending'
             ORDER BY CASE dr.priority WHEN 'urgent' THEN 1 WHEN 'mid_urgent' THEN 2 ELSE 3 END`),
      
      // Active clients details
      query(`SELECT cp.id, cp.full_name, cp.subscription_type, cp.remaining_coupons 
             FROM client_profiles cp 
             JOIN users u ON cp.user_id = u.id 
             WHERE u.is_active = true AND u.role && $1::user_role[]
             ORDER BY cp.full_name ASC`, [['client']]),
      
      // Low inventory workers details
      query(`SELECT id, full_name, vehicle_current_gallons 
             FROM worker_profiles 
             WHERE vehicle_current_gallons < 10
             ORDER BY vehicle_current_gallons ASC`),
      
      // Clients with debt details
      query(`SELECT id, full_name, current_debt 
             FROM client_profiles 
             WHERE current_debt > 0
             ORDER BY current_debt DESC`)
    ]);

    // Get recent activity (deliveries and coupon purchases)
    const recentActivity = await query(
      `SELECT * FROM (
        SELECT 
          'delivery' as type,
          d.id,
          d.delivery_date as date,
          d.actual_delivery_time as timestamp,
          d.status::text as status,
          d.gallons_delivered as amount,
          c.full_name as client_name,
          w.full_name as worker_name,
          NULL as payment_method
        FROM deliveries d
        JOIN client_profiles c ON d.client_id = c.id
        JOIN worker_profiles w ON d.worker_id = w.id
        
        UNION ALL
        
        SELECT
          'coupon_purchase' as type,
          cbr.id,
          cbr.created_at::date as date,
          cbr.created_at as timestamp,
          cbr.status as status,
          cbr.total_price as amount,
          c.full_name as client_name,
          NULL as worker_name,
          cbr.payment_method
        FROM coupon_book_requests cbr
        JOIN client_profiles c ON cbr.client_id = c.id
        WHERE cbr.status = 'completed'
      ) activities
      ORDER BY timestamp DESC NULLS LAST
      LIMIT 10`
    );

    res.json({
      success: true,
      data: {
        metrics: {
          on_shift_workers: parseInt(activeWorkersCount.rows[0].count),
          pending_deliveries: parseInt(pendingDeliveriesCount.rows[0].count),
          today_deliveries: parseInt(todayDeliveriesCount.rows[0].count),
          pending_requests: parseInt(pendingRequestsCount.rows[0].count),
          urgent_requests: parseInt(urgentRequestsCount.rows[0].count),
          active_clients: parseInt(activeClientsCount.rows[0].count),
          low_inventory_workers: parseInt(lowInventoryCount.rows[0].count),
          clients_with_debt: parseInt(overduePaymentsCount.rows[0].count),
          pending_coupon_requests: parseInt(pendingCouponRequestsCount.rows[0].count)
        },
        details: {
          on_shift_workers: activeWorkersList.rows,
          pending_deliveries: pendingDeliveriesList.rows,
          today_deliveries: todayDeliveriesList.rows,
          pending_requests: pendingRequestsList.rows,
          active_clients: activeClientsList.rows,
          low_inventory_workers: lowInventoryWorkersList.rows,
          clients_with_debt: clientsWithDebtList.rows
        },
        revenue: {
          today: parseFloat(todayRevenueCount.rows[0].total),
          this_month: parseFloat(monthRevenueCount.rows[0].total)
        },
        recent_activity: recentActivity.rows
      }
    });
  } catch (error) {
    logger.error('Get dashboard error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get dashboard data'
    });
  }
};

/**
 * GET /api/v1/admin/requests
 * Get all delivery requests with filtering
 */
const getAllRequests = async (req, res) => {
  try {
    const { status, priority, search, limit = 50, offset = 0 } = req.query;

    let queryText = `
      SELECT 
        dr.id,
        dr.priority,
        dr.requested_gallons,
        dr.request_date,
        dr.status,
        dr.notes,
        c.full_name as client_name,
        c.address as client_address,
        u.phone_number as client_phone,
        w.full_name as assigned_worker_name
      FROM delivery_requests dr
      JOIN client_profiles c ON dr.client_id = c.id
      JOIN users u ON c.user_id = u.id
      LEFT JOIN worker_profiles w ON dr.assigned_worker_id = w.id
      WHERE 1=1
    `;

    const queryParams = [];
    let paramCount = 0;

    if (status) {
      paramCount++;
      queryText += ` AND dr.status = $${paramCount}`;
      queryParams.push(status);
    }

    if (priority) {
      paramCount++;
      queryText += ` AND dr.priority = $${paramCount}`;
      queryParams.push(priority);
    }

    if (search) {
      paramCount++;
      queryText += ` AND (c.full_name ILIKE $${paramCount} OR c.address ILIKE $${paramCount} OR u.phone_number ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    queryText += ` ORDER BY 
      CASE dr.priority 
        WHEN 'urgent' THEN 1 
        WHEN 'mid_urgent' THEN 2 
        WHEN 'non_urgent' THEN 3 
      END,
      dr.request_date DESC
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;

    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, queryParams);

    // Get total count
    let countQuery = `
      SELECT COUNT(*) 
      FROM delivery_requests dr
      JOIN client_profiles c ON dr.client_id = c.id
      JOIN users u ON c.user_id = u.id
      WHERE 1=1
    `;
    const countParams = [];
    let countParamNum = 0;

    if (status) {
      countParamNum++;
      countQuery += ` AND dr.status = $${countParamNum}`;
      countParams.push(status);
    }

    if (priority) {
      countParamNum++;
      countQuery += ` AND dr.priority = $${countParamNum}`;
      countParams.push(priority);
    }

    if (search) {
      countParamNum++;
      countQuery += ` AND (c.full_name ILIKE $${countParamNum} OR c.address ILIKE $${countParamNum} OR u.phone_number ILIKE $${countParamNum})`;
      countParams.push(`%${search}%`);
    }

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        requests: result.rows,
        pagination: {
          total,
          limit: parseInt(limit),
          offset: parseInt(offset),
          has_more: offset + result.rows.length < total
        }
      }
    });
  } catch (error) {
    logger.error('Get all requests error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get delivery requests'
    });
  }
};

/**
 * POST /api/v1/admin/requests/:id/assign
 * Assign a worker to a delivery request
 */
const assignWorkerToRequest = async (req, res) => {
  try {
    const requestId = req.params.id;
    const { worker_id } = req.body;

    // Check if request exists and is pending
    const requestCheck = await query(
      'SELECT id, status FROM delivery_requests WHERE id = $1',
      [requestId]
    );

    if (requestCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Delivery request not found'
      });
    }

    if (requestCheck.rows[0].status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot assign worker to completed request'
      });
    }

    if (requestCheck.rows[0].status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Can only assign workers to pending requests'
      });
    }

    // Check if worker exists
    const workerCheck = await query(
      'SELECT id FROM worker_profiles WHERE id = $1',
      [worker_id]
    );

    if (workerCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found'
      });
    }

    // Assign worker and mark as in_progress to show on schedule
    const result = await transaction(async (client) => {
      await client.query(
        `UPDATE delivery_requests 
         SET assigned_worker_id = $1, status = 'in_progress', updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [worker_id, requestId]
      );

      // Notify Worker
      const workerUser = await client.query('SELECT u.id as user_id, u.preferred_language FROM worker_profiles wp JOIN users u ON wp.user_id = u.id WHERE wp.id = $1', [worker_id]);
      const workerLang = workerUser.rows[0].preferred_language || 'en';
      const workerNotification = await notificationService.createNotification({
        userId: workerUser.rows[0].user_id,
        title: t(workerLang, 'new_task_assigned_title'),
        message: t(workerLang, 'new_task_assigned_body'),
        type: 'worker_assignment',
        referenceId: requestId,
        referenceType: 'delivery_request',
        dbClient: client,
        sendPush: false
      });

      // Notify Client
      const clientRequest = await client.query(
        `SELECT cp.user_id, u.preferred_language, wp.full_name as worker_name 
         FROM delivery_requests dr
         JOIN client_profiles cp ON dr.client_id = cp.id
         JOIN users u ON cp.user_id = u.id
         JOIN worker_profiles wp ON wp.id = $1
         WHERE dr.id = $2`,
        [worker_id, requestId]
      );
      
      const clientLang = clientRequest.rows[0].preferred_language || 'en';
      const clientNotification = await notificationService.createNotification({
        userId: clientRequest.rows[0].user_id,
        title: t(clientLang, 'request_assigned_title'),
        message: t(clientLang, 'request_assigned_body'),
        type: 'delivery_status',
        referenceId: requestId,
        referenceType: 'delivery_request',
        dbClient: client,
        sendPush: false
      });

      return {
        workerId: workerUser.rows[0].user_id,
        workerNotification,
        clientId: clientRequest.rows[0].user_id,
        clientNotification
      };
    });

    // Send push notifications after transaction commits
    notificationService.sendPush(result.workerId, result.workerNotification);
    notificationService.sendPush(result.clientId, result.clientNotification);

    logger.info('Worker assigned to request with notifications:', { requestId, worker_id, admin: req.user.id });

    res.json({
      success: true,
      message: 'Worker assigned successfully and notifications sent'
    });
  } catch (error) {
    logger.error('Assign worker error:', {
      message: error.message,
      stack: error.stack,
      requestId: req.params.id,
      workerId: req.body.worker_id
    });
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to assign worker',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * POST /api/v1/admin/requests/:id/unassign
 */
const unassignWorkerFromRequest = async (req, res) => {
  try {
    const requestId = req.params.id;
    await query(
      "UPDATE delivery_requests SET assigned_worker_id = NULL, status = 'pending', updated_at = CURRENT_TIMESTAMP WHERE id = $1",
      [requestId]
    );
    res.json({ success: true, message: 'Worker unassigned from request' });
  } catch (error) {
    logger.error('Unassign worker error:', error);
    res.status(500).json({ success: false, message: 'Failed to unassign worker' });
  }
};

/**
 * PATCH /api/v1/admin/requests/:id/status
 * Update status of a delivery request
 */
const updateRequestStatus = async (req, res) => {
  // ... existing implementation
};

/**
 * PATCH /api/v1/admin/requests/:id
 * Update general request fields (gallons, notes, priority)
 */
const updateRequest = async (req, res) => {
  try {
    const requestId = req.params.id;
    const { requested_gallons, notes, priority, status } = req.body;

    const fields = [];
    const values = [];
    let paramIdx = 1;

    if (requested_gallons !== undefined) {
      fields.push(`requested_gallons = $${paramIdx++}`);
      values.push(requested_gallons);
    }
    if (notes !== undefined) {
      fields.push(`notes = $${paramIdx++}`);
      values.push(notes);
    }
    if (priority !== undefined) {
      fields.push(`priority = $${paramIdx++}`);
      values.push(priority);
    }
    if (status !== undefined) {
      fields.push(`status = $${paramIdx++}`);
      values.push(status);
    }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(requestId);
    const queryText = `
      UPDATE delivery_requests 
      SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP 
      WHERE id = $${paramIdx} 
      RETURNING *
    `;

    const result = await query(queryText, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }

    res.json({
      success: true,
      message: 'Request updated successfully',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Update request error:', error);
    res.status(500).json({ success: false, message: 'Failed to update request' });
  }
};

/**
 * GET /api/v1/admin/deliveries
 * Get all deliveries with filtering (includes assigned requests)
 */
const getAllDeliveries = async (req, res) => {
  try {
    const { status, worker_id, date, limit = 50, offset = 0 } = req.query;

    // Query for actual deliveries
    let deliveriesQuery = `
      SELECT 
        d.id,
        d.delivery_date,
        d.scheduled_time,
        d.actual_delivery_time,
        d.gallons_delivered,
        d.empty_gallons_returned,
        d.status::text as status,
        d.notes,
        c.full_name as client_name,
        c.address as client_address,
        u.phone_number as client_phone,
        w.full_name as worker_name,
        'delivery' as source_type
      FROM deliveries d
      JOIN client_profiles c ON d.client_id = c.id
      JOIN users u ON c.user_id = u.id
      JOIN worker_profiles w ON d.worker_id = w.id
      WHERE 1=1
    `;

    // Query for assigned requests (in_progress)
    let requestsQuery = `
      SELECT 
        dr.id,
        dr.request_date as delivery_date,
        NULL as scheduled_time,
        NULL as actual_delivery_time,
        dr.requested_gallons as gallons_delivered,
        0 as empty_gallons_returned,
        dr.status::text as status,
        dr.notes,
        c.full_name as client_name,
        c.address as client_address,
        u.phone_number as client_phone,
        w.full_name as worker_name,
        'request' as source_type
      FROM delivery_requests dr
      JOIN client_profiles c ON dr.client_id = c.id
      JOIN users u ON c.user_id = u.id
      LEFT JOIN worker_profiles w ON dr.assigned_worker_id = w.id
      WHERE dr.status = 'in_progress'
    `;

    // Query for assigned coupon requests (assigned/in_progress)
    let couponRequestsQuery = `
      SELECT 
        cbr.id,
        cbr.created_at as delivery_date,
        NULL as scheduled_time,
        NULL as actual_delivery_time,
        NULL as gallons_delivered,
        NULL as empty_gallons_returned,
        cbr.status,
        CONCAT('Coupon Book - ', cbr.book_type) as notes,
        c.full_name as client_name,
        c.address as client_address,
        u.phone_number as client_phone,
        w.full_name as worker_name,
        'coupon_request' as source_type
      FROM coupon_book_requests cbr
      JOIN client_profiles c ON cbr.client_id = c.id
      JOIN users u ON c.user_id = u.id
      LEFT JOIN worker_profiles w ON cbr.assigned_worker_id = w.id
      WHERE cbr.status IN ('assigned', 'in_progress')
    `;

    const queryParams = [];
    let paramCount = 0;

    if (status) {
      paramCount++;
      deliveriesQuery += ` AND d.status = $${paramCount}`;
      // Don't include requests/coupon requests when filtering by completed
      if (status === 'completed') {
        requestsQuery = ''; // Exclude requests from completed tab
        couponRequestsQuery = ''; // Exclude coupon requests from completed tab
      } else if (status === 'in_progress') {
        // Include both in_progress requests and assigned coupon requests in the in_progress tab
        // Requests query already filters by in_progress, no change needed
        // Coupon requests stay as is (assigned or in_progress)
      }
      queryParams.push(status);
    }

    if (worker_id) {
      paramCount++;
      deliveriesQuery += ` AND d.worker_id = $${paramCount}`;
      requestsQuery += ` AND dr.assigned_worker_id = $${paramCount}`;
      couponRequestsQuery += ` AND cbr.assigned_worker_id = $${paramCount}`;
      queryParams.push(worker_id);
    }

    if (date) {
      paramCount++;
      deliveriesQuery += ` AND d.delivery_date = $${paramCount}`;
      if (requestsQuery) requestsQuery += ` AND dr.request_date = $${paramCount}`;
      if (couponRequestsQuery) couponRequestsQuery += ` AND cbr.created_at::date = $${paramCount}`;
      queryParams.push(date);
    }

    // Combine all queries with UNION
    let combinedQuery;
    if (requestsQuery && couponRequestsQuery) {
      combinedQuery = `
        (${deliveriesQuery})
        UNION ALL
        (${requestsQuery})
        UNION ALL
        (${couponRequestsQuery})
        ORDER BY delivery_date DESC, actual_delivery_time DESC NULLS LAST, scheduled_time ASC NULLS LAST
        LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
      `;
    } else if (requestsQuery) {
      combinedQuery = `
        (${deliveriesQuery})
        UNION ALL
        (${requestsQuery})
        ORDER BY delivery_date DESC, actual_delivery_time DESC NULLS LAST, scheduled_time ASC NULLS LAST
        LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
      `;
    } else {
      combinedQuery = `
        ${deliveriesQuery}
        ORDER BY d.delivery_date DESC, d.actual_delivery_time DESC NULLS LAST, d.scheduled_time ASC NULLS LAST
        LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
      `;
    }

    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(combinedQuery, queryParams);

    // Get total count (deliveries + assigned requests + assigned coupon requests)
    let countQuery = `
      SELECT 
        (SELECT COUNT(*) FROM deliveries WHERE 1=1${status ? ' AND status = $1' : ''}${worker_id ? ` AND worker_id = $${status ? 2 : 1}` : ''}${date ? ` AND delivery_date = $${(status ? 1 : 0) + (worker_id ? 1 : 0) + 1}` : ''}) +
        (SELECT COUNT(*) FROM delivery_requests WHERE status = 'in_progress'${worker_id ? ` AND assigned_worker_id = $${status ? 2 : 1}` : ''}${date ? ` AND request_date = $${(status ? 1 : 0) + (worker_id ? 1 : 0) + 1}` : ''}) +
        (SELECT COUNT(*) FROM coupon_book_requests WHERE status IN ('assigned', 'in_progress')${worker_id ? ` AND assigned_worker_id = $${status ? 2 : 1}` : ''}${date ? ` AND created_at::date = $${(status ? 1 : 0) + (worker_id ? 1 : 0) + 1}` : ''}) as total
    `;
    const countParams = [];

    if (status) countParams.push(status);
    if (worker_id) countParams.push(worker_id);
    if (date) countParams.push(date);

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      data: {
        deliveries: result.rows,
        pagination: {
          total,
          limit: parseInt(limit),
          offset: parseInt(offset),
          has_more: offset + result.rows.length < total
        }
      }
    });
  } catch (error) {
    logger.error('Get all deliveries error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get deliveries'
    });
  }
};

/**
 * PATCH /api/v1/admin/deliveries/:id/status
 * Update status of a delivery or assigned request
 */
const updateDeliveryStatus = async (req, res) => {
  try {
    const deliveryId = req.params.id;
    const { status: nextStatus } = req.body;

    const result = await transaction(async (client) => {
      // 1. Check if it's an assigned request first
      const requestRes = await client.query(
        'SELECT status FROM delivery_requests WHERE id = $1 AND status = \'in_progress\' FOR UPDATE',
        [deliveryId]
      );

      if (requestRes.rows.length > 0) {
        // This is an assigned request, update it
        const currentStatus = requestRes.rows[0].status;
        
        if (!isValidTransition('request', currentStatus, nextStatus)) {
          throw new Error(`Invalid status transition from ${currentStatus} to ${nextStatus}`);
        }

        const updateRes = await client.query(
          `UPDATE delivery_requests 
           SET status = $1, updated_at = CURRENT_TIMESTAMP 
           WHERE id = $2
           RETURNING *`,
          [nextStatus, deliveryId]
        );

        return { ...updateRes.rows[0], source_type: 'request' };
      }

      // 2. Check if it's an assigned coupon request
      const couponRes = await client.query(
        'SELECT status FROM coupon_book_requests WHERE id = $1 AND status IN (\'assigned\', \'in_progress\') FOR UPDATE',
        [deliveryId]
      );

      if (couponRes.rows.length > 0) {
        const currentStatus = couponRes.rows[0].status;
        
        if (!isValidTransition('coupon_request', currentStatus, nextStatus)) {
          throw new Error(`Invalid status transition from ${currentStatus} to ${nextStatus}`);
        }

        const updateRes = await client.query(
          `UPDATE coupon_book_requests 
           SET status = $1, updated_at = CURRENT_TIMESTAMP 
           WHERE id = $2
           RETURNING *`,
          [nextStatus, deliveryId]
        );

        return { ...updateRes.rows[0], source_type: 'coupon_request' };
      }

      // 3. Otherwise, it's an actual delivery
      const currentRes = await client.query(
        'SELECT status FROM deliveries WHERE id = $1 FOR UPDATE',
        [deliveryId]
      );

      if (currentRes.rows.length === 0) {
        throw new Error('Delivery not found');
      }

      const currentStatus = currentRes.rows[0].status;

      // 4. Validate transition
      if (!isValidTransition('delivery', currentStatus, nextStatus)) {
        throw new Error(`Invalid status transition from ${currentStatus} to ${nextStatus}`);
      }

      // 5. Update status
      const updateRes = await client.query(
        `UPDATE deliveries 
         SET status = $1, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2
         RETURNING *`,
        [nextStatus, deliveryId]
      );

      return updateRes.rows[0];
    });

    logger.info('Delivery status updated by admin:', { deliveryId, status: nextStatus, admin: req.user.id });

    res.json({
      success: true,
      message: 'Delivery status updated successfully',
      data: result
    });
  } catch (error) {
    logger.error('Update delivery status error:', error);
    res.status(error.message.includes('not found') ? 404 : 400).json({
      success: false,
      message: error.message || 'Failed to update delivery status'
    });
  }
};

/**
 * POST /api/v1/admin/deliveries/:id/assign
 * Assign a worker to a delivery
 */
const assignWorkerToDelivery = async (req, res) => {
  try {
    const deliveryId = req.params.id;
    const { worker_id } = req.body;

    // Check if worker exists
    const workerCheck = await query(
      'SELECT id FROM worker_profiles WHERE id = $1',
      [worker_id]
    );

    if (workerCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found'
      });
    }

    await transaction(async (client) => {
      await client.query(
        `UPDATE deliveries 
         SET worker_id = $1, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [worker_id, deliveryId]
      );

      // Notify Worker
      const workerUser = await client.query('SELECT u.id as user_id, u.preferred_language FROM worker_profiles wp JOIN users u ON wp.user_id = u.id WHERE wp.id = $1', [worker_id]);
      const workerLang = workerUser.rows[0].preferred_language || 'en';
      const workerNotification = await notificationService.createNotification({
        userId: workerUser.rows[0].user_id,
        title: t(workerLang, 'new_task_assigned_title'),
        message: t(workerLang, 'new_task_assigned_body'),
        type: 'worker_assignment',
        referenceId: deliveryId,
        referenceType: 'delivery',
        dbClient: client,
        sendPush: false
      });

      // Notify Client (Optional but good for flow)
      const clientDelivery = await client.query(
        `SELECT cp.user_id, u.preferred_language, wp.full_name as worker_name 
         FROM deliveries d
         JOIN client_profiles cp ON d.client_id = cp.id
         JOIN users u ON cp.user_id = u.id
         JOIN worker_profiles wp ON wp.id = $1
         WHERE d.id = $2`,
        [worker_id, deliveryId]
      );

      if (clientDelivery.rows.length > 0) {
        const clientLang = clientDelivery.rows[0].preferred_language || 'en';
        const clientNotification = await notificationService.createNotification({
          userId: clientDelivery.rows[0].user_id,
          title: t(clientLang, 'request_assigned_title'),
          message: t(clientLang, 'request_assigned_body'),
          type: 'delivery_status',
          referenceId: deliveryId,
          referenceType: 'delivery',
          dbClient: client,
          sendPush: false
        });

        return {
          workerId: workerUser.rows[0].user_id,
          workerNotification,
          clientId: clientDelivery.rows[0].user_id,
          clientNotification
        };
      }
      
      return {
        workerId: workerUser.rows[0].user_id,
        workerNotification
      };
    });

    // Send push notifications after transaction commits
    notificationService.sendPush(result.workerId, result.workerNotification);
    if (result.clientId && result.clientNotification) {
      notificationService.sendPush(result.clientId, result.clientNotification);
    }

    res.json({
      success: true,
      message: 'Worker assigned successfully'
    });
  } catch (error) {
    console.error('Error assigning worker to delivery:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to assign worker'
    });
  }
};

/**
 * POST /api/v1/admin/deliveries/:id/unassign
 */
const unassignWorkerFromDelivery = async (req, res) => {
  try {
    const deliveryId = req.params.id;
    
    // Check if delivery has a linked request
    const deliveryCheck = await query(
      'SELECT request_id FROM deliveries WHERE id = $1',
      [deliveryId]
    );

    if (deliveryCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Delivery not found'
      });
    }

    const requestId = deliveryCheck.rows[0].request_id;

    await transaction(async (client) => {
      // If delivery came from a request, restore the request
      if (requestId) {
        await client.query(
          `UPDATE delivery_requests 
           SET status = 'pending', assigned_worker_id = NULL, updated_at = CURRENT_TIMESTAMP 
           WHERE id = $1`,
          [requestId]
        );
        // Delete the delivery
        await client.query('DELETE FROM deliveries WHERE id = $1', [deliveryId]);
      } else {
        // Just unassign worker for quick deliveries
        await client.query(
          'UPDATE deliveries SET worker_id = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
          [deliveryId]
        );
      }
    });

    res.json({ success: true, message: 'Worker unassigned from delivery' });
  } catch (error) {
    logger.error('Unassign delivery worker error:', error);
    res.status(500).json({ success: false, message: 'Failed to unassign worker' });
  }
};

const deleteDelivery = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if this is an assigned request (in_progress)
    const requestCheck = await query(
      'SELECT id FROM delivery_requests WHERE id = $1 AND status = \'in_progress\'',
      [id]
    );

    if (requestCheck.rows.length > 0) {
      // This is an assigned request, cancel it
      await query(
        'UPDATE delivery_requests SET status = \'cancelled\', assigned_worker_id = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
        [id]
      );
      
      return res.json({
        success: true,
        message: 'Request cancelled successfully'
      });
    }

    // Check if this is an assigned coupon request
    const couponCheck = await query(
      'SELECT id FROM coupon_book_requests WHERE id = $1 AND status IN (\'assigned\', \'in_progress\')',
      [id]
    );

    if (couponCheck.rows.length > 0) {
      // This is an assigned coupon request, cancel it
      await query(
        'UPDATE coupon_book_requests SET status = \'cancelled\', assigned_worker_id = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
        [id]
      );
      
      return res.json({
        success: true,
        message: 'Request cancelled successfully'
      });
    }

    // Otherwise, delete the actual delivery
    const result = await query(
      'DELETE FROM deliveries WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Delivery not found'
      });
    }

    res.json({
      success: true,
      message: 'Delivery deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting delivery:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to delete delivery'
    });
  }
};

/**
 * POST /api/v1/admin/deliveries/quick
 * Create a quick delivery without a request
 */
const createQuickDelivery = async (req, res) => {
  try {
    const { client_id, worker_id, gallons_delivered, empty_gallons_returned, delivery_date, notes, is_paid, custom_amount } = req.body;
    
    logger.info('Quick delivery request:', { client_id, worker_id, gallons_delivered, empty_gallons_returned, is_paid, custom_amount });

    await transaction(async (client) => {
      // Get client profile - accept both user_id and profile_id
      const clientProfile = await client.query(
        `SELECT cp.id as profile_id, cp.user_id, cp.subscription_type, cp.remaining_coupons, cp.current_debt, u.preferred_language, u.is_active 
         FROM client_profiles cp
         JOIN users u ON cp.user_id = u.id
         WHERE cp.id = $1 OR cp.user_id = $1 FOR UPDATE`,
        [client_id]
      );

      if (clientProfile.rows.length === 0) {
        logger.error('Client profile not found:', { client_id });
        throw new Error('Client not found');
      }

      const clientData = clientProfile.rows[0];
      const actualClientId = clientData.profile_id;

      if (!clientData.is_active) {
        throw new Error('Client account is inactive');
      }

      // Check if debt exceeds limit (₪10,000) for cash clients
      if ((clientData.subscription_type === 'cash' || clientData.subscription_type === 'pay_as_you_go') && parseFloat(clientData.current_debt) > 10000) {
        throw new Error(`Credit limit exceeded. Client owes ₪${clientData.current_debt}. Payment required before further deliveries.`);
      }

      // Basic validations
      if (custom_amount !== undefined && custom_amount < 0) {
        throw new Error('Custom amount cannot be negative');
      }
      if (empty_gallons_returned !== undefined && empty_gallons_returned < 0) {
        throw new Error('Empty gallons returned cannot be negative');
      }

      const effectiveTotalPrice = custom_amount !== undefined ? custom_amount : (gallons_delivered * 10);
      const paidAmountValue = is_paid === true ? effectiveTotalPrice : 0;

      // Create delivery
      const deliveryResult = await client.query(
        `INSERT INTO deliveries (
          client_id, worker_id, delivery_date, actual_delivery_time, 
          gallons_delivered, empty_gallons_returned, 
          status, notes, created_at, paid_amount, total_price
        ) VALUES ($1, $2, COALESCE($3::date, CURRENT_DATE), NOW(), $4, $5, 'completed', $6, NOW(), $7, $8)
        RETURNING id`,
        [actualClientId, worker_id, delivery_date, gallons_delivered, empty_gallons_returned || 0, notes, paidAmountValue, effectiveTotalPrice]
      );

      const deliveryId = deliveryResult.rows[0].id;

      // Update client's gallons on hand (delivered - returned)
      const netGallons = gallons_delivered - (empty_gallons_returned || 0);
      
      // Check if client has enough gallons to return
      if (empty_gallons_returned && empty_gallons_returned > 0) {
        const clientCheck = await client.query(
          'SELECT gallons_on_hand FROM client_profiles WHERE id = $1',
          [actualClientId]
        );
        const currentGallons = clientCheck.rows[0].gallons_on_hand;
        if (empty_gallons_returned > currentGallons + gallons_delivered) {
          throw new Error(`Cannot return ${empty_gallons_returned} gallons. Client only has ${currentGallons} gallons on hand.`);
        }
      }
      
      await client.query(
        'UPDATE client_profiles SET gallons_on_hand = gallons_on_hand + $1 WHERE id = $2',
        [netGallons, actualClientId]
      );

      // Handle payment based on subscription type
      if (clientData.subscription_type === 'coupon_book') {
        // Deduct coupons
        const couponsNeeded = Math.ceil(gallons_delivered / 20);
        await client.query(
          'UPDATE client_profiles SET remaining_coupons = remaining_coupons - $1 WHERE id = $2',
          [couponsNeeded, actualClientId]
        );
      } else if (clientData.subscription_type === 'pay_as_you_go' || clientData.subscription_type === 'cash') {
        // Cash payment - use custom amount or default ₪10 per gallon
        const rawAmount = custom_amount !== undefined ? custom_amount : (gallons_delivered * 10);
        const amount = Math.round(rawAmount * 100) / 100;
        
        if (is_paid === true) {
          // Record payment to revenue
          await client.query(
            `INSERT INTO payments (payer_id, amount, payment_method, payment_status, payment_date, description)
             VALUES ($1, $2, 'cash', 'completed', NOW(), $3)`,
            [clientData.user_id, amount, `Delivery payment - ${gallons_delivered} gallons`]
          );
        } else {
          // Explicit lock for debt update
          await client.query(
            'SELECT current_debt FROM client_profiles WHERE id = $1 FOR UPDATE',
            [actualClientId]
          );

          // Add to client debt
          await client.query(
            'UPDATE client_profiles SET current_debt = current_debt + $1 WHERE id = $2',
            [amount, actualClientId]
          );
        }
      }

      // Notify client
      const notification = await notificationService.createNotification({
        userId: clientData.user_id,
        title: t(clientData.preferred_language, 'water_delivered_title'),
        message: t(clientData.preferred_language, 'water_delivered_body', gallons_delivered),
        type: 'delivery_status',
        referenceId: deliveryId,
        referenceType: 'delivery',
        dbClient: client,
        sendPush: false
      });

      return {
        userId: clientData.user_id,
        notification
      };
    });

    // Send push notification after transaction commits
    notificationService.sendPush(result.userId, result.notification);

    logger.info('Quick delivery created:', { admin: req.user.id });

    res.status(201).json({
      success: true,
      message: 'Delivery created successfully'
    });
  } catch (error) {
    logger.error('Create quick delivery error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: error.message || 'Failed to create delivery'
    });
  }
};

/**
 * PATCH /api/v1/admin/deliveries/:id
 * Update delivery details
 */
const updateDelivery = async (req, res) => {
  try {
    const { id } = req.params;
    const { gallons_delivered, empty_gallons_returned, notes, delivery_date } = req.body;

    await transaction(async (client) => {
      // Get old delivery values
      const oldDelivery = await client.query(
        'SELECT client_id, gallons_delivered, empty_gallons_returned FROM deliveries WHERE id = $1',
        [id]
      );

      if (oldDelivery.rows.length === 0) {
        throw new Error('Delivery not found');
      }

      const old = oldDelivery.rows[0];
      const oldNet = old.gallons_delivered - (old.empty_gallons_returned || 0);

      // Update delivery
      const updateFields = [];
      const updateValues = [];
      let paramIndex = 1;

      if (gallons_delivered !== undefined) {
        updateFields.push(`gallons_delivered = $${paramIndex++}`);
        updateValues.push(gallons_delivered);
      }
      if (empty_gallons_returned !== undefined) {
        updateFields.push(`empty_gallons_returned = $${paramIndex++}`);
        updateValues.push(empty_gallons_returned);
      }
      if (notes !== undefined) {
        updateFields.push(`notes = $${paramIndex++}`);
        updateValues.push(notes);
      }
      if (delivery_date !== undefined) {
        updateFields.push(`delivery_date = $${paramIndex++}`);
        updateValues.push(delivery_date);
      }

      updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
      updateValues.push(id);

      if (updateFields.length === 1) {
        // Only updated_at, nothing to update
        return res.json({
          success: true,
          message: 'No changes to update',
          data: oldDelivery.rows[0]
        });
      }

      const result = await client.query(
        `UPDATE deliveries 
         SET ${updateFields.join(', ')}
         WHERE id = $${paramIndex}
         RETURNING *`,
        updateValues
      );

      // Update client's gallons on hand
      const newDelivered = gallons_delivered ?? old.gallons_delivered;
      const newReturned = empty_gallons_returned ?? old.empty_gallons_returned ?? 0;
      const newNet = newDelivered - newReturned;
      const netChange = newNet - oldNet;

      // Check if client has enough gallons for the new return amount
      if (netChange < 0) {
        const clientCheck = await client.query(
          'SELECT gallons_on_hand FROM client_profiles WHERE id = $1',
          [old.client_id]
        );
        const currentGallons = clientCheck.rows[0].gallons_on_hand;
        if (currentGallons + netChange < 0) {
          throw new Error(`Cannot return ${newReturned} gallons. Client only has ${currentGallons} gallons on hand.`);
        }
      }

      await client.query(
        'UPDATE client_profiles SET gallons_on_hand = gallons_on_hand + $1 WHERE id = $2',
        [netChange, old.client_id]
      );

      res.json({
        success: true,
        message: 'Delivery updated successfully',
        data: result.rows[0]
      });
    });
  } catch (error) {
    logger.error('Update delivery error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: error.message || 'Failed to update delivery'
    });
  }
};

/**
 * GET /api/v1/admin/users
 * Get all users with filtering
 */
const getAllUsers = async (req, res) => {
  try {
    const { role, is_active, search, on_shift, payment_method, coupon_size, limit = 50, offset = 0 } = req.query;

    let queryText = `
      SELECT 
        u.id,
        u.username,
        u.email,
        u.phone_number,
        u.role,
        u.is_active,
        u.created_at,
        u.last_login,
        CASE 
          WHEN 'client' = ANY(u.role) THEN 
            json_build_object(
              'id', cp.id,
              'full_name', cp.full_name,
              'address', cp.address,
              'subscription_type', cp.subscription_type,
              'remaining_coupons', cp.remaining_coupons,
              'current_debt', cp.current_debt,
              'monthly_usage_gallons', cp.monthly_usage_gallons,
              'home_latitude', cp.home_latitude,
              'home_longitude', cp.home_longitude,
              'gallons_on_hand', cp.gallons_on_hand,
              'dispenser', (SELECT json_build_object('id', d.id, 'serial_number', d.serial_number, 'status', d.status) FROM dispensers d WHERE d.current_client_id = cp.id LIMIT 1),
              'dispensers', (SELECT json_agg(json_build_object('id', d.id, 'serial_number', d.serial_number, 'status', d.status)) FROM dispensers d WHERE d.current_client_id = cp.id),
              'dispensers_count', (SELECT COUNT(*) FROM dispensers d WHERE d.current_client_id = cp.id),
              'coupon_book_size', cs.size
            )
          WHEN u.role && ARRAY['delivery_worker', 'onsite_worker']::user_role[] THEN
            json_build_object(
              'id', wp.id,
              'full_name', wp.full_name,
              'worker_type', wp.worker_type,
              'hire_date', wp.hire_date,
              'vehicle_current_gallons', wp.vehicle_current_gallons,
              'gps_sharing_enabled', wp.gps_sharing_enabled,
              'current_salary', wp.current_salary,
              'debt_advances', wp.debt_advances,
              'shift_id', wp.shift_id,
              'shift', (
                SELECT json_build_object(
                  'id', ws.id,
                  'name', ws.name,
                  'days_of_week', ws.days_of_week,
                  'start_time', ws.start_time,
                  'end_time', ws.end_time
                )
                FROM work_shifts ws
                WHERE ws.id = wp.shift_id
              ),
              'is_active_now', is_worker_active_now(u.id),
              'current_leave', (
                SELECT json_build_object(
                  'id', wl.id,
                  'leave_type', wl.leave_type,
                  'start_date', wl.start_date,
                  'end_date', wl.end_date,
                  'reason', wl.reason
                )
                FROM worker_leaves wl
                WHERE wl.user_id = u.id
                AND CURRENT_DATE BETWEEN wl.start_date AND wl.end_date
                LIMIT 1
              ),
              'active_tasks_count', (
                SELECT COUNT(*) FROM (
                  SELECT id FROM deliveries WHERE worker_id = wp.id AND status = 'in_progress'
                  UNION ALL
                  SELECT id FROM delivery_requests WHERE assigned_worker_id = wp.id AND status = 'in_progress'
                ) as tasks
              )
            )
          ELSE NULL
        END as profile
      FROM users u
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      LEFT JOIN coupon_sizes cs ON cp.coupon_book_size_id = cs.id
      LEFT JOIN worker_profiles wp ON u.id = wp.user_id
      WHERE 1=1
    `;

    const queryParams = [];
    let paramCount = 0;

    if (role) {
      paramCount++;
      queryText += ` AND u.role && $${paramCount}::user_role[]`;
      queryParams.push(Array.isArray(role) ? role : [role]);
    }

    if (is_active !== undefined) {
      paramCount++;
      queryText += ` AND u.is_active = $${paramCount}`;
      queryParams.push(is_active === 'true');
    }

    if (search) {
      paramCount++;
      queryText += ` AND (u.username ILIKE $${paramCount} OR u.email ILIKE $${paramCount} OR u.phone_number ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    if (on_shift !== undefined) {
      queryText += ` AND u.is_active = true AND is_worker_active_now(u.id) = ${on_shift === 'true'}`;
    }

    if (payment_method) {
      if (payment_method === 'coupons') {
        queryText += ` AND cp.subscription_type = 'coupon_book'`;
      } else if (payment_method === 'cash') {
        queryText += ` AND cp.subscription_type = 'cash'`;
      }
    }

    if (coupon_size) {
      paramCount++;
      queryText += ` AND cs.size = $${paramCount}`;
      queryParams.push(parseInt(coupon_size));
    }

    queryText += ` ORDER BY u.created_at DESC
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;

    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, queryParams);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM users u';
    if (payment_method || coupon_size) {
      countQuery += ' LEFT JOIN client_profiles cp ON u.id = cp.user_id';
      countQuery += ' LEFT JOIN coupon_sizes cs ON cp.coupon_book_size_id = cs.id';
    }
    countQuery += ' WHERE 1=1';
    const countParams = [];
    let countParamNum = 0;

    if (role) {
      countParamNum++;
      countQuery += ` AND role && $${countParamNum}::user_role[]`;
      countParams.push(Array.isArray(role) ? role : [role]);
    }

    if (is_active !== undefined) {
      countParamNum++;
      countQuery += ` AND is_active = $${countParamNum}`;
      countParams.push(is_active === 'true');
    }

    if (search) {
      countParamNum++;
      countQuery += ` AND (username ILIKE $${countParamNum} OR email ILIKE $${countParamNum} OR phone_number ILIKE $${countParamNum})`;
      countParams.push(`%${search}%`);
    }

    if (on_shift !== undefined) {
      countQuery += ` AND u.is_active = true AND is_worker_active_now(u.id) = ${on_shift === 'true'}`;
    }

    if (payment_method) {
      if (payment_method === 'coupons') {
        countQuery += ` AND cp.subscription_type = 'coupon_book'`;
      } else if (payment_method === 'cash') {
        countQuery += ` AND cp.subscription_type = 'cash'`;
      }
    }

    if (coupon_size) {
      countParamNum++;
      countQuery += ` AND cs.size = $${countParamNum}`;
      countParams.push(parseInt(coupon_size));
    }

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        users: result.rows,
        pagination: {
          total,
          limit: parseInt(limit),
          offset: parseInt(offset),
          has_more: offset + result.rows.length < total
        }
      }
    });
  } catch (error) {
    logger.error('Get all users error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get users'
    });
  }
};

/**
 * POST /api/v1/admin/users
 * Create a new user (client or worker)
 */
const createUser = async (req, res) => {
  try {
    const {
      username,
      email,
      phone_number,
      password,
      role,
      full_name,
      address,
      latitude,
      longitude,
      home_latitude,
      home_longitude,
      subscription_type,
      worker_type,
      initial_coupons,
      payment_method,
      is_paid,
      custom_amount,
      current_salary,
      shift_id
    } = req.body;

    const roles = Array.isArray(role) ? role : [role];

    await transaction(async (client) => {
      // Hash password
      const passwordHash = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 12);

      // Create user with multiple roles
      const userResult = await client.query(
        `INSERT INTO users (username, email, phone_number, password_hash, role)
         VALUES ($1, $2, $3, $4, $5::user_role[])
         RETURNING id`,
        [username, email, phone_number, passwordHash, roles]
      );

      const userId = userResult.rows[0].id;

      // Create profile based on roles
      if (roles.includes('client')) {
        // Get coupon size ID if initial_coupons provided
        let couponSizeId = null;
        if (initial_coupons) {
          const sizeResult = await client.query(
            'SELECT id FROM coupon_sizes WHERE size = $1',
            [initial_coupons]
          );
          if (sizeResult.rows.length > 0) {
            couponSizeId = sizeResult.rows[0].id;
          }
        }
        
        await client.query(
          `INSERT INTO client_profiles (
            user_id, full_name, address,
            home_latitude, home_longitude,
            subscription_type, subscription_start_date, subscription_end_date,
            remaining_coupons, coupon_book_size_id
          ) VALUES ($1, $2, $3, $4, $5, $6, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', $7, $8)`,
          [userId, full_name || 'New Client', address || 'N/A', home_latitude || latitude, home_longitude || longitude, subscription_type || 'coupon_book', subscription_type === 'coupon_book' ? (initial_coupons || 0) : 0, couponSizeId]
        );

        // Handle payment for initial coupons
        if (initial_coupons && initial_coupons > 0) {
          // Use custom_amount if provided (allows for 0), otherwise use default calculation
          const totalAmount = custom_amount !== undefined ? custom_amount : (initial_coupons * 10);
          
          if (is_paid === true) {
            // Record payment to revenue
            await client.query(
              `INSERT INTO payments (payer_id, amount, payment_method, payment_status, payment_date, description)
               VALUES ($1, $2, $3, 'completed', NOW(), $4)`,
              [userId, totalAmount, payment_method || 'cash', `Initial coupons purchase - ${initial_coupons} coupons`]
            );
          } else {
            // Add debt to client
            await client.query(
              `UPDATE client_profiles 
               SET current_debt = current_debt + $1 
               WHERE user_id = $2`,
              [totalAmount, userId]
            );
          }
        }
      }
      
      if (roles.includes('delivery_worker') || roles.includes('onsite_worker')) {
        const defaultType = roles.includes('onsite_worker') ? 'onsite' : 'delivery';
        await client.query(
          `INSERT INTO worker_profiles (
            user_id, full_name, worker_type, hire_date, current_salary, shift_id
          ) VALUES ($1, $2, $3, CURRENT_DATE, $4, $5)`,
          [userId, full_name || 'New Worker', worker_type || defaultType, current_salary || 0, shift_id || null]
        );
      }

      logger.info('User created by admin:', { userId, roles, admin: req.user.id });
    });

    res.status(201).json({
      success: true,
      message: 'User created successfully'
    });
  } catch (error) {
    logger.error('Create user error:', error);
    
    if (error.code === '23505') {
      return res.status(400).json({
        success: false,
        message: 'Username or phone number already exists'
      });
    }

    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to create user'
    });
  }
};

/**
 * PUT /api/v1/admin/users/:id/toggle-active
 * Toggle user active status
 */
const toggleUserActive = async (req, res) => {
  try {
    const userId = req.params.id;

    // Can't deactivate yourself
    if (parseInt(userId) === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot deactivate your own account'
      });
    }

    // Toggle active status
    const result = await query(
      `UPDATE users 
       SET is_active = NOT is_active, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1
       RETURNING is_active`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    logger.info('User status toggled:', { userId, new_status: result.rows[0].is_active, admin: req.user.id });

    res.json({
      success: true,
      message: `User ${result.rows[0].is_active ? 'activated' : 'deactivated'}`,
      data: { is_active: result.rows[0].is_active }
    });
  } catch (error) {
    logger.error('Toggle user active error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to toggle user status'
    });
  }
};

/**
 * GET /api/v1/admin/analytics/overview
 * Get business analytics overview
 */
const getAnalyticsOverview = async (req, res) => {
  try {
    const { start_date, end_date } = req.query;

    // Build safe date filters
    const startDate = start_date || null;
    const endDate = end_date || new Date().toISOString().split('T')[0];

    const dateFilter = startDate
      ? `AND delivery_date BETWEEN '${startDate}' AND '${endDate}'`
      : `AND delivery_date >= CURRENT_DATE - INTERVAL '30 days'`;

    const paymentDateFilter = startDate
      ? `AND DATE(payment_date) BETWEEN '${startDate}' AND '${endDate}'`
      : `AND DATE(payment_date) >= CURRENT_DATE - INTERVAL '30 days'`;

    const expenseDateFilter = startDate
      ? `AND DATE(created_at) BETWEEN '${startDate}' AND '${endDate}'`
      : `AND DATE(created_at) >= CURRENT_DATE - INTERVAL '30 days'`;

    const fillingDateFilter = startDate
      ? `AND DATE(fs.completion_time) BETWEEN '${startDate}' AND '${endDate}'`
      : `AND DATE(fs.completion_time) >= CURRENT_DATE - INTERVAL '30 days'`;

    // Get comprehensive analytics
    logger.info('Fetching analytics with filters:', { startDate, endDate, dateFilter, paymentDateFilter, expenseDateFilter, fillingDateFilter });
    
    const [
      deliveryStats,
      revenueStats,
      expenseStats,
      expenseList,
      salaryAdvances,
      paymentLogs,
      workerStats,
      clientStats,
      onsiteWorkerStats,
      dailyTrend,
      subscriptionBreakdown,
      requestStats,
      avgResponseTime,
      deliveryWorkerUtilization,
      onsiteWorkerUtilization
    ] = await Promise.all([
      // ... previous queries ...
      // Delivery statistics
      query(`
        SELECT 
          COUNT(*) as total_deliveries,
          SUM(gallons_delivered) as total_gallons,
          AVG(gallons_delivered) as avg_gallons,
          COUNT(DISTINCT client_id) as unique_clients,
          COUNT(DISTINCT worker_id) as active_workers,
          COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_deliveries,
          COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_deliveries,
          COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress_deliveries,
          COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_deliveries
        FROM deliveries
        WHERE 1=1 ${dateFilter.replace('AND delivery_date', 'AND delivery_date')}
      `),

      // Revenue statistics (Income)
      query(`
        SELECT 
          COUNT(*) as total_transactions,
          SUM(amount) as total_revenue,
          AVG(amount) as avg_transaction,
          SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END) as cash_revenue,
          SUM(CASE WHEN payment_method = 'credit_card' THEN amount ELSE 0 END) as card_revenue
        FROM payments
        WHERE payment_status = 'completed' ${paymentDateFilter}
      `),

      // Expense statistics (Outcome)
      query(`
        SELECT 
          COUNT(*) as total_expenses,
          SUM(amount) as total_expenses_amount,
          SUM(CASE WHEN payment_method = 'worker_pocket' THEN amount ELSE 0 END) as my_pocket_expenses,
          SUM(CASE WHEN payment_method = 'company_pocket' THEN amount ELSE 0 END) as company_expenses,
          SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END) as cash_expenses,
          SUM(CASE WHEN payment_method = 'card' THEN amount ELSE 0 END) as card_expenses,
          SUM(CASE WHEN payment_status = 'paid' THEN amount ELSE 0 END) as paid_expenses,
          SUM(CASE WHEN payment_status IN ('unpaid', 'pending') THEN amount ELSE 0 END) as unpaid_expenses
        FROM worker_expenses
        WHERE 1=1 ${expenseDateFilter}
      `),

      // Expense list details
      query(`
        SELECT 
          we.id,
          we.amount,
          we.payment_method,
          we.payment_status,
          we.destination,
          we.notes,
          we.created_at,
          u.username,
          wp.full_name as worker_name
        FROM worker_expenses we
        JOIN users u ON we.user_id = u.id
        LEFT JOIN worker_profiles wp ON u.id = wp.user_id
        WHERE 1=1 ${expenseDateFilter.replace('created_at', 'we.created_at')}
        ORDER BY we.created_at DESC
        LIMIT 100
      `),

      // Salary advances
      query(`
        SELECT 
          wp.user_id,
          u.username,
          wp.full_name as worker_name,
          wp.debt_advances as advance_amount,
          wp.current_salary
        FROM worker_profiles wp
        JOIN users u ON wp.user_id = u.id
        WHERE wp.debt_advances > 0
        ORDER BY wp.debt_advances DESC
      `),

      // Payment logs for the period
      query(`
        SELECT 
          p.id,
          p.amount,
          p.payment_method,
          p.payment_date,
          u.username,
          cp.full_name as client_name
        FROM payments p
        JOIN users u ON p.payer_id = u.id
        LEFT JOIN client_profiles cp ON u.id = cp.user_id
        WHERE p.payment_status = 'completed' ${paymentDateFilter}
        ORDER BY p.payment_date DESC
        LIMIT 100
      `),

      // Worker performance (Delivery)
      query(`
        SELECT 
          w.id,
          w.full_name,
          COUNT(d.id) as deliveries_completed,
          SUM(d.gallons_delivered) as total_gallons
        FROM worker_profiles w
        LEFT JOIN deliveries d ON w.id = d.worker_id AND d.status = 'completed' ${dateFilter}
        WHERE w.worker_type = 'delivery'
        GROUP BY w.id, w.full_name
        ORDER BY deliveries_completed DESC
        LIMIT 10
      `),

      // Client activity
      query(`
        SELECT 
          COUNT(DISTINCT c.id) as total_clients,
          COUNT(DISTINCT c.id) as active_subscriptions,
          0 as expired_subscriptions,
          SUM(cp.current_debt) as total_debt
        FROM client_profiles cp
        JOIN users c ON cp.user_id = c.id
      `),

      // On-site worker performance (Filling)
      query(`
        SELECT 
          w.id,
          w.full_name,
          COUNT(fs.id) as sessions_completed,
          SUM(fs.gallons_filled) as total_gallons_filled,
          COALESCE(AVG(fs.gallons_filled), 0) as avg_filling_rate
        FROM worker_profiles w
        LEFT JOIN filling_sessions fs ON w.id = fs.worker_id 
          ${fillingDateFilter}
        WHERE w.worker_type = 'onsite'
        GROUP BY w.id, w.full_name
        ORDER BY total_gallons_filled DESC NULLS LAST
        LIMIT 10
      `),

      // Daily trend (last 7 days)
      query(`
        SELECT 
          d.day::date,
          COALESCE(count(del.id), 0) as delivery_count,
          COALESCE(sum(del.gallons_delivered), 0) as gallons_delivered,
          COALESCE(sum(p.amount), 0) as revenue
        FROM generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, '1 day') d(day)
        LEFT JOIN deliveries del ON DATE(del.delivery_date) = d.day AND del.status = 'completed'
        LEFT JOIN payments p ON DATE(p.payment_date) = d.day AND p.payment_status = 'completed'
        GROUP BY d.day
        ORDER BY d.day ASC
      `),

      // Subscription breakdown
      query(`
        SELECT 
          subscription_type,
          count(*) as count,
          sum(current_debt) as total_debt
        FROM client_profiles
        GROUP BY subscription_type
      `),

      // Request statistics (operational efficiency)
      query(`
        SELECT 
          COUNT(*) as total_requests,
          COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
          COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_requests,
          COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_requests,
          COUNT(CASE WHEN priority = 'urgent' THEN 1 END) as urgent_requests,
          ROUND(AVG(CASE WHEN status = 'completed' THEN requested_gallons END), 2) as avg_request_size
        FROM delivery_requests
        WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
      `),

      // Average response time (request to delivery)
      query(`
        SELECT 
          ROUND(AVG(EXTRACT(EPOCH FROM (d.actual_delivery_time - dr.created_at))/3600), 2) as avg_response_hours,
          ROUND(MIN(EXTRACT(EPOCH FROM (d.actual_delivery_time - dr.created_at))/3600), 2) as fastest_response_hours,
          ROUND(MAX(EXTRACT(EPOCH FROM (d.actual_delivery_time - dr.created_at))/3600), 2) as slowest_response_hours
        FROM delivery_requests dr
        JOIN deliveries d ON dr.id = d.request_id
        WHERE dr.created_at >= CURRENT_DATE - INTERVAL '30 days'
          AND d.status = 'completed'
          AND d.actual_delivery_time IS NOT NULL
      `),

      // Worker utilization (delivery workers)
      query(`
        SELECT 
          COUNT(*) as total_delivery_workers,
          COUNT(CASE WHEN u.is_active = true THEN 1 END) as active_delivery_workers,
          COUNT(CASE WHEN ws.id IS NOT NULL THEN 1 END) as delivery_workers_on_shift,
          COUNT(CASE WHEN d.id IS NOT NULL THEN 1 END) as delivery_workers_busy_today
        FROM worker_profiles wp
        JOIN users u ON wp.user_id = u.id
        LEFT JOIN work_shifts ws ON wp.shift_id = ws.id
        LEFT JOIN deliveries d ON wp.id = d.worker_id 
          AND DATE(d.delivery_date) = CURRENT_DATE
          AND d.status IN ('pending', 'in_progress')
        WHERE wp.worker_type = 'delivery'
      `),

      // Onsite worker utilization
      query(`
        SELECT 
          COUNT(*) as total_onsite_workers,
          COUNT(CASE WHEN u.is_active = true THEN 1 END) as active_onsite_workers,
          COUNT(CASE WHEN ws.id IS NOT NULL THEN 1 END) as onsite_workers_on_shift,
          COUNT(CASE WHEN fs.id IS NOT NULL THEN 1 END) as onsite_workers_busy_today
        FROM worker_profiles wp
        JOIN users u ON wp.user_id = u.id
        LEFT JOIN work_shifts ws ON wp.shift_id = ws.id
        LEFT JOIN filling_sessions fs ON wp.id = fs.worker_id 
          AND DATE(fs.start_time) = CURRENT_DATE
        WHERE wp.worker_type = 'onsite'
      `)
    ]);

    const revenue = revenueStats.rows[0];
    const expenses = expenseStats.rows[0];
    const delivery = deliveryStats.rows[0];
    const requests = requestStats.rows[0];
    const responseTime = avgResponseTime.rows[0];
    const deliveryUtilization = deliveryWorkerUtilization.rows[0];
    const onsiteUtilization = onsiteWorkerUtilization.rows[0];
    
    const totalAdvances = salaryAdvances.rows.reduce((sum, row) => sum + parseFloat(row.advance_amount || 0), 0);
    const totalOutcome = (parseFloat(expenses.total_expenses_amount) || 0) + totalAdvances;
    const netIncome = (parseFloat(revenue.total_revenue) || 0) - totalOutcome;

    // Calculate operational efficiency metrics
    const completionRate = delivery.total_deliveries > 0 
      ? ((delivery.completed_deliveries / delivery.total_deliveries) * 100).toFixed(1)
      : 0;
    const cancellationRate = delivery.total_deliveries > 0
      ? ((delivery.cancelled_deliveries / delivery.total_deliveries) * 100).toFixed(1)
      : 0;
    const requestFulfillmentRate = requests.total_requests > 0
      ? ((requests.completed_requests / requests.total_requests) * 100).toFixed(1)
      : 0;
    const deliveryWorkerUtilizationRate = deliveryUtilization.active_delivery_workers > 0
      ? ((deliveryUtilization.delivery_workers_busy_today / deliveryUtilization.active_delivery_workers) * 100).toFixed(1)
      : 0;
    const onsiteWorkerUtilizationRate = onsiteUtilization.active_onsite_workers > 0
      ? ((onsiteUtilization.onsite_workers_busy_today / onsiteUtilization.active_onsite_workers) * 100).toFixed(1)
      : 0;
    const avgGallonsPerDelivery = delivery.completed_deliveries > 0
      ? (delivery.total_gallons / delivery.completed_deliveries).toFixed(1)
      : 0;
    const avgRevenuePerDelivery = delivery.completed_deliveries > 0
      ? (revenue.total_revenue / delivery.completed_deliveries).toFixed(2)
      : 0;

    res.json({
      success: true,
      data: {
        deliveries: delivery,
        revenue: revenue,
        expenses: expenses,
        salary_advances: {
          total_advances: totalAdvances,
          workers_with_advances: salaryAdvances.rows.length,
          advance_details: salaryAdvances.rows
        },
        operational_efficiency: {
          completion_rate: parseFloat(completionRate),
          cancellation_rate: parseFloat(cancellationRate),
          request_fulfillment_rate: parseFloat(requestFulfillmentRate),
          avg_response_time_hours: parseFloat(responseTime.avg_response_hours) || 0,
          fastest_response_hours: parseFloat(responseTime.fastest_response_hours) || 0,
          slowest_response_hours: parseFloat(responseTime.slowest_response_hours) || 0,
          delivery_worker_utilization_rate: parseFloat(deliveryWorkerUtilizationRate),
          delivery_workers: {
            total: deliveryUtilization.total_delivery_workers,
            active: deliveryUtilization.active_delivery_workers,
            on_shift: deliveryUtilization.delivery_workers_on_shift,
            busy_today: deliveryUtilization.delivery_workers_busy_today
          },
          onsite_worker_utilization_rate: parseFloat(onsiteWorkerUtilizationRate),
          onsite_workers: {
            total: onsiteUtilization.total_onsite_workers,
            active: onsiteUtilization.active_onsite_workers,
            on_shift: onsiteUtilization.onsite_workers_on_shift,
            busy_today: onsiteUtilization.onsite_workers_busy_today
          },
          avg_gallons_per_delivery: parseFloat(avgGallonsPerDelivery),
          avg_revenue_per_delivery: parseFloat(avgRevenuePerDelivery),
          pending_requests: requests.pending_requests,
          urgent_requests: requests.urgent_requests,
          total_requests: requests.total_requests
        },
        financial_summary: {
          total_income: revenue.total_revenue,
          total_expenses: expenses.total_expenses_amount,
          total_salary_advances: totalAdvances,
          total_outcome: totalOutcome,
          net_income: netIncome,
          profit_margin: revenue.total_revenue > 0 
            ? ((netIncome / revenue.total_revenue) * 100).toFixed(1)
            : 0,
          paid_expenses: expenses.paid_expenses,
          unpaid_expenses: expenses.unpaid_expenses,
          payment_logs: paymentLogs.rows,
          expense_list: expenseList.rows
        },
        payment_logs: paymentLogs.rows,
        top_workers: workerStats.rows,
        onsite_workers: onsiteWorkerStats.rows,
        clients: clientStats.rows[0],
        daily_trend: dailyTrend.rows,
        subscription_breakdown: subscriptionBreakdown.rows,
        period: {
          start: start_date || 'last_30_days',
          end: end_date || 'today'
        }
      }
    });
  } catch (error) {
    logger.error('Get analytics error:', {
      message: error.message,
      stack: error.stack,
      code: error.code
    });
    res.status(500).json({
      success: false,
      message: 'Failed to get analytics',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * DELETE /api/v1/admin/requests/:id
 * Delete a delivery request
 */
const deleteDeliveryRequest = async (req, res) => {
  try {
    const requestId = req.params.id;

    // Check if request exists
    const requestCheck = await query(
      'SELECT id FROM delivery_requests WHERE id = $1',
      [requestId]
    );

    if (requestCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Delivery request not found'
      });
    }

    // Delete the request
    await query('DELETE FROM delivery_requests WHERE id = $1', [requestId]);

    logger.info('Delivery request deleted by admin:', { requestId, admin: req.user.id });

    res.json({
      success: true,
      message: 'Delivery request deleted successfully'
    });
  } catch (error) {
    logger.error('Delete delivery request error:', error);
    
    // Check if it's a foreign key constraint error
    if (error.code === '23503') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete request because it has associated delivery records'
      });
    }

    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to delete delivery request'
    });
  }
};

/**
 * DELETE /api/v1/admin/users/:id
 * Delete a user permanently
 */
const deleteUser = async (req, res) => {
  try {
    const userId = req.params.id;

    // Can't delete yourself
    if (parseInt(userId) === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account'
      });
    }

    // Check if user exists
    const userCheck = await query(
      'SELECT id FROM users WHERE id = $1',
      [userId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Delete the user (profiles will be deleted via ON DELETE CASCADE in DB)
    await query('DELETE FROM users WHERE id = $1', [userId]);

    logger.info('User deleted by admin:', { userId, admin: req.user.id });

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    logger.error('Delete user error:', error);
    
    // Check for foreign key constraints
    if (error.code === '23503') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete user because they have associated records (deliveries, requests, etc.). Deactivate them instead.'
      });
    }

    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to delete user'
    });
  }
};

/**
 * GET /api/v1/admin/users/:id
 * Get detailed user information including profile
 */
const getUserById = async (req, res) => {
  try {
    const userId = req.params.id;

    const result = await query(
      `SELECT 
        u.id, u.username, u.email, u.phone_number, u.role, u.is_active, u.created_at, u.last_login,
        CASE 
          WHEN 'client' = ANY(u.role) THEN 
            json_build_object(
              'id', cp.id,
              'full_name', cp.full_name,
              'address', cp.address,
              'subscription_type', cp.subscription_type,
              'remaining_coupons', cp.remaining_coupons,
              'current_debt', cp.current_debt,
              'subscription_expiry_date', cp.subscription_expiry_date,
              'monthly_usage_gallons', cp.monthly_usage_gallons,
              'home_latitude', cp.home_latitude,
              'home_longitude', cp.home_longitude,
              'gallons_on_hand', cp.gallons_on_hand,
              'dispenser', (SELECT json_build_object('id', d.id, 'serial_number', d.serial_number, 'status', d.status) FROM dispensers d WHERE d.current_client_id = cp.id LIMIT 1),
              'dispensers', (SELECT json_agg(json_build_object('id', d.id, 'serial_number', d.serial_number, 'status', d.status)) FROM dispensers d WHERE d.current_client_id = cp.id),
              'dispensers_count', (SELECT COUNT(*) FROM dispensers d WHERE d.current_client_id = cp.id),
              'coupon_book_size', cs.size
            )
          WHEN u.role && ARRAY['delivery_worker', 'onsite_worker']::user_role[] THEN
            json_build_object(
              'id', wp.id,
              'full_name', wp.full_name,
              'worker_type', wp.worker_type,
              'hire_date', wp.hire_date,
              'vehicle_current_gallons', wp.vehicle_current_gallons,
              'gps_sharing_enabled', wp.gps_sharing_enabled,
              'current_salary', wp.current_salary,
              'debt_advances', wp.debt_advances,
              'active_tasks_count', (
                SELECT COUNT(*) FROM (
                  SELECT id FROM deliveries WHERE worker_id = wp.id AND status = 'in_progress'
                  UNION ALL
                  SELECT id FROM delivery_requests WHERE assigned_worker_id = wp.id AND status = 'in_progress'
                ) as tasks
              )
            )
          ELSE NULL
        END as profile
      FROM users u
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      LEFT JOIN coupon_sizes cs ON cp.coupon_book_size_id = cs.id
      LEFT JOIN worker_profiles wp ON u.id = wp.user_id
      WHERE u.id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Get user by ID error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get user details'
    });
  }
};

/**
 * PATCH /api/v1/admin/users/:id
 * Update user information and profile
 */
const updateUser = async (req, res) => {
  try {
    const userId = req.params.id;
    logger.debug('Received update request for user:', { userId, body: req.body });
    const {
      username,
      password,
      email,
      phone_number,
      role,
      full_name,
      address,
      latitude,
      longitude,
      home_latitude,
      home_longitude,
      subscription_type,
      remaining_coupons,
      coupon_book_size_id,
      coupon_book_size,
      initial_coupons,
      worker_type,
      current_salary,
      debt_advances,
      vehicle_current_gallons,
      shift_id
    } = req.body;

    // Check if user exists
    const userCheck = await query('SELECT role FROM users WHERE id = $1', [userId]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const currentRoles = Array.isArray(userCheck.rows[0].role) ? userCheck.rows[0].role : [userCheck.rows[0].role];
    const newRoles = role ? (Array.isArray(role) ? role : [role]) : currentRoles;

    // Ensure at least one role remains
    if (newRoles.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'User must have at least one role' 
      });
    }

    logger.debug('Updating user roles:', { userId, currentRoles, newRoles });

    await transaction(async (client) => {
      // 1. Update basic user info
      const userFields = [];
      const userValues = [];
      let paramIdx = 1;

      if (username !== undefined) {
        userFields.push(`username = $${paramIdx++}`);
        userValues.push(username);
      }
      if (password !== undefined && password !== '') {
        const passwordHash = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 12);
        userFields.push(`password_hash = $${paramIdx++}`);
        userValues.push(passwordHash);
      }
      if (email !== undefined) {
        userFields.push(`email = $${paramIdx++}`);
        userValues.push(email);
      }
      if (phone_number !== undefined) {
        userFields.push(`phone_number = $${paramIdx++}`);
        userValues.push(phone_number);
      }
      if (role !== undefined) {
        userFields.push(`role = $${paramIdx++}::user_role[]`);
        userValues.push(newRoles);
      }

      if (userFields.length > 0) {
        userValues.push(userId);
        const updateQuery = `UPDATE users SET ${userFields.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = $${paramIdx}`;
        logger.debug('Executing user update query:', { query: updateQuery, values: userValues });
        await client.query(updateQuery, userValues);
      }

      // 2. Ensure profiles exist for new roles
      if (newRoles.includes('client')) {
        const profileCheck = await client.query('SELECT * FROM client_profiles WHERE user_id = $1 FOR UPDATE', [userId]);
        if (profileCheck.rows.length === 0) {
          await client.query(
            `INSERT INTO client_profiles (
              user_id, full_name, address, subscription_type, 
              subscription_start_date, subscription_end_date,
              subscription_expiry_date, remaining_coupons
            ) VALUES ($1, $2, $3, $4, CURRENT_DATE, 
                      CURRENT_DATE + INTERVAL '1 year',
                      CURRENT_DATE + INTERVAL '1 year', $5)`,
            [userId, full_name || 'New Client', address || 'N/A', subscription_type || 'coupon_book', remaining_coupons || 100]
          );
        } else {
          const currentProfile = profileCheck.rows[0];
          
          // Safety check: Don't allow switching from coupon_book to cash if coupons remain
          if (currentProfile.subscription_type === 'coupon_book' && 
              subscription_type !== undefined && 
              subscription_type !== 'coupon_book' && 
              currentProfile.remaining_coupons > 0) {
            throw new Error(`Cannot change subscription type to ${subscription_type}. Client still has ${currentProfile.remaining_coupons} coupons. Please clear coupons first.`);
          }

          // Update existing profile
          const profileFields = [];
          const profileValues = [];
          let pIdx = 1;
          if (full_name !== undefined) { profileFields.push(`full_name = $${pIdx++}`); profileValues.push(full_name); }
          if (address !== undefined) { profileFields.push(`address = $${pIdx++}`); profileValues.push(address); }
          if (home_latitude !== undefined || latitude !== undefined) { 
            profileFields.push(`home_latitude = $${pIdx++}`); 
            profileValues.push(home_latitude !== undefined ? home_latitude : latitude); 
          }
          if (home_longitude !== undefined || longitude !== undefined) { 
            profileFields.push(`home_longitude = $${pIdx++}`); 
            profileValues.push(home_longitude !== undefined ? home_longitude : longitude); 
          }
          if (subscription_type !== undefined) { profileFields.push(`subscription_type = $${pIdx++}`); profileValues.push(subscription_type); }
          
          // Handle coupon_book_size (convert size value to ID)
          // Accept: coupon_book_size, initial_coupons, or remaining_coupons as the size value
          const sizeValue = coupon_book_size || initial_coupons || (subscription_type === 'coupon_book' ? remaining_coupons : undefined);
          if (sizeValue !== undefined && subscription_type === 'coupon_book') {
            const sizeResult = await client.query('SELECT id FROM coupon_sizes WHERE size = $1', [parseInt(sizeValue)]);
            if (sizeResult.rows.length > 0) {
              profileFields.push(`coupon_book_size_id = $${pIdx++}`); 
              profileValues.push(sizeResult.rows[0].id);
            }
          } else if (coupon_book_size_id !== undefined) {
            profileFields.push(`coupon_book_size_id = $${pIdx++}`); 
            profileValues.push(coupon_book_size_id);
          }
          
          // Handle remaining_coupons separately (only if not used for size)
          if (remaining_coupons !== undefined && subscription_type !== 'coupon_book') { 
            profileFields.push(`remaining_coupons = remaining_coupons + $${pIdx++}`); 
            profileValues.push(remaining_coupons);
            // If adding coupons to a non-coupon_book client, change subscription to coupon_book
            if (remaining_coupons > 0) {
              profileFields.push(`subscription_type = $${pIdx++}`);
              profileValues.push('coupon_book');
            }
          }
          
          if (profileFields.length > 0) {
            profileValues.push(userId);
            const profileQuery = `UPDATE client_profiles SET ${profileFields.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE user_id = $${pIdx}`;
            logger.debug('Executing profile update query:', { query: profileQuery, values: profileValues });
            await client.query(profileQuery, profileValues);
          }
        }
      }

      if (newRoles.includes('delivery_worker') || newRoles.includes('onsite_worker')) {
        const profileCheck = await client.query('SELECT id FROM worker_profiles WHERE user_id = $1', [userId]);
        const defaultType = newRoles.includes('onsite_worker') ? 'onsite' : 'delivery';
        if (profileCheck.rows.length === 0) {
          await client.query(
            `INSERT INTO worker_profiles (
              user_id, full_name, worker_type, hire_date, current_salary
            ) VALUES ($1, $2, $3, CURRENT_DATE, $4)`,
            [userId, full_name || 'New Worker', worker_type || defaultType, current_salary || 0]
          );
        } else {
          // Update existing profile
          const profileFields = [];
          const profileValues = [];
          let pIdx = 1;
          if (full_name !== undefined) { profileFields.push(`full_name = $${pIdx++}`); profileValues.push(full_name); }
          if (worker_type !== undefined) { profileFields.push(`worker_type = $${pIdx++}`); profileValues.push(worker_type); }
          if (current_salary !== undefined) { profileFields.push(`current_salary = $${pIdx++}`); profileValues.push(current_salary); }
          if (debt_advances !== undefined) { profileFields.push(`debt_advances = $${pIdx++}`); profileValues.push(debt_advances); }
          if (vehicle_current_gallons !== undefined) { profileFields.push(`vehicle_current_gallons = $${pIdx++}`); profileValues.push(vehicle_current_gallons); }
          if (shift_id !== undefined) { profileFields.push(`shift_id = $${pIdx++}`); profileValues.push(shift_id); }
          
          if (profileFields.length > 0) {
            profileValues.push(userId);
            await client.query(`UPDATE worker_profiles SET ${profileFields.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE user_id = $${pIdx}`, profileValues);
          }
        }
      }
    });

    logger.info('User updated by admin:', { userId, roles: newRoles, admin: req.user.id });

    res.json({
      success: true,
      message: 'User updated successfully'
    });
  } catch (error) {
    logger.error('Update user error:', error);
    if (error.code === '23505') {
      return res.status(400).json({
        success: false,
        message: 'Email or phone number already exists'
      });
    }
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update user'
    });
  }
};

// ============================================================================
// STATION MANAGEMENT
// ============================================================================

const createStation = async (req, res) => {
  try {
    const { name, address } = req.body;

    if (!name || name.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Station name is required'
      });
    }

    const result = await query(
      `INSERT INTO filling_stations (name, address, current_status)
       VALUES ($1, $2, 'open')
       RETURNING *`,
      [name.trim(), address?.trim() || null]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating station:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to create station'
    });
  }
};

const updateStation = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, address } = req.body;

    if (!name || name.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Station name is required'
      });
    }

    const result = await query(
      `UPDATE filling_stations
       SET name = $1, address = $2, updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
      [name.trim(), address?.trim() || null, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Station not found'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating station:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update station'
    });
  }
};

const deleteStation = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      'DELETE FROM filling_stations WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Station not found'
      });
    }

    res.json({
      success: true,
      message: 'Station deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting station:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to delete station'
    });
  }
};

// ============================================================================
// SCHEDULED DELIVERIES
// ============================================================================

const getScheduledDeliveries = async (req, res) => {
  try {
    const result = await query(
      `SELECT sd.*, 
              cp.full_name as client_name,
              wp.full_name as worker_name
       FROM scheduled_deliveries sd
       JOIN client_profiles cp ON sd.client_id = cp.id
       LEFT JOIN worker_profiles wp ON sd.worker_id = wp.id
       ORDER BY sd.created_at DESC`
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Error getting scheduled deliveries:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get scheduled deliveries'
    });
  }
};

const createScheduledDelivery = async (req, res) => {
  try {
    const { client_id, worker_id, gallons, schedule_type, schedule_time, schedule_days, start_date, end_date, frequency_per_week, frequency_per_month, notes } = req.body;

    const result = await query(
      `INSERT INTO scheduled_deliveries 
       (client_id, worker_id, gallons, schedule_type, schedule_time, schedule_days, start_date, end_date, frequency_per_week, frequency_per_month, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [client_id, worker_id, gallons, schedule_type, schedule_time, schedule_days, start_date, end_date, frequency_per_week, frequency_per_month, notes]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating scheduled delivery:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to create scheduled delivery'
    });
  }
};

const updateScheduledDelivery = async (req, res) => {
  try {
    const { id } = req.params;
    const { client_id, worker_id, gallons, schedule_type, schedule_time, schedule_days, start_date, end_date, frequency_per_week, frequency_per_month, is_active, notes } = req.body;

    const result = await query(
      `UPDATE scheduled_deliveries
       SET client_id = $1, worker_id = $2, gallons = $3, schedule_type = $4,
           schedule_time = $5, schedule_days = $6, start_date = $7, end_date = $8,
           frequency_per_week = $9, frequency_per_month = $10, is_active = $11, notes = $12, updated_at = CURRENT_TIMESTAMP
       WHERE id = $13
       RETURNING *`,
      [client_id, worker_id, gallons, schedule_type, schedule_time, schedule_days, start_date, end_date, frequency_per_week, frequency_per_month, is_active, notes, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Scheduled delivery not found'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating scheduled delivery:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update scheduled delivery'
    });
  }
};

const deleteScheduledDelivery = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      'DELETE FROM scheduled_deliveries WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Scheduled delivery not found'
      });
    }

    res.json({
      success: true,
      message: 'Scheduled delivery deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting scheduled delivery:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to delete scheduled delivery'
    });
  }
};

/**
 * PATCH /api/v1/admin/users/:id/advance
 * Update worker salary advance
 */
const updateWorkerAdvance = async (req, res) => {
  try {
    const userId = req.params.id;
    const { amount } = req.body;

    // Get worker profile
    const workerResult = await query(
      'SELECT id, debt_advances FROM worker_profiles WHERE user_id = $1',
      [userId]
    );

    if (workerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found'
      });
    }

    const currentAdvance = parseFloat(workerResult.rows[0].debt_advances) || 0;
    const newAdvance = currentAdvance + amount;

    await query(
      'UPDATE worker_profiles SET debt_advances = $1, updated_at = NOW() WHERE user_id = $2',
      [newAdvance, userId]
    );

    res.json({
      success: true,
      message: 'Salary advance updated',
      data: { debt_advances: newAdvance }
    });
  } catch (error) {
    logger.error('Update worker advance error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update salary advance'
    });
  }
};

// ============================================================================
// EXPENSES MANAGEMENT
// ============================================================================

/**
 * GET /api/v1/admin/expenses
 * Get all worker expenses with summary
 */
const getAllExpenses = async (req, res) => {
  try {
    const result = await query(
      `SELECT 
        we.id, we.amount, we.payment_method, we.payment_status, 
        we.destination, we.notes, we.created_at,
        u.id as user_id, u.username,
        wp.full_name as worker_name
       FROM worker_expenses we
       JOIN users u ON we.user_id = u.id
       LEFT JOIN worker_profiles wp ON u.id = wp.user_id
       ORDER BY we.created_at DESC`
    );

    // Calculate summary
    const summary = result.rows.reduce((acc, expense) => {
      const amount = parseFloat(expense.amount) || 0;
      
      // Company paid directly (already spent)
      if (expense.payment_method === 'company_pocket') {
        acc.company_paid += amount;
      }
      // Worker paid from pocket - company owes worker (all worker_pocket expenses are debt)
      else if (expense.payment_method === 'worker_pocket') {
        acc.debt_to_workers += amount;
      }
      
      return acc;
    }, {
      company_paid: 0,      // Paid directly by company
      debt_to_workers: 0,   // Owed to workers (all worker_pocket expenses)
      total: 0
    });

    summary.total = summary.company_paid;

    res.json({
      success: true,
      data: result.rows,
      summary
    });
  } catch (error) {
    logger.error('Get all expenses error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get expenses'
    });
  }
};

/**
 * PATCH /api/v1/admin/expenses/:id/status
 * Update expense payment status
 */
const updateExpenseStatus = async (req, res) => {
  try {
    const expenseId = req.params.id;
    const { payment_status } = req.body;

    const result = await query(
      `UPDATE worker_expenses
       SET payment_status = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [payment_status, expenseId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    res.json({
      success: true,
      message: 'Expense status updated',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Update expense status error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update expense status'
    });
  }
};

/**
 * PATCH /api/v1/admin/expenses/:id/approve
 * Approve an expense
 */
const approveExpense = async (req, res) => {
  try {
    const expenseId = req.params.id;
    
    const result = await query(
      `UPDATE worker_expenses 
       SET approval_status = 'approved', 
           approved_by = $1, 
           approved_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND approval_status = 'pending'
       RETURNING *`,
      [req.user.userId, expenseId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Expense not found or already processed' 
      });
    }
    
    res.json({ 
      success: true, 
      message: 'Expense approved successfully', 
      data: result.rows[0] 
    });
  } catch (error) {
    logger.error('Approve expense error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to approve expense' 
    });
  }
};

/**
 * PATCH /api/v1/admin/expenses/:id/reject
 * Reject an expense
 */
const rejectExpense = async (req, res) => {
  try {
    const expenseId = req.params.id;
    const { rejection_reason } = req.body;
    
    const result = await query(
      `UPDATE worker_expenses 
       SET approval_status = 'rejected', 
           approved_by = $1, 
           approved_at = CURRENT_TIMESTAMP,
           rejection_reason = $2,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3 AND approval_status = 'pending'
       RETURNING *`,
      [req.user.userId, rejection_reason, expenseId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Expense not found or already processed' 
      });
    }
    
    res.json({ 
      success: true, 
      message: 'Expense rejected successfully', 
      data: result.rows[0] 
    });
  } catch (error) {
    logger.error('Reject expense error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to reject expense' 
    });
  }
};

/**
 * PUT /api/v1/admin/expenses/:id
 * Update expense details
 */
const updateExpense = async (req, res) => {
  try {
    const expenseId = req.params.id;
    const { amount, payment_method, payment_status, destination, notes } = req.body;

    logger.debug('Updating expense:', { expenseId, amount, payment_method, payment_status, destination, notes });

    // Build dynamic update query
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (amount !== undefined) {
      if (amount === null) {
        return res.status(400).json({
          success: false,
          message: 'Amount cannot be null'
        });
      }
      updates.push(`amount = $${paramCount++}`);
      values.push(amount);
    }
    if (payment_method !== undefined) {
      updates.push(`payment_method = $${paramCount++}`);
      values.push(payment_method);
    }
    if (payment_status !== undefined) {
      updates.push(`payment_status = $${paramCount++}`);
      values.push(payment_status);
    }
    if (destination !== undefined) {
      updates.push(`destination = $${paramCount++}`);
      values.push(destination);
    }
    if (notes !== undefined) {
      updates.push(`notes = $${paramCount++}`);
      values.push(notes);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }

    updates.push('updated_at = NOW()');
    values.push(expenseId);

    const result = await query(
      `UPDATE worker_expenses
       SET ${updates.join(', ')}
       WHERE id = $${paramCount}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found'
      });
    }

    res.json({
      success: true,
      message: 'Expense updated',
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Update expense error:', error);
    logger.error('Error details:', { message: error.message, stack: error.stack });
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update expense',
      error: error.message
    });
  }
};

// Get all dispensers
const getDispensers = async (req, res) => {
  try {
    const result = await query(
      `SELECT d.*, cp.full_name as client_name, dt.name as type_name
       FROM dispensers d
       LEFT JOIN client_profiles cp ON d.current_client_id = cp.id
       LEFT JOIN dispenser_types dt ON d.type_id = dt.id
       ORDER BY d.serial_number`
    );
    res.json({ success: true, dispensers: result.rows });
  } catch (error) {
    logger.error('Get dispensers error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to fetch dispensers' });
  }
};

// Create dispenser
const createDispenser = async (req, res) => {
  try {
    const { serial_number, type_id, features, status, current_client_id, dispenser_type } = req.body;
    await query(
      `INSERT INTO dispensers (serial_number, dispenser_type, type_id, features, status, current_client_id, purchase_date)
       VALUES ($1, $2, $3, $4, $5, $6, CURRENT_DATE)`,
      [serial_number, dispenser_type || 'manual', type_id, features || [], status, current_client_id]
    );
    res.json({ success: true, message: 'Dispenser created' });
  } catch (error) {
    logger.error('Create dispenser error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to create dispenser' });
  }
};

// Update dispenser
const updateDispenser = async (req, res) => {
  try {
    const { id } = req.params;
    const { serial_number, type_id, features, status, current_client_id } = req.body;
    
    const updates = [];
    const values = [];
    let paramIndex = 1;
    
    if (serial_number !== undefined) {
      updates.push(`serial_number = $${paramIndex++}`);
      values.push(serial_number);
    }
    if (type_id !== undefined) {
      updates.push(`type_id = $${paramIndex++}`);
      values.push(type_id);
    }
    if (features !== undefined) {
      updates.push(`features = $${paramIndex++}`);
      values.push(features || []);
    }
    if (status !== undefined) {
      updates.push(`status = $${paramIndex++}`);
      values.push(status);
    }
    if (current_client_id !== undefined) {
      updates.push(`current_client_id = $${paramIndex++}`);
      values.push(current_client_id);
    }
    
    if (updates.length === 0) {
      return res.json({ success: true, message: 'No changes to update' });
    }
    
    values.push(id);
    await query(
      `UPDATE dispensers SET ${updates.join(', ')} WHERE id = $${paramIndex}`,
      values
    );
    res.json({ success: true, message: 'Dispenser updated' });
  } catch (error) {
    logger.error('Update dispenser error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to update dispenser' });
  }
};

// Delete dispenser
const deleteDispenser = async (req, res) => {
  try {
    const { id } = req.params;
    await query(`DELETE FROM dispensers WHERE id = $1`, [id]);
    res.json({ success: true, message: 'Dispenser deleted' });
  } catch (error) {
    logger.error('Delete dispenser error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to delete dispenser' });
  }
};

// Dispenser Types
const getDispenserTypes = async (req, res) => {
  try {
    const result = await query('SELECT * FROM dispenser_types ORDER BY display_order, name');
    res.json({ success: true, types: result.rows });
  } catch (error) {
    logger.error('Get types error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to fetch types' });
  }
};

const createDispenserType = async (req, res) => {
  try {
    const { name } = req.body;
    await query('INSERT INTO dispenser_types (name) VALUES ($1)', [name]);
    res.json({ success: true, message: 'Type created' });
  } catch (error) {
    logger.error('Create type error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to create type' });
  }
};

const updateDispenserType = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;
    await query('UPDATE dispenser_types SET name = $1 WHERE id = $2', [name, id]);
    res.json({ success: true, message: 'Type updated' });
  } catch (error) {
    logger.error('Update type error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to update type' });
  }
};

const deleteDispenserType = async (req, res) => {
  try {
    const { id } = req.params;
    await query('DELETE FROM dispenser_types WHERE id = $1', [id]);
    res.json({ success: true, message: 'Type deleted' });
  } catch (error) {
    logger.error('Delete type error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to delete type' });
  }
};

// Dispenser Features
const getDispenserFeatures = async (req, res) => {
  try {
    const result = await query('SELECT * FROM dispenser_features ORDER BY display_order, name');
    res.json({ success: true, features: result.rows });
  } catch (error) {
    logger.error('Get features error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to fetch features' });
  }
};

const createDispenserFeature = async (req, res) => {
  try {
    const { name } = req.body;
    await query('INSERT INTO dispenser_features (name) VALUES ($1)', [name]);
    res.json({ success: true, message: 'Feature created' });
  } catch (error) {
    logger.error('Create feature error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to create feature' });
  }
};

const updateDispenserFeature = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;
    await query('UPDATE dispenser_features SET name = $1 WHERE id = $2', [name, id]);
    res.json({ success: true, message: 'Feature updated' });
  } catch (error) {
    logger.error('Update feature error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to update feature' });
  }
};

const deleteDispenserFeature = async (req, res) => {
  try {
    const { id } = req.params;
    await query('DELETE FROM dispenser_features WHERE id = $1', [id]);
    res.json({ success: true, message: 'Feature deleted' });
  } catch (error) {
    logger.error('Delete feature error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to delete feature' });
  }
};

// Get all assets (kept for backward compatibility)
const getAllAssets = async (req, res) => {
  try {
    const result = await query(
      `SELECT ca.*, cp.full_name as client_name 
       FROM client_assets ca
       JOIN client_profiles cp ON ca.client_id = cp.id
       ORDER BY ca.assigned_date DESC`
    );
    res.json({ success: true, assets: result.rows });
  } catch (error) {
    logger.error('Get all assets error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to fetch assets' });
  }
};

// ============================================================================
// REPORTS
// ============================================================================

const getRevenueReport = async (req, res) => {
  try {
    const { start_date, end_date } = req.query;
    const startDate = start_date || new Date(new Date().setDate(1)).toISOString();
    const endDate = end_date || new Date().toISOString();
    
    const deliveryRevenue = await query(
      `SELECT COALESCE(SUM(total_price), 0) as total, COUNT(*) as count
       FROM delivery_requests
       WHERE status = 'completed' AND completed_at BETWEEN $1 AND $2`,
      [startDate, endDate]
    );
    
    const couponRevenue = await query(
      `SELECT COALESCE(SUM(total_price), 0) as total, COUNT(*) as count
       FROM coupon_book_purchases
       WHERE purchased_at BETWEEN $1 AND $2`,
      [startDate, endDate]
    );
    
    const payments = await query(
      `SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as count
       FROM payments
       WHERE created_at BETWEEN $1 AND $2`,
      [startDate, endDate]
    );
    
    res.json({
      success: true,
      data: {
        period: { start: startDate, end: endDate },
        delivery_revenue: parseFloat(deliveryRevenue.rows[0].total),
        delivery_count: parseInt(deliveryRevenue.rows[0].count),
        coupon_revenue: parseFloat(couponRevenue.rows[0].total),
        coupon_count: parseInt(couponRevenue.rows[0].count),
        payment_collections: parseFloat(payments.rows[0].total),
        payment_count: parseInt(payments.rows[0].count),
        total_revenue: parseFloat(deliveryRevenue.rows[0].total) + parseFloat(couponRevenue.rows[0].total)
      }
    });
  } catch (error) {
    logger.error('Get revenue report error:', error);
    res.status(500).json({ success: false, message: 'Failed to get revenue report' });
  }
};

const getClientReport = async (req, res) => {
  try {
    const total = await query('SELECT COUNT(*) FROM client_profiles');
    const active = await query('SELECT COUNT(*) FROM client_profiles cp JOIN users u ON cp.user_id = u.id WHERE u.is_active = true');
    const withDebt = await query('SELECT COUNT(*) FROM client_profiles WHERE current_debt > 0');
    const totalDebt = await query('SELECT COALESCE(SUM(current_debt), 0) as total FROM client_profiles');
    const bySubscription = await query('SELECT subscription_type, COUNT(*) as count FROM client_profiles GROUP BY subscription_type');
    
    res.json({
      success: true,
      data: {
        total_clients: parseInt(total.rows[0].count),
        active_clients: parseInt(active.rows[0].count),
        clients_with_debt: parseInt(withDebt.rows[0].count),
        total_debt: parseFloat(totalDebt.rows[0].total),
        by_subscription_type: bySubscription.rows
      }
    });
  } catch (error) {
    logger.error('Get client report error:', error);
    res.status(500).json({ success: false, message: 'Failed to get client report' });
  }
};

const getWorkerReport = async (req, res) => {
  try {
    const { start_date, end_date } = req.query;
    const startDate = start_date || new Date(new Date().setDate(1)).toISOString();
    const endDate = end_date || new Date().toISOString();
    
    const workers = await query(
      `SELECT wp.id, wp.full_name, wp.worker_type,
              COUNT(dr.id) as deliveries_completed,
              COALESCE(SUM(dr.gallons_delivered), 0) as total_gallons
       FROM worker_profiles wp
       LEFT JOIN delivery_requests dr ON wp.id = dr.worker_id 
         AND dr.status = 'completed' 
         AND dr.completed_at BETWEEN $1 AND $2
       GROUP BY wp.id, wp.full_name, wp.worker_type
       ORDER BY deliveries_completed DESC`,
      [startDate, endDate]
    );
    
    res.json({
      success: true,
      data: {
        period: { start: startDate, end: endDate },
        workers: workers.rows
      }
    });
  } catch (error) {
    logger.error('Get worker report error:', error);
    res.status(500).json({ success: false, message: 'Failed to get worker report' });
  }
};

const getInventoryReport = async (req, res) => {
  try {
    const workers = await query(
      `SELECT id, full_name, vehicle_capacity, vehicle_current_gallons, is_on_shift
       FROM worker_profiles
       WHERE worker_type = 'delivery_worker'
       ORDER BY full_name`
    );
    
    const couponStock = await query(
      `SELECT size, available_stock, is_active
       FROM coupon_sizes
       ORDER BY size`
    );
    
    const totalCapacity = await query(
      'SELECT COALESCE(SUM(vehicle_capacity), 0) as total FROM worker_profiles WHERE worker_type = \'delivery_worker\''
    );
    
    const totalCurrent = await query(
      'SELECT COALESCE(SUM(vehicle_current_gallons), 0) as total FROM worker_profiles WHERE worker_type = \'delivery_worker\''
    );
    
    res.json({
      success: true,
      data: {
        vehicle_inventory: {
          total_capacity: parseInt(totalCapacity.rows[0].total),
          current_gallons: parseInt(totalCurrent.rows[0].total),
          available_gallons: parseInt(totalCapacity.rows[0].total) - parseInt(totalCurrent.rows[0].total),
          workers: workers.rows
        },
        coupon_stock: couponStock.rows
      }
    });
  } catch (error) {
    logger.error('Get inventory report error:', error);
    res.status(500).json({ success: false, message: 'Failed to get inventory report' });
  }
};

// ============================================================================
// DISPENSER ASSIGNMENT
// ============================================================================

const assignDispenser = async (req, res) => {
  try {
    const { dispenser_id, client_id } = req.body;
    
    await query(
      `UPDATE dispensers 
       SET current_client_id = $1, 
           status = 'used', 
           installation_date = CURRENT_DATE,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND status IN ('new', 'available')`,
      [client_id, dispenser_id]
    );
    
    res.json({ success: true, message: 'Dispenser assigned successfully' });
  } catch (error) {
    logger.error('Assign dispenser error:', error);
    res.status(500).json({ success: false, message: 'Failed to assign dispenser' });
  }
};

const unassignDispenser = async (req, res) => {
  try {
    const { dispenser_id } = req.body;
    
    await query(
      `UPDATE dispensers 
       SET current_client_id = NULL, 
           status = 'available',
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [dispenser_id]
    );
    
    res.json({ success: true, message: 'Dispenser unassigned successfully' });
  } catch (error) {
    logger.error('Unassign dispenser error:', error);
    res.status(500).json({ success: false, message: 'Failed to unassign dispenser' });
  }
};

// ============================================================================
// CLIENT MANAGEMENT
// ============================================================================

// Get all clients
const getAllClients = async (req, res) => {
  try {
    const result = await query(
      `SELECT id, full_name FROM client_profiles ORDER BY full_name`
    );
    res.json({ success: true, clients: result.rows });
  } catch (error) {
    logger.error('Get clients error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to fetch clients' });
  }
};

// Get client assets
const getClientAssets = async (req, res) => {
  try {
    const { clientId } = req.params;
    const result = await query(
      `SELECT * FROM client_assets WHERE client_id = $1 ORDER BY assigned_date DESC`,
      [clientId]
    );
    res.json({ success: true, assets: result.rows });
  } catch (error) {
    logger.error('Get client assets error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to fetch assets' });
  }
};

// Create client asset
const createClientAsset = async (req, res) => {
  try {
    const { clientId } = req.params;
    const { asset_type, quantity } = req.body;
    await query(
      `INSERT INTO client_assets (client_id, asset_type, quantity, assigned_date) 
       VALUES ($1, $2, $3, CURRENT_DATE)`,
      [clientId, asset_type, quantity || 1]
    );
    res.json({ success: true, message: 'Asset created' });
  } catch (error) {
    logger.error('Create asset error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to create asset' });
  }
};

// Update client asset
const updateClientAsset = async (req, res) => {
  try {
    const { assetId } = req.params;
    const { asset_type, quantity } = req.body;
    await query(
      `UPDATE client_assets SET asset_type = $1, quantity = $2 WHERE id = $3`,
      [asset_type, quantity, assetId]
    );
    res.json({ success: true, message: 'Asset updated' });
  } catch (error) {
    logger.error('Update asset error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to update asset' });
  }
};

// Delete client asset
const deleteClientAsset = async (req, res) => {
  try {
    const { assetId } = req.params;
    await query(`DELETE FROM client_assets WHERE id = $1`, [assetId]);
    res.json({ success: true, message: 'Asset deleted' });
  } catch (error) {
    logger.error('Delete asset error:', error);
    res.status(getStatusCode(error)).json({ success: false, message: 'Failed to delete asset' });
  }
};

/**
 * POST /api/v1/admin/requests/batch-assign
 * Bulk assign workers to multiple delivery requests
 */
const batchAssignWorkersToRequests = async (req, res) => {
  try {
    const { request_ids, worker_id } = req.body;

    if (!Array.isArray(request_ids) || request_ids.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'request_ids must be a non-empty array'
      });
    }

    // Check if worker exists
    const workerCheck = await query(
      'SELECT id FROM worker_profiles WHERE id = $1',
      [worker_id]
    );

    if (workerCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found'
      });
    }

    const results = await transaction(async (client) => {
      const assignmentResults = [];

      for (const requestId of request_ids) {
        // Check request status
        const requestCheck = await client.query(
          'SELECT id, status FROM delivery_requests WHERE id = $1 FOR UPDATE',
          [requestId]
        );

        if (requestCheck.rows.length === 0 || requestCheck.rows[0].status !== 'pending') {
          continue; // Skip already assigned or missing requests
        }

        // Assign worker
        await client.query(
          `UPDATE delivery_requests 
           SET assigned_worker_id = $1, status = 'in_progress', updated_at = CURRENT_TIMESTAMP 
           WHERE id = $2`,
          [worker_id, requestId]
        );

        // Notify Worker
        const workerUser = await client.query('SELECT u.id as user_id, u.preferred_language FROM worker_profiles wp JOIN users u ON wp.user_id = u.id WHERE wp.id = $1', [worker_id]);
        const workerLang = workerUser.rows[0].preferred_language || 'en';
        await notificationService.createNotification({
          userId: workerUser.rows[0].user_id,
          title: t(workerLang, 'new_task_assigned_title'),
          message: t(workerLang, 'new_task_assigned_body'),
          type: 'worker_assignment',
          referenceId: requestId,
          referenceType: 'delivery_request',
          dbClient: client,
          sendPush: true
        });

        assignmentResults.push(requestId);
      }

      return assignmentResults;
    });

    logger.info('Batch worker assignment completed:', { assigned_count: results.length, worker_id, admin: req.user.id });

    res.json({
      success: true,
      message: `Successfully assigned ${results.length} requests`,
      data: { assigned_ids: results }
    });
  } catch (error) {
    logger.error('Batch assign workers error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to complete batch assignment'
    });
  }
};

/**
 * DELETE /api/v1/admin/requests/:id
 * Permanently delete a delivery request
 */
const deleteRequest = async (req, res) => {
  try {
    const { id } = req.params;

    await query(`DELETE FROM delivery_requests WHERE id = $1`, [id]);

    logger.info('Request deleted by admin:', { request_id: id, admin: req.user.id });

    res.json({
      success: true,
      message: 'Request deleted successfully'
    });
  } catch (error) {
    logger.error('Delete request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete request'
    });
  }
};

/**
 * POST /api/v1/admin/requests/:id/cancel
 * Cancel a delivery request (soft delete)
 */
const cancelRequest = async (req, res) => {
  try {
    const { id } = req.params;

    await query(
      `UPDATE delivery_requests SET status = 'cancelled' WHERE id = $1`,
      [id]
    );

    logger.info('Request cancelled by admin:', { request_id: id, admin: req.user.id });

    res.json({
      success: true,
      message: 'Request cancelled successfully'
    });
  } catch (error) {
    logger.error('Cancel request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel request'
    });
  }
};

module.exports = {
  getDashboard,
  getAllRequests,
  assignWorkerToRequest,
  batchAssignWorkersToRequests,
  updateRequestStatus,
  deleteDeliveryRequest,
  getAllDeliveries,
  updateDeliveryStatus,
  assignWorkerToDelivery,
  unassignWorkerFromDelivery,
  deleteDelivery,
  createQuickDelivery,
  updateDelivery,
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  toggleUserActive,
  deleteUser,
  updateWorkerAdvance,
  getAnalyticsOverview,
  createStation,
  updateStation,
  deleteStation,
  getScheduledDeliveries,
  createScheduledDelivery,
  updateScheduledDelivery,
  deleteScheduledDelivery,
  getAllExpenses,
  updateExpenseStatus,
  updateExpense,
  approveExpense,
  rejectExpense,
  getRevenueReport,
  getClientReport,
  getWorkerReport,
  getInventoryReport,
  assignDispenser,
  unassignDispenser,
  getDispensers,
  createDispenser,
  updateDispenser,
  deleteDispenser,
  getDispenserTypes,
  createDispenserType,
  updateDispenserType,
  deleteDispenserType,
  getDispenserFeatures,
  createDispenserFeature,
  updateDispenserFeature,
  deleteDispenserFeature,
  getAllAssets,
  getAllClients,
  getClientAssets,
  createClientAsset,
  updateClientAsset,
  getAllCouponBookRequests,
  assignCouponBookWorker,
  unassignWorkerFromCouponBookRequest,
  updateCouponBookRequest,
  deleteCouponBookRequest,
  unassignWorkerFromRequest,
  updateRequest,
  deleteClientAsset,
  getCouponSizes,
  createCouponSize,
  updateCouponSize,
  deleteRequest,
  cancelRequest
};
