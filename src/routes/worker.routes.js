// src/routes/worker.routes.js
// Worker schedule and delivery management routes

const express = require('express');
const { body, query, param } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const workerController = require('../controllers/worker.controller');
const clientController = require('../controllers/client.controller');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// General worker role requirement for most routes in this file
const workerAuth = authorizeRoles('delivery_worker', 'onsite_worker', 'administrator', 'owner');

// ============================================================================
// VALIDATION RULES
// ============================================================================

const completeDeliveryValidation = [
  param('id').isInt().withMessage('Delivery ID must be a number'),
  body('gallons_delivered')
  .isInt({ min: 1, max: 500 })
  .withMessage('Gallons delivered must be between 1 and 500'),
  body('empty_gallons_returned')
  .optional({ nullable: true })
  .isInt({ min: 0, max: 500 })
  .withMessage('Empty gallons returned must be a positive number'),
  body('delivery_latitude')
  .optional({ nullable: true })
  .isFloat({ min: -90, max: 90 })
  .withMessage('Latitude must be between -90 and 90'),
  body('delivery_longitude')
  .optional({ nullable: true })
  .isFloat({ min: -180, max: 180 })
  .withMessage('Longitude must be between -180 and 180'),
  body('notes')
  .optional({ nullable: true })
  .trim()
  .isLength({ max: 500 })
  .withMessage('Notes must be less than 500 characters'),
  body('photo_url')
  .optional({ nullable: true })
  .trim()
  .custom((value) => {
    if (!value || value === '') return true;
    try {
      new URL(value);
      return true;
    } catch (_) {
      throw new Error('Photo URL must be valid');
    }
  })
];

const scheduleQueryValidation = [
  query('date')
  .optional({ nullable: true })
  .isISO8601()
  .withMessage('Date must be in ISO 8601 format (YYYY-MM-DD)')
];

const vehicleInventoryValidation = [
  body('current_gallons')
  .isInt({ min: 0, max: 1000 })
  .withMessage('Current gallons must be between 0 and 1000')
];

const gpsToggleValidation = [
  body('enabled')
  .isBoolean()
  .withMessage('Enabled must be true or false')
];

const deliveryIdValidation = [
  param('id').isInt().withMessage('Delivery ID must be a number')
];

const completeCouponRequestValidation = [
  param('id').isInt().withMessage('Request ID must be a number'),
  body('delivery_latitude')
  .optional({ nullable: true })
  .isFloat({ min: -90, max: 90 })
  .withMessage('Latitude must be between -90 and 90'),
  body('delivery_longitude')
  .optional({ nullable: true })
  .isFloat({ min: -180, max: 180 })
  .withMessage('Longitude must be between -180 and 180'),
  body('notes')
  .optional({ nullable: true })
  .trim()
  .isLength({ max: 500 })
  .withMessage('Notes must be less than 500 characters')
];

const sessionIdValidation = [
  param('id').isInt().withMessage('Session ID must be a number')
];

const stationStatusValidation = [
  param('id').isInt().withMessage('Station ID must be a number'),
  body('status')
  .isIn(['open', 'temporarilyClosed', 'closedUntilTomorrow', 'closed_temporarily', 'closed_until_tomorrow'])
  .withMessage('Invalid station status')
];

const updateLocationValidation = [
  body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude required'),
  body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude required'),
  body('delivery_id').optional().isInt().withMessage('Delivery ID must be a number')
];

// ============================================================================
// WORKER ROUTES
// ============================================================================

router.get('/profile', workerAuth, workerController.getWorkerProfile);

/**
 * PUT /api/v1/workers/location
 * Update worker's live location
 */
router.put(
  '/location',
  workerAuth,
  updateLocationValidation,
  validate,
  workerController.updateLiveLocation
);

/**
 * GET /api/v1/workers/location/delivery/:delivery_id
 * Get assigned worker's live location for a delivery
 */
router.get(
  '/location/delivery/:delivery_id',
  authorizeRoles('client', 'administrator', 'owner'),
  param('delivery_id').isInt().withMessage('Delivery ID must be a number'),
  validate,
  clientController.getWorkerLocationForDelivery
);

/**
 * GET /api/v1/workers/location/request/:request_id
 * Get assigned worker's live location for a delivery request
 */
router.get(
  '/location/request/:request_id',
  authorizeRoles('client', 'administrator', 'owner'),
  param('request_id').isInt().withMessage('Request ID must be a number'),
  validate,
  clientController.getWorkerLocationForRequest
);

router.get(
  '/schedule/main',
  workerAuth,
  scheduleQueryValidation,
  validate,
  workerController.getMainSchedule
);

router.get('/schedule/secondary', workerAuth, workerController.getSecondaryList);

router.post(
  '/deliveries/:id/start',
  workerAuth,
  deliveryIdValidation,
  validate,
  workerController.startDelivery
);

router.post(
  '/deliveries/:id/accept',
  workerAuth,
  deliveryIdValidation,
  validate,
  workerController.acceptScheduledDelivery
);

router.post(
  '/deliveries/:id/complete',
  workerAuth,
  completeDeliveryValidation,
  validate,
  workerController.completeDelivery
);

router.post(
  '/requests/:id/accept',
  workerAuth,
  deliveryIdValidation,
  validate,
  workerController.acceptRequest
);

router.post(
  '/requests/:id/complete',
  workerAuth,
  completeDeliveryValidation,
  validate,
  workerController.completeRequest
);

router.post(
  '/coupon-requests/:id/accept',
  workerAuth,
  deliveryIdValidation,
  validate,
  workerController.acceptCouponBookRequest
);

router.post(
  '/coupon-requests/:id/complete',
  workerAuth,
  completeCouponRequestValidation,
  validate,
  workerController.completeCouponBookRequest
);

router.put(
  '/vehicle/inventory',
  workerAuth,
  vehicleInventoryValidation,
  validate,
  workerController.updateVehicleInventory
);

router.put(
  '/gps/toggle',
  workerAuth,
  gpsToggleValidation,
  validate,
  workerController.toggleGPSSharing
);

// ============================================================================
// ONSITE WORKER ROUTES (Filling Operations)
// ============================================================================

// Accessible by clients too so they can see station status
router.get(
  '/onsite/stations', 
  authorizeRoles('client', 'delivery_worker', 'onsite_worker', 'administrator', 'owner'),
  workerController.getFillingStations
);

router.put(
  '/onsite/stations/:id',
  workerAuth,
  stationStatusValidation,
  validate,
  workerController.updateFillingStationStatus
);

router.post('/onsite/sessions/start', workerAuth, workerController.startFillingSession);

router.post(
  '/onsite/sessions/:id/complete',
  workerAuth,
  sessionIdValidation,
  validate,
  workerController.completeFillingSession
);

router.get('/onsite/sessions/recent', workerAuth, workerController.getRecentFillingSessions);

router.patch(
  '/onsite/sessions/:id',
  workerAuth,
  sessionIdValidation,
  validate,
  workerController.updateFillingSession
);

router.delete(
  '/onsite/sessions/:id',
  workerAuth,
  sessionIdValidation,
  validate,
  workerController.deleteFillingSession
);

// ============================================================================
// WORKER EXPENSES ROUTES
// ============================================================================

router.get('/expenses', workerAuth, workerController.getExpenses);

router.post(
  '/expenses',
  workerAuth,
  [
    body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be greater than 0'),
    body('payment_method').isIn(['cash', 'card', 'worker_pocket', 'company_pocket', 'unpaid']).withMessage('Invalid payment method'),
    body('payment_status').optional().isIn(['paid', 'unpaid', 'pending']).withMessage('Invalid payment status'),
    body('destination').optional().trim().isLength({ max: 200 }).withMessage('Destination must be less than 200 characters'),
    body('notes').optional().trim().isLength({ max: 500 }).withMessage('Notes must be less than 500 characters')
  ],
  validate,
  workerController.submitExpense
);

/**
 * POST /api/v1/workers/deliveries/quick
 * Create a quick delivery without a request
 */
const quickDeliveryValidation = [
  body('client_id').isInt().withMessage('Client ID is required'),
  body('worker_id').isInt().withMessage('Worker ID is required'),
  body('gallons_delivered').isInt({ min: 0, max: 500 }).withMessage('Gallons delivered must be between 0 and 500'),
  body('empty_gallons_returned').optional().isInt({ min: 0, max: 500 }).withMessage('Empty gallons must be between 0 and 500'),
];

router.post('/deliveries/quick', workerAuth, quickDeliveryValidation, validate, workerController.createQuickDelivery);

router.put(
  '/expenses/:id',
  workerAuth,
  [
    param('id').isInt().withMessage('Expense ID must be a number'),
    body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be greater than 0'),
    body('payment_method').isIn(['cash', 'card', 'worker_pocket', 'company_pocket', 'unpaid']).withMessage('Invalid payment method'),
    body('payment_status').optional().isIn(['paid', 'unpaid', 'pending']).withMessage('Invalid payment status'),
    body('destination').optional().trim().isLength({ max: 200 }).withMessage('Destination must be less than 200 characters'),
    body('notes').optional().trim().isLength({ max: 500 }).withMessage('Notes must be less than 500 characters')
  ],
  validate,
  workerController.updateExpense
);

router.delete(
  '/expenses/:id',
  workerAuth,
  param('id').isInt().withMessage('Expense ID must be a number'),
  validate,
  workerController.deleteExpense
);

module.exports = router;
