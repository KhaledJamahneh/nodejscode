// src/middleware/error-handler.middleware.js
// Centralized error handling middleware

const logger = require('../utils/logger');

/**
 * Determine HTTP status code from error
 * @param {Error} error - Error object
 * @returns {number} - HTTP status code
 */
const getStatusCode = (error) => {
  // Custom error with statusCode property
  if (error.statusCode) {
    return error.statusCode;
  }

  const message = error.message || '';

  // Validation errors (400)
  if (
    message.includes('Insufficient inventory') ||
    message.includes('Insufficient coupons') ||
    message.includes('already completed') ||
    message.includes('already assigned') ||
    message.includes('already exists') ||
    message.includes('exceeds request') ||
    message.includes('exceeds limit') ||
    message.includes('cannot be negative') ||
    message.includes('cannot exceed') ||
    message.includes('must be') ||
    message.includes('is required') ||
    message.includes('Invalid') ||
    message.includes('no longer in pending')
  ) {
    return 400;
  }

  // Authorization errors (403)
  if (
    message.includes('inactive') ||
    message.includes('cannot deliver to themselves') ||
    message.includes('not authorized') ||
    message.includes('Permission denied') ||
    message.includes('Access denied') ||
    message.includes('expired')
  ) {
    return 403;
  }

  // Not found errors (404)
  if (
    message.includes('not found') ||
    message.includes('not assigned') ||
    message.includes('does not exist')
  ) {
    return 404;
  }

  // Default to 500 for unexpected errors
  return 500;
};

/**
 * Error handler middleware
 * Use at the end of middleware chain
 */
const errorHandler = (error, req, res, next) => {
  const statusCode = getStatusCode(error);

  // Log error with full context
  logger.error('Request error:', {
    error: error.message,
    statusCode,
    stack: error.stack,
    method: req.method,
    path: req.path,
    userId: req.user?.id,
    body: req.body
  });

  // Send error response
  res.status(statusCode).json({
    success: false,
    message: error.message || 'An error occurred'
  });
};

/**
 * Async handler wrapper to catch errors in async route handlers
 * Usage: router.get('/path', asyncHandler(async (req, res) => { ... }))
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = { errorHandler, asyncHandler, getStatusCode };
