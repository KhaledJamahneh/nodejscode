// src/routes/location.routes.js
const express = require('express');
const router = express.Router();
const locationController = require('../controllers/location.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');

// Worker routes
router.post('/update', authenticateToken, authorizeRoles('delivery_worker', 'onsite_worker'), locationController.updateLocation);
router.get('/worker/:workerId', authenticateToken, locationController.getWorkerLocation);

// Admin routes
router.get('/active', authenticateToken, authorizeRoles('administrator', 'owner'), locationController.getActiveWorkerLocations);

module.exports = router;
