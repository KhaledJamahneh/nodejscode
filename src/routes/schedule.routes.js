const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/schedule.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');
const { body, param } = require('express-validator');

router.use(authenticateToken);
router.use(authorizeRoles('administrator', 'owner'));

// Reusing validation from admin.routes.js for consistency and rigor
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

const scheduleIdValidation = [
  param('id').isInt({ min: 1 }).withMessage('Schedule ID must be a positive integer')
];

router.get('/', scheduleController.getSchedules);
router.get('/:id', scheduleIdValidation, validate, scheduleController.getSchedule);
router.post('/', createScheduleValidation, validate, scheduleController.createSchedule);
router.put('/:id', scheduleIdValidation, createScheduleValidation, validate, scheduleController.updateSchedule);
router.delete('/:id', scheduleIdValidation, validate, scheduleController.deleteSchedule);
router.post('/batch-delete', scheduleController.batchDeleteSchedules);
router.post('/:id/create-delivery', scheduleIdValidation, validate, scheduleController.createDeliveryFromSchedule);
router.delete('/:id/unassign-delivery', scheduleIdValidation, validate, scheduleController.unassignScheduleDelivery);

module.exports = router;
