// src/routes/coupon-sizes.routes.js
const express = require('express');
const router = express.Router();
const couponSizesController = require('../controllers/coupon-sizes.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');

// All routes require admin authentication
router.use(authenticateToken);
router.use(authorizeRoles('administrator'));

router.get('/coupon-sizes', couponSizesController.getCouponSizes);
router.post('/coupon-sizes', couponSizesController.createCouponSize);
router.put('/coupon-sizes/:id', couponSizesController.updateCouponSize);
router.delete('/coupon-sizes/:id', couponSizesController.deleteCouponSize);

module.exports = router;
