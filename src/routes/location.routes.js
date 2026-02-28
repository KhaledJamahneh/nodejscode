// src/routes/location.routes.js
const express = require('express');
const { body, param } = require('express-validator');
const router = express.Router();
const locationController = require('../controllers/location.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validation.middleware');

// Worker routes
router.post(
  '/update',
  authenticateToken,
  authorizeRoles('delivery_worker', 'onsite_worker'),
  [
    body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude required'),
    body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude required'),
    body('accuracy_meters').optional().isFloat({ min: 0 }).withMessage('Accuracy must be a positive number'),
    body('speed_kmh').optional().isFloat({ min: 0 }).withMessage('Speed must be a positive number')
  ],
  validate,
  locationController.updateLocation
);

router.get(
  '/worker/:workerId',
  authenticateToken,
  authorizeRoles('administrator', 'owner'), // Only admin/owner can get specific worker location
  [param('workerId').isInt({ min: 1 }).withMessage('Worker ID must be a positive integer')],
  validate,
  locationController.getWorkerLocation
);

// Admin routes
router.get('/active', authenticateToken, authorizeRoles('administrator', 'owner'), locationController.getActiveWorkerLocations);

module.exports = router;
