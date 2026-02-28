// src/middleware/auth.middleware.js
// JWT authentication and authorization middleware

const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

/**
 * Verify JWT token and attach user to request
 */
const authenticateToken = (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access token required'
      });
    }

    // Verify token
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (err) {
        logger.warn('Invalid token attempt:', { error: err.message });
        return res.status(403).json({
          success: false,
          message: 'Invalid or expired token'
        });
      }

      // Attach user to request
      req.user = user;
      next();
    });
  } catch (error) {
    logger.error('Authentication error:', error);
    res.status(500).json({
      success: false,
      message: 'Authentication failed'
    });
  }
};

/**
 * Check if user has required role(s)
 * @param {Array} allowedRoles - Array of allowed roles
 */
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    // Support multiple roles (roles array)
    const userRoles = req.user.roles || [];
    const hasRequiredRole = allowedRoles.some(role => userRoles.includes(role));

    if (!hasRequiredRole) {
      logger.warn('Unauthorized access attempt:', {
        user: req.user.id,
        roles: userRoles,
        requiredRoles: allowedRoles,
        path: req.path
      });

      return res.status(403).json({
        success: false,
        message: 'You do not have permission to access this resource'
      });
    }

    next();
  };
};

/**
 * Optional authentication - attaches user if token is valid, but doesn't fail if missing
 */
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return next();
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (!err) {
      req.user = user;
    }
    next();
  });
};

/**
 * Check if user owns the resource or is admin
 * Expects req.params.userId to match req.user.id or user to be admin/owner
 */
const authorizeOwnerOrAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'User not authenticated'
    });
  }

  const userRoles = req.user.roles || [];
  const isOwner = req.user.id === parseInt(req.params.userId);
  const isAdmin = userRoles.some(role => ['administrator', 'owner'].includes(role));

  if (!isOwner && !isAdmin) {
    return res.status(403).json({
      success: false,
      message: 'You can only access your own data'
    });
  }

  next();
};

module.exports = {
  authenticateToken,
  authorizeRoles,
  optionalAuth,
  authorizeOwnerOrAdmin
};
