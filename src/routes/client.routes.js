// src/routes/client.routes.js
// Client-specific routes: profile, subscriptions, delivery requests

const express = require('express');
const { body, query } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const clientController = require('../controllers/client.controller');

const router = express.Router();

// All client routes require authentication
router.use(authenticateToken);
router.use(authorizeRoles('client', 'administrator', 'owner')); // Allow admin/owner to access client routes

// ============================================================================
// VALIDATION RULES
// ============================================================================

const updateProfileValidation = [
  body('full_name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Full name must be between 2 and 255 characters'),
  body('address')
    .optional()
    .trim()
    .isLength({ min: 5 })
    .withMessage('Address must be at least 5 characters'),
  body('latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Invalid email format'),
  body('phone_number')
    .optional()
    .matches(/^\+?[1-9]\d{1,14}$/)
    .withMessage('Invalid phone number format'),
  body('preferred_language')
    .optional()
    .isIn(['en', 'ar'])
    .withMessage('Language must be en or ar'),
  body('proximity_notifications_enabled')
    .optional()
    .isBoolean()
    .withMessage('Must be true or false')
];

const usageQueryValidation = [
  query('months')
    .optional()
    .isInt({ min: 1, max: 24 })
    .withMessage('Months must be between 1 and 24')
];

// ============================================================================
// ROUTES
// ============================================================================

/**
 * GET /api/v1/clients/profile
 * Get complete client profile information
 */
router.get('/profile', clientController.getProfile);

/**
 * PUT /api/v1/clients/profile
 * Update client profile
 */
router.put('/profile', updateProfileValidation, validate, clientController.updateProfile);

/**
 * GET /api/v1/clients/subscription
 * Get subscription details and status
 */
router.get('/subscription', clientController.getSubscription);

/**
 * GET /api/v1/clients/usage
 * Get usage history and statistics
 * Query params: months (default: 6)
 */
router.get('/usage', usageQueryValidation, validate, clientController.getUsageHistory);

/**
 * GET /api/v1/clients/coupon-sizes
 * Get available coupon book sizes with prices
 */
router.get('/coupon-sizes', clientController.getCouponSizes);

/**
 * POST /api/v1/clients/coupon-book-request
 * Create a coupon book request
 */
router.post('/coupon-book-request', clientController.createCouponBookRequest);

/**
 * GET /api/v1/clients/coupon-book-requests
 * Get client's coupon book requests
 */
router.get('/coupon-book-requests', clientController.getCouponBookRequests);

/**
 * PATCH /api/v1/clients/coupon-books/:id
 * Update a coupon book request (only if pending)
 */
router.patch('/coupon-books/:id', clientController.updateCouponBookRequest);

/**
 * DELETE /api/v1/clients/coupon-books/:id
 * Delete/cancel a coupon book request (only if pending)
 */
router.delete('/coupon-books/:id', clientController.deleteCouponBookRequest);

/**
 * GET /api/v1/clients/payments
 * Get payment history
 */
router.get(
  '/payments',
  [
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('offset').optional().isInt({ min: 0 }).withMessage('Offset must be 0 or greater')
  ],
  validate,
  clientController.getPaymentHistory
);

/**
 * GET /api/v1/clients/assets
 * Get list of company assets (dispensers, bottles) in client's possession
 */
router.get('/assets', clientController.getAssets);

/**
 * GET /api/v1/clients/debt
 * Get detailed debt information and payment history
 */
router.get('/debt', clientController.getDebtInfo);

/**
 * GET /api/v1/clients/deliveries/active
 * Get current active delivery with real-time tracking and ETA
 */
router.get('/deliveries/active', clientController.getActiveDelivery);

/**
 * POST /api/v1/clients/dispensers/request
 * Request a dispenser
 */
router.post(
  '/dispensers/request',
  [
    body('dispenser_type').isIn(['touch', 'manual', 'electric']).withMessage('Invalid dispenser type'),
    body('notes').optional().trim().isLength({ max: 500 }).withMessage('Notes max 500 characters')
  ],
  validate,
  clientController.requestDispenser
);

// ============================================================================
// LOCATION & PROXIMITY ROUTES
// ============================================================================

/**
 * PUT /api/v1/clients/location/home
 * Save client's permanent home location
 */
router.put(
  '/location/home',
  [
    body('home_latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude required'),
    body('home_longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude required')
  ],
  validate,
  clientController.saveHomeLocation
);

module.exports = router;
