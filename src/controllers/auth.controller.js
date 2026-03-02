// src/controllers/auth.controller.js
// Authentication controller handling login, token management, password reset

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { query } = require('../config/database');
const logger = require('../utils/logger');
const { getStatusCode } = require('../middleware/error-handler.middleware');

// In-memory store for refresh tokens (in production, use Redis)
const refreshTokens = new Set();

// In-memory store for verification codes (in production, use Redis with TTL)
const verificationCodes = new Map();

/**
 * Generate JWT access token
 */
const generateAccessToken = (user) => {
  // Database returns 'role' as array, ensure it's always an array
  const roles = Array.isArray(user.role) ? user.role : [user.role];

  return jwt.sign(
    {
      id: user.id,
      username: user.username,
      roles: roles
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
  );
};

/**
 * Generate JWT refresh token
 */
const generateRefreshToken = (user) => {
  return jwt.sign(
    { id: user.id },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
  );
};

/**
 * POST /api/v1/auth/login
 * Login with username and password
 */
const login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Find user
    const result = await query(
      `SELECT u.*, 
        COALESCE(cp.full_name, wp.full_name) as full_name
       FROM users u
       LEFT JOIN client_profiles cp ON u.id = cp.user_id
       LEFT JOIN worker_profiles wp ON u.id = wp.user_id
       WHERE u.username = $1 AND u.is_active = true`,
      [username]
    );

    const user = result.rows[0];

    // Verify password (mitigate timing attacks by always running bcrypt)
    const dummyHash = '$2b$12$L9v3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyVdJ3o9OQzi';
    const hashToCompare = user ? user.password_hash : dummyHash;
    const isValidPassword = await bcrypt.compare(password, hashToCompare);
    
    if (!user || !isValidPassword) {
      logger.warn('Failed login attempt:', { username, ip: req.ip });
      return res.status(401).json({
        success: false,
        message: 'Invalid username or password'
      });
    }

    // Update last login
    await query(
      'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
      [user.id]
    );

    // Map singular role to roles array for frontend and middleware compatibility
    user.roles = Array.isArray(user.role) ? user.role : [user.role];

    // Generate tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);
    
    // Store refresh token
    refreshTokens.add(refreshToken);

    logger.info('User logged in successfully:', {
      userId: user.id,
      username: user.username,
      roles: user.roles
    });

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          username: user.username,
          roles: user.roles,
          phone_number: user.phone_number,
          email: user.email,
          full_name: user.full_name,
          preferred_language: user.preferred_language || 'en'
        },
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Login failed'
    });
  }
};

/**
 * POST /api/v1/auth/refresh
 * Refresh access token using refresh token
 */
const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token required'
      });
    }

    // Check if refresh token exists in our store
    if (!refreshTokens.has(refreshToken)) {
      return res.status(403).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Verify refresh token
    jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET, async (err, decoded) => {
      if (err) {
        refreshTokens.delete(refreshToken);
        return res.status(403).json({
          success: false,
          message: 'Invalid or expired refresh token'
        });
      }

      // Get user
      const result = await query(
        'SELECT * FROM users WHERE id = $1 AND is_active = true',
        [decoded.id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      const user = result.rows[0];

      // Generate new access token
      const newAccessToken = generateAccessToken(user);

      res.json({
        success: true,
        data: {
          accessToken: newAccessToken
        }
      });
    });
  } catch (error) {
    logger.error('Token refresh error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Token refresh failed'
    });
  }
};

/**
 * POST /api/v1/auth/logout
 * Logout and invalidate tokens
 */
const logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    // Remove refresh token from store
    if (refreshToken) {
      refreshTokens.delete(refreshToken);
    }

    logger.info('User logged out:', { userId: req.user.id });

    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Logout failed'
    });
  }
};

/**
 * POST /api/v1/auth/password-reset/request
 * Request password reset (sends verification code)
 */
const requestPasswordReset = async (req, res) => {
  try {
    const { phone_number } = req.body;

    // Find user by phone number
    const result = await query(
      'SELECT * FROM users WHERE phone_number = $1 AND is_active = true',
      [phone_number]
    );

    // For security, always return success even if user not found
    if (result.rows.length === 0) {
      return res.json({
        success: true,
        message: 'If this phone number exists, a verification code has been sent'
      });
    }

    const user = result.rows[0];

    // Generate 6-digit verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Store code with expiration (5 minutes)
    verificationCodes.set(phone_number, {
      code: verificationCode,
      userId: user.id,
      expiresAt: Date.now() + 5 * 60 * 1000 // 5 minutes
    });

    // TODO: Send SMS with verification code using Twilio or SMS service
    // For now, we'll log it (NEVER do this in production!)
    logger.info('Password reset code generated:', {
      phone_number,
      code: verificationCode,
      userId: user.id
    });

    res.json({
      success: true,
      message: 'Verification code sent to your phone',
      // Remove this in production:
      dev_code: process.env.NODE_ENV === 'development' ? verificationCode : undefined
    });
  } catch (error) {
    logger.error('Password reset request error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Password reset request failed'
    });
  }
};

/**
 * POST /api/v1/auth/password-reset/verify
 * Verify code and reset password
 */
const verifyAndResetPassword = async (req, res) => {
  try {
    const { phone_number, verification_code, new_password } = req.body;

    // Check if verification code exists and is valid
    const storedData = verificationCodes.get(phone_number);

    if (!storedData) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired verification code'
      });
    }

    // Check if code is expired
    if (Date.now() > storedData.expiresAt) {
      verificationCodes.delete(phone_number);
      return res.status(400).json({
        success: false,
        message: 'Verification code has expired'
      });
    }

    // Check if code matches
    if (storedData.code !== verification_code) {
      return res.status(400).json({
        success: false,
        message: 'Invalid verification code'
      });
    }

    // Hash new password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const passwordHash = await bcrypt.hash(new_password, saltRounds);

    // Update password
    await query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [passwordHash, storedData.userId]
    );

    // Remove verification code
    verificationCodes.delete(phone_number);

    logger.info('Password reset successful:', {
      userId: storedData.userId,
      phone_number
    });

    res.json({
      success: true,
      message: 'Password reset successful'
    });
  } catch (error) {
    logger.error('Password reset error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Password reset failed'
    });
  }
};

/**
 * POST /api/v1/auth/password/change
 * Change password (requires authentication)
 */
const changePassword = async (req, res) => {
  try {
    const { current_password, new_password } = req.body;
    const userId = req.user.id;

    // Get user
    const result = await query(
      'SELECT password_hash FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = result.rows[0];

    // Verify current password
    const isValidPassword = await bcrypt.compare(current_password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const passwordHash = await bcrypt.hash(new_password, saltRounds);

    // Update password
    await query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [passwordHash, userId]
    );

    logger.info('Password changed:', { userId });

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    logger.error('Change password error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Password change failed'
    });
  }
};

/**
 * GET /api/v1/auth/me
 * Get current user info
 */
const getCurrentUser = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT 
        u.id, u.username, u.email, u.phone_number, u.role, u.last_login,
        CASE WHEN cp.id IS NOT NULL THEN
          json_build_object(
            'full_name', cp.full_name,
            'address', cp.address,
            'subscription_type', cp.subscription_type,
            'remaining_coupons', cp.remaining_coupons,
            'current_debt', cp.current_debt
          ) ELSE NULL END as client_profile,
        CASE WHEN wp.id IS NOT NULL THEN
          json_build_object(
            'full_name', wp.full_name,
            'worker_type', wp.worker_type,
            'vehicle_current_gallons', wp.vehicle_current_gallons,
            'gps_sharing_enabled', wp.gps_sharing_enabled
          ) ELSE NULL END as worker_profile
      FROM users u
      LEFT JOIN client_profiles cp ON u.id = cp.user_id
      LEFT JOIN worker_profiles wp ON u.id = wp.user_id
      WHERE u.id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userData = result.rows[0];
    userData.roles = Array.isArray(userData.role) ? userData.role : [userData.role];
    delete userData.role; // Remove singular role to avoid confusion

    res.json({
      success: true,
      data: userData
    });
  } catch (error) {
    logger.error('Get current user error:', error);
    res.status(getStatusCode(error)).json({
      success: false,
      message: 'Failed to get user info'
    });
  }
};

module.exports = {
  login,
  refreshToken,
  logout,
  requestPasswordReset,
  verifyAndResetPassword,
  changePassword,
  getCurrentUser
};
