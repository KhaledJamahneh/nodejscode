// src/utils/errors.js
// Custom error classes for better error handling

/**
 * Business logic validation error (HTTP 400)
 * Use for: insufficient inventory, invalid state transitions, validation failures
 */
class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
    this.statusCode = 400;
  }
}

/**
 * Resource not found error (HTTP 404)
 * Use for: user not found, delivery not found, etc.
 */
class NotFoundError extends Error {
  constructor(message) {
    super(message);
    this.name = 'NotFoundError';
    this.statusCode = 404;
  }
}

/**
 * Authentication error (HTTP 401)
 * Use for: invalid token, expired session
 */
class AuthenticationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'AuthenticationError';
    this.statusCode = 401;
  }
}

/**
 * Authorization error (HTTP 403)
 * Use for: insufficient permissions, account inactive
 */
class AuthorizationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'AuthorizationError';
    this.statusCode = 403;
  }
}

/**
 * Conflict error (HTTP 409)
 * Use for: duplicate entries, race conditions
 */
class ConflictError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ConflictError';
    this.statusCode = 409;
  }
}

module.exports = {
  ValidationError,
  NotFoundError,
  AuthenticationError,
  AuthorizationError,
  ConflictError
};
