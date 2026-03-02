// src/routes/coupon-sizes.routes.js
const express = require('express');
const router = express.Router();
const { body, param } = require('express-validator');
const { validate } = require('../middleware/validation.middleware');
const couponSizesController = require('../controllers/coupon-sizes.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');

// All routes require admin authentication
router.use(authenticateToken);
router.use(authorizeRoles('administrator'));

// ============================================================================
// VALIDATION RULES
// ============================================================================

const couponSizeValidation = [
  body('size')
    .isInt({ min: 1 })
    .withMessage('Size must be a positive integer'),
  body('price_per_page')
    .isFloat({ min: 0 })
    .withMessage('Price per page must be a non-negative number'),
  body('bonus_gallons')
    .isInt({ min: 0 })
    .withMessage('Bonus gallons must be a non-negative integer'),
  body('expiry_days')
    .isInt({ min: 1 })
    .withMessage('Expiry days must be a positive integer'),
  body('available_stock')
    .isInt({ min: 0 })
    .withMessage('Available stock must be a non-negative integer'),
  body('is_active')
    .optional()
    .isBoolean()
    .withMessage('Is active must be a boolean'),
];

const couponSizeIdValidation = [
  param('id').isInt({ min: 1 }).withMessage('Coupon size ID must be a positive integer')
];

// ============================================================================
// ROUTES
// ============================================================================

router.get('/coupon-sizes', couponSizesController.getCouponSizes);
router.post('/coupon-sizes', couponSizeValidation, validate, couponSizesController.createCouponSize);
router.put('/coupon-sizes/:id', couponSizeIdValidation, couponSizeValidation, validate, couponSizesController.updateCouponSize);
router.delete('/coupon-sizes/:id', couponSizeIdValidation, validate, couponSizesController.deleteCouponSize);

module.exports = router;
