// src/routes/auth.routes.js
// Authentication routes: login, register, password reset

const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { validate } = require('../middleware/validation.middleware');
const { authenticateToken } = require('../middleware/auth.middleware');

const router = express.Router();

// ============================================================================
// VALIDATION RULES
// ============================================================================

const loginValidation = [
  body('username').trim().notEmpty().withMessage('Username is required'),
  body('password').notEmpty().withMessage('Password is required')
];

const passwordResetRequestValidation = [
  body('phone_number')
    .trim()
    .notEmpty()
    .withMessage('Phone number is required')
    .matches(/^\d{7,15}$/)
    .withMessage('Phone number must be 7-15 digits')
];

const passwordResetValidation = [
  body('phone_number')
    .trim()
    .notEmpty()
    .matches(/^\d{7,15}$/)
    .withMessage('Phone number must be 7-15 digits'),
  body('verification_code').trim().notEmpty().withMessage('Verification code is required'),
  body('new_password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain uppercase, lowercase, number, and special character')
];

const changePasswordValidation = [
  body('new_password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain uppercase, lowercase, number, and special character')
];

// ============================================================================
// ROUTES
// ============================================================================

/**
 * POST /api/v1/auth/login
 * Login with username and password
 */
router.post('/login', loginValidation, validate, authController.login);

/**
 * POST /api/v1/auth/refresh
 * Refresh access token using refresh token
 */
router.post('/refresh', authController.refreshToken);

/**
 * POST /api/v1/auth/logout
 * Logout and invalidate tokens
 */
router.post('/logout', authenticateToken, authController.logout);

/**
 * POST /api/v1/auth/password-reset/request
 * Request password reset (sends verification code via SMS)
 */
router.post(
  '/password-reset/request',
  passwordResetRequestValidation,
  validate,
  authController.requestPasswordReset
);

/**
 * POST /api/v1/auth/password-reset/verify
 * Verify code and reset password
 */
router.post(
  '/password-reset/verify',
  passwordResetValidation,
  validate,
  authController.verifyAndResetPassword
);

/**
 * POST /api/v1/auth/password/change
 * Change password (requires authentication)
 */
router.post(
  '/password/change',
  authenticateToken,
  changePasswordValidation,
  validate,
  authController.changePassword
);

/**
 * GET /api/v1/auth/me
 * Get current user info
 */
router.get('/me', authenticateToken, authController.getCurrentUser);

module.exports = router;
