// src/routes/admin.routes.js
// Admin dashboard and management routes

const express = require('express');
const { body, query, param } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const adminController = require('../controllers/admin.controller');

const router = express.Router();

// All routes require authentication and admin/owner role
router.use(authenticateToken);
router.use(authorizeRoles('administrator', 'owner'));

// ============================================================================
// VALIDATION RULES
// ============================================================================

const createUserValidation = [
  body('username')
    .trim()
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be 3-50 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores'),
  body('email')
    .optional({ nullable: true, checkFalsy: true })
    .isEmail()
    .withMessage('Invalid email format'),
  body('phone_number')
    .optional({ nullable: true, checkFalsy: true })
    .matches(/^\+?\d{7,15}$/)
    .withMessage('Phone number must be 7-15 digits'),
  body('password')
    .isLength({ min: 4 })
    .withMessage('Password must be at least 4 characters'),
  body('role')
    .custom((value) => {
      const roles = Array.isArray(value) ? value : [value];
      if (roles.length === 0) return false;
      const validRoles = ['client', 'delivery_worker', 'onsite_worker', 'administrator', 'owner'];
      return roles.every(role => validRoles.includes(role));
    })
    .withMessage('Invalid role(s) provided'),
  body('full_name')
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Full name must be 2-255 characters'),
  body('address')
    .custom((value, { req }) => {
      const roles = Array.isArray(req.body.role) ? req.body.role : [req.body.role];
      if (roles.includes('client')) {
        if (!value || value.trim().length < 5) {
          throw new Error('Address is required for clients and must be at least 5 characters');
        }
      }
      return true;
    })
    .trim(),
  body('latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  body('subscription_type')
    .optional()
    .isIn(['coupon_book', 'cash'])
    .withMessage('Invalid subscription type'),
  body('worker_type')
    .optional()
    .isIn(['delivery', 'onsite', 'social_media'])
    .withMessage('Invalid worker type')
];

const updateUserValidation = [
  body('username')
    .optional()
    .trim()
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be 3-50 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores'),
  body('email')
    .optional({ nullable: true, checkFalsy: true })
    .isEmail()
    .withMessage('Invalid email format'),
  body('phone_number')
    .optional({ nullable: true, checkFalsy: true })
    .matches(/^\+?\d{7,15}$/)
    .withMessage('Phone number must be 7-15 digits'),
  body('password')
    .optional()
    .isLength({ min: 4 })
    .withMessage('Password must be at least 4 characters'),
  body('role')
    .optional()
    .custom((value) => {
      const roles = Array.isArray(value) ? value : [value];
      if (roles.length === 0) return false;
      const validRoles = ['client', 'delivery_worker', 'onsite_worker', 'administrator', 'owner'];
      return roles.every(role => validRoles.includes(role));
    })
    .withMessage('Invalid role(s) provided'),
  body('full_name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage('Full name must be 2-255 characters'),
  body('address')
    .optional()
    .trim(),
  body('latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  body('subscription_type')
    .optional()
    .isIn(['coupon_book', 'cash'])
    .withMessage('Invalid subscription type'),
  body('worker_type')
    .optional()
    .isIn(['delivery', 'onsite', 'social_media'])
    .withMessage('Invalid worker type')
];

const assignWorkerValidation = [
  param('id').isInt().withMessage('Request ID must be a number'),
  body('worker_id').isInt().withMessage('Worker ID must be a number')
];

const updateStatusValidation = [
  param('id').isInt().withMessage('Request ID must be a number'),
  body('status').isIn(['pending', 'in_progress', 'completed', 'cancelled']).withMessage('Invalid status')
];

const listQueryValidation = [
  query('limit')
    .optional()
    .isInt({ min: 1, max: 10000 })
    .withMessage('Limit must be between 1 and 10000'),
  query('offset')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Offset must be 0 or greater')
];

const analyticsQueryValidation = [
  query('start_date')
    .optional()
    .isISO8601()
    .withMessage('Start date must be valid ISO 8601 date'),
  query('end_date')
    .optional()
    .isISO8601()
    .withMessage('End date must be valid ISO 8601 date')
];

const createScheduleValidation = [
  body('client_id').isInt().withMessage('Client ID must be a number'),
  body('worker_id').optional({ nullable: true }).isInt().withMessage('Worker ID must be a number'),
  body('gallons').isInt({ min: 1 }).withMessage('Gallons must be a positive number'),
  body('schedule_type').isIn(['daily', 'weekly', 'biweekly', 'monthly']).withMessage('Invalid schedule type'),
  body('schedule_time').matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/).withMessage('Time must be in HH:MM format'),
  body('frequency_per_week')
    .optional({ nullable: true })
    .isInt({ min: 1, max: 7 })
    .withMessage('Frequency per week must be between 1 and 7'),
  body('frequency_per_month')
    .optional({ nullable: true })
    .isInt({ min: 1, max: 31 })
    .withMessage('Frequency per month must be between 1 and 31'),
  body('schedule_days')
    .optional()
    .isArray()
    .withMessage('Schedule days must be an array')
    .custom((value, { req }) => {
      if (['weekly', 'biweekly'].includes(req.body.schedule_type)) {
        if (!value || value.length === 0) {
          throw new Error('Schedule days are required for weekly/biweekly schedules');
        }
        if (!value.every(day => Number.isInteger(day) && day >= 0 && day <= 6)) {
           throw new Error('Schedule days must be integers between 0 (Sunday) and 6 (Saturday)');
        }
      }
      return true;
    }),
  body('start_date').isISO8601().withMessage('Start date must be a valid date'),
  body('end_date')
    .optional({ nullable: true })
    .isISO8601()
    .withMessage('End date must be a valid date')
    .custom((value, { req }) => {
      if (value && req.body.start_date && new Date(value) < new Date(req.body.start_date)) {
        throw new Error('End date must be after start date');
      }
      return true;
    }),
  body('notes').optional().isString()
];

const userIdValidation = [
  param('id').isInt().withMessage('User ID must be a number')
];

// ============================================================================
// DASHBOARD ROUTES
// ============================================================================

/**
 * GET /api/v1/admin/dashboard
 * Get comprehensive dashboard overview with key metrics
 */
router.get('/dashboard', adminController.getDashboard);

/**
 * GET /api/v1/admin/analytics/overview
 * Get business analytics and statistics
 * Query params: start_date, end_date (optional, defaults to last 30 days)
 */
router.get(
  '/analytics/overview',
  analyticsQueryValidation,
  validate,
  adminController.getAnalyticsOverview
);

/**
 * POST /api/v1/admin/analytics/pay-debt
 * Pay all company debt to workers (unpaid + worker_pocket expenses)
 */
router.post('/analytics/pay-debt', adminController.payCompanyDebt);

// ============================================================================
// REQUEST MANAGEMENT
// ============================================================================

/**
 * GET /api/v1/admin/requests
 * Get all delivery requests with filtering
 * Query params: status, priority, limit, offset
 */
router.get(
  '/requests',
  listQueryValidation,
  validate,
  adminController.getAllRequests
);

/**
 * POST /api/v1/admin/requests/:id/assign
 * Assign a worker to a delivery request
 */
router.post(
  '/requests/:id/assign',
  assignWorkerValidation,
  validate,
  adminController.assignWorkerToRequest
);

/**
 * PATCH /api/v1/admin/requests/:id/status
 * Update status of a delivery request
 */
router.patch(
  '/requests/:id/status',
  updateStatusValidation,
  validate,
  adminController.updateRequestStatus
);

/**
 * DELETE /api/v1/admin/requests/:id
 * Delete a delivery request
 */
router.delete(
  '/requests/:id',
  userIdValidation,
  validate,
  adminController.deleteDeliveryRequest
);

/**
 * GET /api/v1/admin/coupon-book-requests
 * Get all coupon book requests
 */
router.get('/coupon-book-requests', adminController.getAllCouponBookRequests);

/**
 * PATCH /api/v1/admin/coupon-book-requests/:id/status
 * Update status of a coupon book request
 */
router.patch(
  '/coupon-book-requests/:id/status',
  [
    param('id').isInt().withMessage('Request ID must be a number'),
    body('status').isIn(['pending', 'approved', 'delivered', 'cancelled']).withMessage('Invalid status')
  ],
  validate,
  adminController.updateCouponBookRequestStatus
);

/**
 * DELETE /api/v1/admin/coupon-book-requests/:id
 * Delete a coupon book request
 */
router.delete(
  '/coupon-book-requests/:id',
  [param('id').isInt().withMessage('Request ID must be a number')],
  validate,
  adminController.deleteCouponBookRequest
);

/**
 * GET /api/v1/admin/coupon-sizes
 * Get all coupon sizes for management
 */
router.get('/coupon-sizes', adminController.getCouponSizes);

/**
 * PATCH /api/v1/admin/coupon-sizes/:id
 * Update coupon size price and bonus
 */
router.patch(
  '/coupon-sizes/:id',
  [
    param('id').isInt().withMessage('Size ID must be a number'),
    body('price_per_page').optional().isFloat({ min: 0 }).withMessage('Price must be a positive number'),
    body('bonus_gallons').optional().isInt({ min: 0 }).withMessage('Bonus must be a non-negative integer'),
    body('expiry_days').optional().isInt({ min: 1 }).withMessage('Expiry days must be a positive integer')
  ],
  validate,
  adminController.updateCouponSize
);

// ============================================================================
// DELIVERY MANAGEMENT
// ============================================================================

/**
 * GET /api/v1/admin/deliveries
 * Get all deliveries with filtering
 * Query params: status, worker_id, date, limit, offset
 */
router.get(
  '/deliveries',
  listQueryValidation,
  validate,
  adminController.getAllDeliveries
);

/**
 * PATCH /api/v1/admin/deliveries/:id/status
 * Update status of a delivery
 */
router.patch(
  '/deliveries/:id/status',
  updateStatusValidation,
  validate,
  adminController.updateDeliveryStatus
);

/**
 * POST /api/v1/admin/deliveries/:id/assign
 * Assign a worker to a delivery
 */
router.post(
  '/deliveries/:id/assign',
  assignWorkerValidation,
  validate,
  adminController.assignWorkerToDelivery
);

/**
 * DELETE /api/v1/admin/deliveries/:id
 * Delete a delivery
 */
router.delete('/deliveries/:id', adminController.deleteDelivery);

/**
 * PATCH /api/v1/admin/deliveries/:id
 * Update a delivery
 */
router.patch('/deliveries/:id', adminController.updateDelivery);

/**
 * POST /api/v1/admin/deliveries/quick
 * Create a quick delivery without a request
 */
const quickDeliveryValidation = [
  body('client_id').isInt().withMessage('Client ID is required'),
  body('worker_id').isInt().withMessage('Worker ID is required'),
  body('gallons_delivered').isInt({ min: 0, max: 500 }).withMessage('Gallons delivered must be between 0 and 500'),
  body('empty_gallons_returned').optional().isInt({ min: 0, max: 500 }).withMessage('Empty gallons must be between 0 and 500'),
];

router.post('/deliveries/quick', quickDeliveryValidation, validate, adminController.createQuickDelivery);

// ============================================================================
// USER MANAGEMENT
// ============================================================================

/**
 * GET /api/v1/admin/users
 * Get all users with filtering
 * Query params: role, is_active, search, limit, offset
 */
router.get(
  '/users',
  listQueryValidation,
  validate,
  adminController.getAllUsers
);

/**
 * GET /api/v1/admin/users/:id
 * Get detailed user info
 */
router.get(
  '/users/:id',
  userIdValidation,
  validate,
  adminController.getUserById
);

/**
 * POST /api/v1/admin/users
 * Create a new user (client or worker)
 */
router.post(
  '/users',
  createUserValidation,
  validate,
  adminController.createUser
);

/**
 * PATCH /api/v1/admin/users/:id
 * Update user information
 */
router.patch(
  '/users/:id',
  userIdValidation,
  updateUserValidation,
  validate,
  adminController.updateUser
);

/**
 * PUT /api/v1/admin/users/:id/toggle-active
 * Activate or deactivate a user
 */
router.put(
  '/users/:id/toggle-active',
  userIdValidation,
  validate,
  adminController.toggleUserActive
);

/**
 * DELETE /api/v1/admin/users/:id
 * Delete a user permanently
 */
router.delete(
  '/users/:id',
  userIdValidation,
  validate,
  adminController.deleteUser
);

/**
 * POST /api/v1/admin/stations
 * Create a new filling station
 */
router.post('/stations', adminController.createStation);

/**
 * PUT /api/v1/admin/stations/:id
 * Update station name and address
 */
router.put('/stations/:id', adminController.updateStation);

/**
 * DELETE /api/v1/admin/stations/:id
 * Delete a filling station
 */
router.delete('/stations/:id', adminController.deleteStation);

/**
 * GET /api/v1/admin/schedules
 * Get all scheduled deliveries
 */
router.get('/schedules', adminController.getScheduledDeliveries);

/**
 * POST /api/v1/admin/schedules
 * Create a new scheduled delivery
 */
router.post(
  '/schedules',
  createScheduleValidation,
  validate,
  adminController.createScheduledDelivery
);

/**
 * PUT /api/v1/admin/schedules/:id
 * Update a scheduled delivery
 */
router.put(
  '/schedules/:id',
  createScheduleValidation,
  validate,
  adminController.updateScheduledDelivery
);

/**
 * DELETE /api/v1/admin/schedules/:id
 * Delete a scheduled delivery
 */
router.delete('/schedules/:id', adminController.deleteScheduledDelivery);

/**
 * PATCH /api/v1/admin/users/:id/advance
 * Update worker salary advance
 */
router.patch(
  '/users/:id/advance',
  [
    param('id').isInt().withMessage('User ID must be a number'),
    body('amount').isFloat().withMessage('Amount must be a number')
  ],
  validate,
  adminController.updateWorkerAdvance
);

/**
 * GET /api/v1/admin/expenses
 * Get all worker expenses
 */
router.get('/expenses', adminController.getAllExpenses);

/**
 * PATCH /api/v1/admin/expenses/:id/status
 * Update expense payment status
 */
router.patch(
  '/expenses/:id/status',
  [
    param('id').isInt().withMessage('Expense ID must be a number'),
    body('payment_status').isIn(['paid', 'unpaid', 'pending']).withMessage('Invalid payment status')
  ],
  validate,
  adminController.updateExpenseStatus
);

/**
 * PUT /api/v1/admin/expenses/:id
 * Update expense details
 */
router.put(
  '/expenses/:id',
  [
    param('id').isInt().withMessage('Expense ID must be a number'),
    body('amount').isFloat().withMessage('Amount must be a number'),
    body('payment_method').isIn(['worker_pocket', 'company_pocket', 'unpaid']).withMessage('Invalid payment method'),
    body('payment_status').isIn(['paid', 'unpaid', 'pending']).withMessage('Invalid payment status')
  ],
  validate,
  adminController.updateExpense
);

// Dispensers
router.get('/dispensers', adminController.getDispensers);
router.post('/dispensers', adminController.createDispenser);
router.put('/dispensers/:id', adminController.updateDispenser);
router.delete('/dispensers/:id', adminController.deleteDispenser);

// Dispenser Types & Features
router.get('/dispenser-types', adminController.getDispenserTypes);
router.post('/dispenser-types', adminController.createDispenserType);
router.put('/dispenser-types/:id', adminController.updateDispenserType);
router.delete('/dispenser-types/:id', adminController.deleteDispenserType);

router.get('/dispenser-features', adminController.getDispenserFeatures);
router.post('/dispenser-features', adminController.createDispenserFeature);
router.put('/dispenser-features/:id', adminController.updateDispenserFeature);
router.delete('/dispenser-features/:id', adminController.deleteDispenserFeature);

// Client Assets
router.get('/clients', adminController.getAllClients);
router.get('/clients/:clientId/assets', adminController.getClientAssets);
router.post('/clients/:clientId/assets', adminController.createClientAsset);
router.put('/assets/:assetId', adminController.updateClientAsset);
router.delete('/assets/:assetId', adminController.deleteClientAsset);

// Revenue Analytics
const revenueController = require('../controllers/revenue.controller');
router.get('/revenues', revenueController.getRevenueData);

module.exports = router;
