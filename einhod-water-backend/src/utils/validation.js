// src/utils/validation.js
// Input validation utilities to prevent data corruption and injection attacks

/**
 * Validate that a value is a positive number
 * @param {any} value - Value to validate
 * @param {string} fieldName - Field name for error message
 * @returns {object} - { valid: boolean, error: string|null, value: number|null }
 */
const validatePositiveNumber = (value, fieldName) => {
  if (value === undefined || value === null) {
    return { valid: false, error: `${fieldName} is required`, value: null };
  }

  const num = Number(value);
  
  if (isNaN(num)) {
    return { valid: false, error: `${fieldName} must be a number`, value: null };
  }

  if (num <= 0) {
    return { valid: false, error: `${fieldName} must be a positive number`, value: null };
  }

  return { valid: true, error: null, value: num };
};

/**
 * Validate that a value is a non-negative number (0 or greater)
 * @param {any} value - Value to validate
 * @param {string} fieldName - Field name for error message
 * @returns {object} - { valid: boolean, error: string|null, value: number|null }
 */
const validateNonNegativeNumber = (value, fieldName) => {
  if (value === undefined || value === null) {
    return { valid: true, error: null, value: 0 }; // Optional field, default to 0
  }

  const num = Number(value);
  
  if (isNaN(num)) {
    return { valid: false, error: `${fieldName} must be a number`, value: null };
  }

  if (num < 0) {
    return { valid: false, error: `${fieldName} must be a non-negative number`, value: null };
  }

  return { valid: true, error: null, value: num };
};

/**
 * Validate that a value is a non-negative integer
 * @param {any} value - Value to validate
 * @param {string} fieldName - Field name for error message
 * @returns {object} - { valid: boolean, error: string|null, value: number|null }
 */
const validateNonNegativeInteger = (value, fieldName) => {
  if (value === undefined || value === null) {
    return { valid: true, error: null, value: 0 }; // Optional field, default to 0
  }

  const num = Number(value);
  
  if (isNaN(num)) {
    return { valid: false, error: `${fieldName} must be a number`, value: null };
  }

  if (num < 0) {
    return { valid: false, error: `${fieldName} must be non-negative`, value: null };
  }

  if (!Number.isInteger(num)) {
    return { valid: false, error: `${fieldName} must be an integer`, value: null };
  }

  return { valid: true, error: null, value: num };
};

/**
 * Validate multiple fields and return first error
 * @param {array} validations - Array of validation results
 * @returns {object} - { valid: boolean, error: string|null }
 */
const validateAll = (validations) => {
  for (const validation of validations) {
    if (!validation.valid) {
      return { valid: false, error: validation.error };
    }
  }
  return { valid: true, error: null };
};

module.exports = {
  validatePositiveNumber,
  validateNonNegativeNumber,
  validateNonNegativeInteger,
  validateAll
};
