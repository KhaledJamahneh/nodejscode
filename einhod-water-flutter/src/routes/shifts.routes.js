// src/routes/shifts.routes.js
const express = require('express');
const router = express.Router();
const shiftsController = require('../controllers/shifts.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');

// All routes require authentication and admin/owner role
router.use(authenticateToken);
router.use(authorizeRoles('administrator', 'owner'));

// Shift routes
router.get('/shifts', shiftsController.getShifts);
router.post('/shifts', shiftsController.createShift);
router.put('/shifts/:id', shiftsController.updateShift);
router.delete('/shifts/:id', shiftsController.deleteShift);
router.post('/shifts/assign', shiftsController.assignShift);

// Leave routes
router.get('/leaves', shiftsController.getLeaves);
router.post('/leaves', shiftsController.createLeave);
router.put('/leaves/:id', shiftsController.updateLeave);
router.delete('/leaves/:id', shiftsController.deleteLeave);

module.exports = router;
