// src/utils/roles.js
// Role management utilities

/**
 * Check if user has any of the specified roles
 * @param {Array} userRoles - User's roles array
 * @param {Array} requiredRoles - Required roles
 * @returns {boolean}
 */
const hasAnyRole = (userRoles, requiredRoles) => {
  if (!Array.isArray(userRoles) || !Array.isArray(requiredRoles)) {
    return false;
  }
  return requiredRoles.some(role => userRoles.includes(role));
};

/**
 * Check if user has all specified roles
 * @param {Array} userRoles - User's roles array
 * @param {Array} requiredRoles - Required roles
 * @returns {boolean}
 */
const hasAllRoles = (userRoles, requiredRoles) => {
  if (!Array.isArray(userRoles) || !Array.isArray(requiredRoles)) {
    return false;
  }
  return requiredRoles.every(role => userRoles.includes(role));
};

/**
 * Check if user has specific role
 * @param {Array} userRoles - User's roles array
 * @param {string} role - Role to check
 * @returns {boolean}
 */
const hasRole = (userRoles, role) => {
  if (!Array.isArray(userRoles)) {
    return false;
  }
  return userRoles.includes(role);
};

/**
 * Check if user is admin or owner
 * @param {Array} userRoles - User's roles array
 * @returns {boolean}
 */
const isAdminOrOwner = (userRoles) => {
  return hasAnyRole(userRoles, ['administrator', 'owner']);
};

/**
 * Check if user is client
 * @param {Array} userRoles - User's roles array
 * @returns {boolean}
 */
const isClient = (userRoles) => {
  return hasRole(userRoles, 'client');
};

/**
 * Check if user is worker (delivery or onsite)
 * @param {Array} userRoles - User's roles array
 * @returns {boolean}
 */
const isWorker = (userRoles) => {
  return hasAnyRole(userRoles, ['delivery_worker', 'onsite_worker']);
};

module.exports = {
  hasAnyRole,
  hasAllRoles,
  hasRole,
  isAdminOrOwner,
  isClient,
  isWorker
};
