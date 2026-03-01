// src/config/domain-types.js
// Domain-specific PostgreSQL type parsers

const { pool, types, markTypeParsersReady } = require('./database');
const logger = require('../utils/logger');

// Register custom type parser for user_role[] enum array
const setupUserRoleParser = async () => {
  try {
    const result = await pool.query("SELECT oid FROM pg_type WHERE typname = '_user_role'");
    if (result.rows.length > 0) {
      const _user_role_oid = parseInt(result.rows[0].oid);
      
      // Use pg's built-in array parser
      const parseArray = types.getTypeParser(1009); // 1009 is OID for text[]
      types.setTypeParser(_user_role_oid, parseArray);
      
      logger.debug(`Registered custom parser for _user_role (OID: ${_user_role_oid})`);
    }
  } catch (error) {
    logger.warn('Failed to register user_role parser:', error.message);
  }
};

// Initialize all domain-specific type parsers
const setupDomainTypeParsers = async () => {
  await setupUserRoleParser();
  // Add more domain-specific parsers here as needed
  
  // Mark parsers as ready - allows queries to proceed
  markTypeParsersReady();
  logger.info('Domain type parsers initialized');
};

module.exports = {
  setupDomainTypeParsers
};
