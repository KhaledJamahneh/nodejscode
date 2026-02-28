// src/routes/shifts.routes.js
const express = require('express');
const router = express.Router();
const { body, param } = require('express-validator');
const { validate } = require('../middleware/validation.middleware');
const shiftsController = require('../controllers/shifts.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');

// All routes require authentication and admin/owner role
router.use(authenticateToken);
router.use(authorizeRoles('administrator', 'owner'));

// ============================================================================
// VALIDATION RULES
// ============================================================================

const shiftValidation = [
  body('shift_name').trim().notEmpty().withMessage('Shift name is required'),
  body('start_time').matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/).withMessage('Start time must be in HH:MM format'),
  body('end_time').matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/).withMessage('End time must be in HH:MM format'),
  body('days_of_week')
    .isArray({ min: 1, max: 7 })
    .withMessage('Days of week must be an array with 1-7 days')
    .custom((value) => value.every(day => Number.isInteger(day) && day >= 0 && day <= 6))
    .withMessage('Days must be integers between 0 (Sunday) and 6 (Saturday)'),
];

const assignShiftValidation = [
  body('shift_id').isInt({ min: 1 }).withMessage('Shift ID must be a positive integer'),
  body('worker_id').isInt({ min: 1 }).withMessage('Worker ID must be a positive integer'),
  body('start_date').isISO8601().withMessage('Start date must be a valid date'),
  body('end_date').optional().isISO8601().withMessage('End date must be a valid date'),
];

const leaveValidation = [
  body('worker_id').isInt({ min: 1 }).withMessage('Worker ID must be a positive integer'),
  body('start_date').isISO8601().withMessage('Start date must be a valid date'),
  body('end_date').isISO8601().withMessage('End date must be a valid date'),
  body('reason').trim().notEmpty().withMessage('Reason is required'),
];

const shiftIdValidation = [
  param('id').isInt({ min: 1 }).withMessage('Shift ID must be a positive integer')
];

const leaveIdValidation = [
  param('id').isInt({ min: 1 }).withMessage('Leave ID must be a positive integer')
];

// ============================================================================
// SHIFT ROUTES
// ============================================================================

router.get('/shifts', shiftsController.getShifts);
router.post('/shifts', shiftValidation, validate, shiftsController.createShift);
router.put('/shifts/:id', shiftIdValidation, shiftValidation, validate, shiftsController.updateShift);
router.delete('/shifts/:id', shiftIdValidation, validate, shiftsController.deleteShift);
router.post('/shifts/assign', assignShiftValidation, validate, shiftsController.assignShift);

// ============================================================================
// LEAVE ROUTES
// ============================================================================

router.get('/leaves', shiftsController.getLeaves);
router.post('/leaves', leaveValidation, validate, shiftsController.createLeave);
router.put('/leaves/:id', leaveIdValidation, leaveValidation, validate, shiftsController.updateLeave);
router.delete('/leaves/:id', leaveIdValidation, validate, shiftsController.deleteLeave);

module.exports = router;
