// src/config/database.js
// Database connection configuration using pg (node-postgres)

const { Pool, types } = require('pg');
const logger = require('../utils/logger');
const { getContext } = require('../utils/context');

// Flag to track if type parsers are ready
let typeParsersReady = false;
const typeParserPromise = new Promise((resolve) => {
  // Will be resolved by setupDomainTypeParsers
  global.__resolveTypeParsers = resolve;
});

// Database connection pool configuration
const poolConfig = process.env.DATABASE_URL 
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.DB_ALLOW_INSECURE_SSL === 'true' 
        ? { rejectUnauthorized: false }
        : { rejectUnauthorized: true },
      max: parseInt(process.env.DB_POOL_SIZE) || 20,
      idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT) || 30000,
      connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT) || 2000,
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      database: process.env.DB_NAME || 'einhod_water',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
      max: parseInt(process.env.DB_POOL_SIZE) || 20,
      idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT) || 30000,
      connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT) || 2000,
    };

// Create the connection pool
const pool = new Pool(poolConfig);

// Handle pool errors (idle connections)
pool.on('error', (err, client) => {
  logger.error('Unexpected error on idle client', err);
  // Pool will automatically remove the faulty client and create a new one when needed
});

// Monitor pool health (detect connection leaks)
setInterval(() => {
  const { totalCount, idleCount, waitingCount } = pool;
  
  // Alert if pool is exhausted
  if (waitingCount > 0) {
    logger.error('Connection pool exhausted - possible connection leak', {
      totalConnections: totalCount,
      idleConnections: idleCount,
      waitingRequests: waitingCount,
      hint: 'Check for missing client.release() calls or long-running transactions'
    });
  }
  
  // Warn if pool utilization is high
  if (totalCount > 0 && idleCount === 0) {
    logger.warn('Connection pool fully utilized', {
      totalConnections: totalCount,
      idleConnections: idleCount,
      hint: 'Consider increasing DB_POOL_SIZE or optimizing queries'
    });
  }
  
  // Debug log pool stats
  logger.debug('Connection pool stats', {
    total: totalCount,
    idle: idleCount,
    waiting: waitingCount
  });
}, 30000); // Check every 30 seconds

// Test database connection
const connectDatabase = async () => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    logger.info('Database connection successful:', result.rows[0]);
    client.release();
    return true;
  } catch (error) {
    logger.error('Database connection failed:', error.message);
    throw error;
  }
};

/**
 * Sanitize query parameters for logging
 * Truncates large values and removes sensitive data
 */
const sanitizeParams = (params) => {
  if (!params || !Array.isArray(params)) return params;
  
  return params.map(param => {
    // Null/undefined
    if (param === null || param === undefined) return param;
    
    // Numbers/booleans
    if (typeof param === 'number' || typeof param === 'boolean') return param;
    
    // Strings - truncate if too long
    if (typeof param === 'string') {
      if (param.length > 100) {
        return param.substring(0, 100) + `... (${param.length} chars)`;
      }
      return param;
    }
    
    // Objects/Arrays - show type and size only
    if (typeof param === 'object') {
      if (Array.isArray(param)) {
        return `[Array: ${param.length} items]`;
      }
      return `[Object: ${Object.keys(param).length} keys]`;
    }
    
    return String(param);
  });
};

// Query helper function
const query = async (text, params) => {
  // Wait for type parsers to be ready before executing queries
  if (!typeParsersReady) {
    await typeParserPromise;
  }
  
  const start = Date.now();
  const context = getContext();
  
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    
    logger.debug('Executed query', {
      query: text.length > 500 ? text.substring(0, 500) + '...' : text,
      params: sanitizeParams(params),
      duration: `${duration}ms`,
      rows: result.rowCount,
      requestId: context.requestId,
      userId: context.userId,
      userRole: context.userRole
    });
    
    return result;
  } catch (error) {
    logger.error('Query error:', {
      query: text.length > 500 ? text.substring(0, 500) + '...' : text,
      params: sanitizeParams(params),
      error: error.message,
      errorCode: error.code,
      errorDetail: error.detail,
      stack: error.stack, // Full stack trace for debugging
      requestId: context.requestId,
      userId: context.userId,
      userRole: context.userRole
    });
    throw error;
  }
};

// Transaction helper
// WARNING: Keep transactions SHORT. Never call external APIs or perform I/O inside the callback.
// Only database operations should be inside transactions to avoid holding connections hostage.
//
// ❌ ANTI-PATTERN (causes deadlock):
//   await transaction(async (client) => {
//     await client.query('UPDATE deliveries SET status = $1', ['completed']);
//     await fcmService.sendNotification(...); // ❌ External API blocks connection
//   });
//
// ✅ CORRECT PATTERN (deferred execution):
//   const deferredTasks = [];
//   await transaction(async (client) => {
//     await client.query('UPDATE deliveries SET status = $1', ['completed']);
//     deferredTasks.push(() => fcmService.sendNotification(...)); // Queue for later
//   });
//   await Promise.allSettled(deferredTasks.map(fn => fn())); // Execute after commit
//
const transaction = async (callback) => {
  const client = await pool.connect();
  const startTime = Date.now();
  const context = getContext();
  let transactionStarted = false;
  
  try {
    await client.query('BEGIN');
    transactionStarted = true;
    
    const result = await callback(client);
    await client.query('COMMIT');
    
    const duration = Date.now() - startTime;
    if (duration > 1000) {
      logger.warn('Long transaction detected - possible external API call inside transaction', {
        duration: `${duration}ms`,
        requestId: context.requestId,
        userId: context.userId,
        hint: 'Move FCM/Stripe/Twilio/email calls outside transaction. See database.js for pattern.'
      });
    }
    
    return result;
  } catch (error) {
    const duration = Date.now() - startTime;
    
    // Log transaction failure with full context
    logger.error('Transaction failed:', {
      error: error.message,
      errorCode: error.code,
      errorDetail: error.detail,
      stack: error.stack, // Full stack trace for debugging
      duration: `${duration}ms`,
      requestId: context.requestId,
      userId: context.userId,
      userRole: context.userRole
    });
    
    // Only attempt rollback if transaction was successfully started
    if (transactionStarted) {
      try {
        await client.query('ROLLBACK');
      } catch (rollbackError) {
        logger.error('Rollback failed:', {
          originalError: error.message,
          rollbackError: rollbackError.message,
          rollbackStack: rollbackError.stack,
          requestId: context.requestId
        });
      }
    }
    throw error;
  } finally {
    // Always release the client back to pool
    try {
      client.release();
    } catch (releaseError) {
      logger.error('Failed to release client:', {
        error: releaseError.message,
        stack: releaseError.stack
      });
    }
  }
};

// Get a client from the pool for complex operations
// ⚠️ WARNING: You MUST call client.release() when done, or the connection will leak!
// 
// ❌ DANGEROUS - Easy to forget release():
//   const client = await getClient();
//   await client.query('SELECT ...');
//   // Forgot to call client.release() → CONNECTION LEAK
//
// ✅ RECOMMENDED - Use transaction() or query() instead:
//   await transaction(async (client) => {
//     await client.query('SELECT ...');
//     // Automatic release
//   });
//
// ✅ IF YOU MUST USE getClient(), use try-finally:
//   const client = await getClient();
//   try {
//     await client.query('SELECT ...');
//   } finally {
//     client.release(); // CRITICAL: Always release
//   }
//
// Connection leak impact:
// - Pool has max 20 connections
// - 20 leaked connections = entire app hangs
// - Requires server restart to recover
//
const getClient = async () => {
  const client = await pool.connect();
  
  // Track connection acquisition for leak detection
  const context = getContext();
  logger.warn('Raw client acquired - ensure client.release() is called', {
    requestId: context.requestId,
    userId: context.userId,
    stack: new Error().stack.split('\n').slice(2, 4).join('\n') // Show caller
  });
  
  return client;
};

// Close the pool
const closePool = async () => {
  await pool.end();
  logger.info('Database pool closed');
};

module.exports = {
  pool,
  query,
  transaction,
  getClient,
  connectDatabase,
  closePool,
  types, // Export types for domain-level custom parsers
  markTypeParsersReady: () => {
    typeParsersReady = true;
    if (global.__resolveTypeParsers) {
      global.__resolveTypeParsers();
    }
  }
};
