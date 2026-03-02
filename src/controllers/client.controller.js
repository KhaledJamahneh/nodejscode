// src/controllers/client.controller.js
// Client profile management: view, update profile and subscription info

const { query, transaction } = require('../config/database');
const logger = require('../utils/logger');
const { getStatusCode } = require('../middleware/error-handler.middleware');

/**
 * GET /api/v1/clients/profile
 * Get complete client profile information
 */
const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT 
        u.id as user_id,
        u.username,
        u.email,
        u.phone_number,
        u.last_login,
        u.role,
        cp.id as profile_id,
        cp.full_name,
        cp.address,
        cp.subscription_type,
        cp.subscription_start_date,
        cp.subscription_end_date,
        cp.remaining_coupons,
        cp.monthly_usage_gallons,
        cp.current_debt,
        u.preferred_language,
        cp.proximity_notifications_enabled,
        cp.home_latitude,
        cp.home_longitude,
        cp.created_at,
        cp.updated_at
      FROM users u
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      WHERE u.id = $1 AND 'client' = ANY(u.role)`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    const profile = result.rows[0];

    // Calculate subscription status
    let subscriptionStatus = 'active';
    const now = new Date();
    
    if (profile.subscription_end_date && new Date(profile.subscription_end_date) < now) {
      subscriptionStatus = 'expired';
    } else if (profile.subscription_type === 'coupon_book' && profile.remaining_coupons <= 0) {
      subscriptionStatus = 'expired';
    } else if (profile.subscription_end_date) {
      const expiryDate = new Date(profile.subscription_end_date);
      const sevenDaysFromNow = new Date();
      sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
      
      if (expiryDate < sevenDaysFromNow) {
        subscriptionStatus = 'expiring_soon';
      }
    }

    res.json({
      success: true,
      data: {
        ...profile,
        subscription_status: subscriptionStatus
      }
    });
  } catch (error) {
    logger.error('Get profile error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get profile'
    });
  }
};

/**
 * PUT /api/v1/clients/profile
 * Update client profile information
 */
const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      full_name,
      address,
      home_latitude,
      home_longitude,
      email,
      phone_number,
      preferred_language,
      proximity_notifications_enabled
    } = req.body;

    await transaction(async (client) => {
      // Update users table if email or phone is provided
      if (email || phone_number) {
        const updateFields = [];
        const updateValues = [];
        let paramCounter = 1;

        if (email) {
          updateFields.push(`email = $${paramCounter++}`);
          updateValues.push(email);
        }
        if (phone_number) {
          updateFields.push(`phone_number = $${paramCounter++}`);
          updateValues.push(phone_number);
        }

        updateValues.push(userId);

        await client.query(
          `UPDATE users SET ${updateFields.join(', ')} WHERE id = $${paramCounter}`,
          updateValues
        );
      }

      // Update client_profiles table
      const profileUpdateFields = [];
      const profileUpdateValues = [];
      let paramCounter = 1;

      if (full_name) {
        profileUpdateFields.push(`full_name = $${paramCounter++}`);
        profileUpdateValues.push(full_name);
      }
      if (address) {
        profileUpdateFields.push(`address = $${paramCounter++}`);
        profileUpdateValues.push(address);
      }
      if (home_latitude !== undefined) {
        profileUpdateFields.push(`home_latitude = $${paramCounter++}`);
        profileUpdateValues.push(home_latitude);
      }
      if (home_longitude !== undefined) {
        profileUpdateFields.push(`home_longitude = $${paramCounter++}`);
        profileUpdateValues.push(home_longitude);
      }
      if (preferred_language) {
        profileUpdateFields.push(`preferred_language = $${paramCounter++}`);
        profileUpdateValues.push(preferred_language);
      }
      if (proximity_notifications_enabled !== undefined) {
        profileUpdateFields.push(`proximity_notifications_enabled = $${paramCounter++}`);
        profileUpdateValues.push(proximity_notifications_enabled);
      }

      if (profileUpdateFields.length > 0) {
        profileUpdateValues.push(userId);
        await client.query(
          `UPDATE client_profiles 
           SET ${profileUpdateFields.join(', ')} 
           WHERE user_id = $${paramCounter}`,
          profileUpdateValues
        );
      }
    });

    logger.info('Profile updated:', { userId });

    // Get updated profile
    const updatedProfile = await query(
      `SELECT 
        u.id as user_id,
        u.username,
        u.email,
        u.phone_number,
        cp.full_name,
        cp.address,
        cp.home_latitude,
        cp.home_longitude,
        u.preferred_language,
        cp.proximity_notifications_enabled
      FROM users u
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      WHERE u.id = $1`,
      [userId]
    );

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedProfile.rows[0]
    });
  } catch (error) {
    logger.error('Update profile error:', error);
    
    // Handle unique constraint violations
    if (error.code === '23505') {
      return res.status(400).json({
        success: false,
        message: 'Phone number or email already in use'
      });
    }

    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to update profile'
    });
  }
};

/**
 * GET /api/v1/clients/subscription
 * Get detailed subscription information
 */
const getSubscription = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT 
        cp.subscription_type,
        cp.subscription_start_date,
        cp.subscription_end_date,
        cp.remaining_coupons,
        cp.monthly_usage_gallons,
        cp.current_debt
      FROM client_profiles cp
      WHERE cp.user_id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Subscription information not found'
      });
    }

    const subData = result.rows[0];
    let subscriptionStatus = 'active';
    const now = new Date();
    
    if (subData.subscription_end_date && new Date(subData.subscription_end_date) < now) {
      subscriptionStatus = 'expired';
    } else if (subData.subscription_type === 'coupon_book' && subData.remaining_coupons <= 0) {
      subscriptionStatus = 'expired';
    } else if (subData.subscription_end_date) {
      const expiryDate = new Date(subData.subscription_end_date);
      const sevenDaysFromNow = new Date();
      sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);
      
      if (expiryDate < sevenDaysFromNow) {
        subscriptionStatus = 'expiring_soon';
      }
    }

    res.json({
      success: true,
      data: {
        ...subData,
        status: subscriptionStatus
      }
    });
  } catch (error) {
    logger.error('Get subscription error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get subscription information'
    });
  }
};

/**
 * GET /api/v1/clients/usage
 * Get usage history for the client
 */
const getUsageHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const { months = 6 } = req.query; // Default to last 6 months

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

    // Get monthly usage summary
    const usageResult = await query(
      `SELECT 
        DATE_TRUNC('month', delivery_date) as month,
        COUNT(*) as delivery_count,
        SUM(gallons_delivered) as total_gallons,
        AVG(gallons_delivered) as avg_gallons_per_delivery
      FROM deliveries
      WHERE client_id = $1 
        AND status = 'completed'
        AND delivery_date >= CURRENT_DATE - INTERVAL '${parseInt(months)} months'
      GROUP BY DATE_TRUNC('month', delivery_date)
      ORDER BY month DESC`,
      [clientId]
    );

    // Get recent deliveries
    const recentDeliveries = await query(
      `SELECT 
        d.id,
        d.delivery_date,
        d.actual_delivery_time,
        d.gallons_delivered,
        d.status,
        w.full_name as worker_name
      FROM deliveries d
      LEFT JOIN worker_profiles w ON d.worker_id = w.id
      WHERE d.client_id = $1
      ORDER BY d.delivery_date DESC, d.actual_delivery_time DESC
      LIMIT 10`,
      [clientId]
    );

    // Get overall statistics
    const statsResult = await query(
      `SELECT 
        COUNT(*) as total_deliveries,
        SUM(gallons_delivered) as total_gallons,
        AVG(gallons_delivered) as avg_gallons,
        MAX(delivery_date) as last_delivery_date
      FROM deliveries
      WHERE client_id = $1 AND status = 'completed'`,
      [clientId]
    );

    res.json({
      success: true,
      data: {
        monthly_usage: usageResult.rows,
        recent_deliveries: recentDeliveries.rows,
        statistics: statsResult.rows[0]
      }
    });
  } catch (error) {
    logger.error('Get usage history error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get usage history'
    });
  }
};

/**
 * GET /api/v1/clients/assets
 * Get list of company assets in client's possession
 */
const getAssets = async (req, res) => {
  try {
    const userId = req.user.id;

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

    // Get assets
    const result = await query(
      `SELECT 
        ca.id,
        ca.asset_type,
        ca.quantity,
        ca.assigned_date,
        ca.returned_date,
        d.serial_number,
        d.dispenser_type,
        d.status as dispenser_status,
        d.image_url
      FROM client_assets ca
      LEFT JOIN dispensers d ON ca.dispenser_id = d.id
      WHERE ca.client_id = $1 AND ca.returned_date IS NULL
      ORDER BY ca.assigned_date DESC`,
      [clientId]
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    logger.error('Get assets error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get assets'
    });
  }
};

/**
 * GET /api/v1/clients/debt
 * Get detailed debt information
 */
const getDebtInfo = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get client profile ID and debt
    const clientResult = await query(
      `SELECT 
        cp.id,
        cp.current_debt,
        cp.subscription_type
      FROM client_profiles cp
      WHERE cp.user_id = $1`,
      [userId]
    );

    if (clientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    const clientId = clientResult.rows[0].id;
    const currentDebt = clientResult.rows[0].current_debt;

    // Get payment history
    const paymentsResult = await query(
      `SELECT 
        id,
        amount,
        payment_method,
        payment_status,
        payment_date,
        description
      FROM payments
      WHERE payer_id = $1
      ORDER BY payment_date DESC
      LIMIT 10`,
      [userId]
    );

    res.json({
      success: true,
      data: {
        current_debt: parseFloat(currentDebt),
        subscription_type: clientResult.rows[0].subscription_type,
        recent_payments: paymentsResult.rows
      }
    });
  } catch (error) {
    logger.error('Get debt info error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get debt information'
    });
  }
};

/**
 * PUT /api/v1/clients/location/home
 * Save client's permanent home location
 */
const saveHomeLocation = async (req, res) => {
  try {
    const userId = req.user.id;
    const { home_latitude, home_longitude } = req.body;

    if (home_latitude === undefined || home_longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const result = await query(
      `UPDATE client_profiles 
       SET home_latitude = $1, home_longitude = $2, updated_at = CURRENT_TIMESTAMP 
       WHERE user_id = $3
       RETURNING id`,
      [home_latitude, home_longitude, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client profile not found'
      });
    }

    res.json({
      success: true,
      message: 'Home location saved'
    });
  } catch (error) {
    logger.error('Save home location error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to save home location'
    });
  }
};

/**
 * GET /api/v1/workers/location/delivery/:delivery_id
 * Get assigned worker's live location for a delivery
 */
const getWorkerLocationForDelivery = async (req, res) => {
  try {
    const userId = req.user.id;
    const { delivery_id } = req.params;

    // Security check: client can only see their own delivery's worker
    // Also stale check: updates within last 5 minutes
    const result = await query(
      `SELECT wl.latitude, wl.longitude, wl.updated_at,
              u.full_name AS worker_name
       FROM worker_locations wl
       JOIN deliveries d ON d.id = wl.delivery_id
       JOIN client_profiles cp ON d.client_id = cp.id
       JOIN users u ON u.id = wl.worker_id
       WHERE wl.delivery_id = $1
         AND cp.user_id = $2
         AND wl.updated_at > NOW() - INTERVAL '5 minutes'`,
      [delivery_id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No live location available'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Get worker location error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get worker location'
    });
  }
};

/**
 * GET /api/v1/workers/location/request/:request_id
 * Get assigned worker's live location for a delivery request
 */
const getWorkerLocationForRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { request_id } = req.params;

    const result = await query(
      `SELECT wl.latitude, wl.longitude, wl.updated_at,
              u.full_name AS worker_name
       FROM worker_locations wl
       JOIN delivery_requests dr ON dr.id = $1
       JOIN client_profiles cp ON dr.client_id = cp.id
       JOIN users u ON u.id = wl.worker_id
       WHERE wl.worker_id = dr.assigned_worker_id
         AND cp.user_id = $2
         AND wl.updated_at > NOW() - INTERVAL '5 minutes'`,
      [request_id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No live location available'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    logger.error('Get worker location request error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get worker location'
    });
  }
};

/**
 * GET /api/v1/clients/coupon-sizes
 * Get available coupon book sizes with calculated prices
 */
const getCouponSizes = async (req, res) => {
  try {
    const result = await query(
      `SELECT 
        id,
        size,
        price_per_page,
        bonus_gallons,
        (size * price_per_page) as price,
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
 * POST /api/v1/clients/coupon-book-request
 * Create a coupon book request (physical) or purchase electronic coupons directly
 */
const createCouponBookRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { book_type, coupon_size_id, payment_method = 'cash' } = req.body;

    const resultData = await transaction(async (client) => {
      // 1. Get client profile
      const clientResult = await client.query(
        'SELECT id, remaining_coupons FROM client_profiles WHERE user_id = $1',
        [userId]
      );

      if (clientResult.rows.length === 0) {
        throw new Error('Client profile not found');
      }

      const clientProfileId = clientResult.rows[0].id;

      // 2. Get coupon size and LOCK the row to prevent race conditions
      const sizeResult = await client.query(
        `SELECT size, bonus_gallons, price_per_page, (size * price_per_page) as calculated_total, available_stock 
         FROM coupon_sizes WHERE id = $1 FOR UPDATE`,
        [coupon_size_id]
      );

      if (sizeResult.rows.length === 0) {
        throw new Error('Coupon size not found');
      }

      const { size, bonus_gallons, calculated_total, available_stock } = sizeResult.rows[0];
      const totalGallons = size + (bonus_gallons || 0);

      // 3. Check stock for physical books
      if (book_type === 'physical' && available_stock <= 0) {
        throw new Error('Out of stock for physical coupon books');
      }

      // 4. Handle based on book type
      if (book_type === 'electronic') {
        const currentCoupons = clientResult.rows[0].remaining_coupons || 0;
        const newBalance = currentCoupons + totalGallons;

        // Update client balance
        await client.query(
          'UPDATE client_profiles SET remaining_coupons = $1 WHERE id = $2',
          [newBalance, clientProfileId]
        );

        // Record completed request
        await client.query(
          `INSERT INTO coupon_book_requests (client_id, book_type, coupon_size_id, total_price, status, payment_method)
           VALUES ($1, $2, $3, $4, 'completed', $5)`,
          [clientProfileId, book_type, coupon_size_id, calculated_total, payment_method]
        );

        // Record payment
        await client.query(
          `INSERT INTO payments (payer_id, amount, payment_method, payment_status, payment_date, description)
           VALUES ($1, $2, $3, 'completed', NOW(), $4)`,
          [userId, calculated_total, payment_method, `Electronic coupon purchase - ${totalGallons} gallons`]
        );

        return {
          type: 'electronic',
          message: `${totalGallons} gallons added to your balance`,
          data: { gallons_added: totalGallons, new_balance: newBalance }
        };
      } else {
        // Physical book: Decrease stock and create pending request
        await client.query(
          'UPDATE coupon_sizes SET available_stock = available_stock - 1 WHERE id = $1',
          [coupon_size_id]
        );

        const requestResult = await client.query(
          `INSERT INTO coupon_book_requests (client_id, book_type, coupon_size_id, total_price, status, payment_method)
           VALUES ($1, $2, $3, $4, 'approved', $5) RETURNING *`,
          [clientProfileId, book_type, coupon_size_id, calculated_total, payment_method]
        );

        return {
          type: 'physical',
          message: 'Coupon book request created successfully',
          data: requestResult.rows[0]
        };
      }
    });

    res.status(resultData.type === 'physical' ? 201 : 200).json({
      success: true,
      message: resultData.message,
      data: resultData.data
    });
  } catch (error) {
    logger.error('Create coupon book request error:', error);
    res.status(error.message.includes('not found') ? 404 : (error.message.includes('stock') ? 400 : 500)).json({
      success: false,
      message: error.message || 'Failed to create coupon book request'
    });
  }
};

/**
 * GET /api/v1/clients/coupon-book-requests
 * Get client's coupon book requests
 */
const getCouponBookRequests = async (req, res) => {
  try {
    const userId = req.user.id;

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

    const result = await query(
      `SELECT 
        cbr.id,
        cbr.book_type,
        cbr.total_price,
        cbr.status,
        cbr.created_at,
        cs.size as book_size
      FROM coupon_book_requests cbr
      JOIN coupon_sizes cs ON cbr.coupon_size_id = cs.id
      WHERE cbr.client_id = $1
      ORDER BY cbr.created_at DESC`,
      [clientResult.rows[0].id]
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    logger.error('Get coupon book requests error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to retrieve coupon book requests'
    });
  }
};

/**
 * PATCH /api/v1/clients/coupon-books/:id
 * Update coupon book request (only if pending)
 */
const updateCouponBookRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;
    const { coupon_size_id, book_type } = req.body;

    const result = await transaction(async (client) => {
      // Check if request exists and belongs to user
      const checkResult = await client.query(
        `SELECT cbr.id, cbr.status, cbr.assigned_worker_id, cp.user_id
         FROM coupon_book_requests cbr
         JOIN client_profiles cp ON cbr.client_id = cp.id
         WHERE cbr.id = $1`,
        [requestId]
      );

      if (checkResult.rows.length === 0) {
        throw new Error('Coupon book request not found');
      }

      if (checkResult.rows[0].user_id !== userId) {
        throw new Error('Unauthorized');
      }

      // Can only edit if not assigned to worker yet
      if (checkResult.rows[0].assigned_worker_id) {
        throw new Error('Cannot edit request already assigned to worker');
      }

      if (!['pending', 'approved'].includes(checkResult.rows[0].status)) {
        throw new Error('Can only edit pending or approved requests');
      }

      // Update request
      const updateResult = await client.query(
        `UPDATE coupon_book_requests 
         SET coupon_size_id = $1, book_type = $2, updated_at = NOW()
         WHERE id = $3
         RETURNING *`,
        [coupon_size_id, book_type, requestId]
      );

      return updateResult.rows[0];
    });

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    logger.error('Update coupon book request error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: error.message || 'Failed to update coupon book request'
    });
  }
};

/**
 * DELETE /api/v1/clients/coupon-books/:id
 * Delete/cancel coupon book request (only if pending)
 */
const deleteCouponBookRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const requestId = req.params.id;

    await transaction(async (client) => {
      // Check if request exists and belongs to user
      const checkResult = await client.query(
        `SELECT cbr.id, cbr.status, cbr.assigned_worker_id, cbr.coupon_size_id, cp.user_id
         FROM coupon_book_requests cbr
         JOIN client_profiles cp ON cbr.client_id = cp.id
         WHERE cbr.id = $1`,
        [requestId]
      );

      if (checkResult.rows.length === 0) {
        throw new Error('Coupon book request not found');
      }

      if (checkResult.rows[0].user_id !== userId) {
        throw new Error('Unauthorized');
      }

      const { status, assigned_worker_id, coupon_size_id } = checkResult.rows[0];

      // Can only cancel if not assigned to worker yet
      if (assigned_worker_id) {
        throw new Error('Cannot cancel request already assigned to worker');
      }

      // Can cancel pending or approved requests
      if (!['pending', 'approved'].includes(status)) {
        throw new Error('Can only cancel pending or approved requests');
      }

      // Restore stock if physical book
      await client.query(
        'UPDATE coupon_sizes SET available_stock = available_stock + 1 WHERE id = $1',
        [coupon_size_id]
      );

      // Update status to cancelled
      await client.query(
        'UPDATE coupon_book_requests SET status = $1, updated_at = NOW() WHERE id = $2',
        ['cancelled', requestId]
      );
    });

    res.json({
      success: true,
      message: 'Coupon book request cancelled successfully'
    });
  } catch (error) {
    logger.error('Delete coupon book request error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: error.message || 'Failed to cancel coupon book request'
    });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  getSubscription,
  getUsageHistory,
  getAssets,
  getDebtInfo,
  saveHomeLocation,
  getWorkerLocationForDelivery,
  getWorkerLocationForRequest,
  getCouponSizes,
  createCouponBookRequest,
  getCouponBookRequests,
  updateCouponBookRequest,
  deleteCouponBookRequest
};
