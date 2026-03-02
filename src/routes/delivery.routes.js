// src/routes/delivery.routes.js
// Delivery request and history routes

const express = require('express');
const { body, query, param } = require('express-validator');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const deliveryController = require('../controllers/delivery.controller');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// ============================================================================
// VALIDATION RULES
// ============================================================================

const createRequestValidation = [
  body('requested_gallons')
    .isInt({ min: 1, max: 500 })
    .withMessage('Requested gallons must be between 1 and 500'),
  body('priority')
    .optional()
    .isIn(['urgent', 'mid_urgent', 'non_urgent'])
    .withMessage('Priority must be urgent, mid_urgent, or non_urgent'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters')
];

const updateRequestValidation = [
  param('id').isInt().withMessage('Request ID must be a number'),
  body('requested_gallons')
    .optional()
    .isInt({ min: 1, max: 500 })
    .withMessage('Requested gallons must be between 1 and 500'),
  body('priority')
    .optional()
    .isIn(['urgent', 'mid_urgent', 'non_urgent'])
    .withMessage('Priority must be urgent, mid_urgent, or non_urgent'),
  body('notes')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters')
];

const listRequestsValidation = [
  query('status')
    .optional()
    .isIn(['pending', 'in_progress', 'completed', 'cancelled'])
    .withMessage('Invalid status'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  query('offset')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Offset must be 0 or greater')
];

const deliveryHistoryValidation = [
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  query('offset')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Offset must be 0 or greater'),
  query('start_date')
    .optional()
    .isISO8601()
    .withMessage('Start date must be a valid date'),
  query('end_date')
    .optional()
    .isISO8601()
    .withMessage('End date must be a valid date')
];

const requestIdValidation = [
  param('id').isInt().withMessage('Request ID must be a number')
];

// ============================================================================
// CLIENT ROUTES
// ============================================================================

/**
 * POST /api/v1/deliveries/request
 * Create a new delivery request
 * Priority levels: urgent, mid_urgent, non_urgent
 */
router.post(
  '/request',
  authorizeRoles('client'),
  createRequestValidation,
  validate,
  deliveryController.createDeliveryRequest
);

/**
 * GET /api/v1/deliveries/requests
 * Get all delivery requests for the current client
 * Query params: status, limit, offset
 */
router.get(
  '/requests',
  authorizeRoles('client'),
  listRequestsValidation,
  validate,
  deliveryController.getClientRequests
);

/**
 * GET /api/v1/deliveries/requests/:id
 * Get a specific delivery request by ID
 */
router.get(
  '/requests/:id',
  authorizeRoles('client'),
  requestIdValidation,
  validate,
  deliveryController.getRequestById
);

/**
 * PATCH /api/v1/deliveries/requests/:id
 * Update a pending delivery request
 */
router.patch(
  '/requests/:id',
  authorizeRoles('client'),
  updateRequestValidation,
  validate,
  deliveryController.updateDeliveryRequest
);

/**
 * DELETE /api/v1/deliveries/requests/:id
 * Cancel a pending delivery request
 */
router.delete(
  '/requests/:id',
  authorizeRoles('client'),
  requestIdValidation,
  validate,
  deliveryController.cancelDeliveryRequest
);

/**
 * GET /api/v1/deliveries/history
 * Get completed delivery history
 * Query params: limit, offset, start_date, end_date
 */
router.get(
  '/history',
  authorizeRoles('client'),
  deliveryHistoryValidation,
  validate,
  deliveryController.getDeliveryHistory
);

module.exports = router;
