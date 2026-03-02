// src/middleware/context.middleware.js
// Request context middleware for audit logging

const { asyncLocalStorage } = require('../utils/context');
const { v4: uuidv4 } = require('crypto');

const contextMiddleware = (req, res, next) => {
  const context = {
    requestId: req.headers['x-request-id'] || generateRequestId(),
    userId: req.user?.userId || null,
    userRole: req.user?.role || null,
    ip: req.ip || req.connection.remoteAddress,
    method: req.method,
    path: req.path
  };

  // Set request ID in response header for tracing
  res.setHeader('X-Request-ID', context.requestId);

  // Run the rest of the request within this context
  asyncLocalStorage.run(context, () => {
    next();
  });
};

// Generate unique request ID
const generateRequestId = () => {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};

module.exports = contextMiddleware;
