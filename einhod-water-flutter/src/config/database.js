// src/config/database.js
// Database connection configuration using pg (node-postgres)

const { Pool, types } = require('pg');
const logger = require('../utils/logger');

// Register parser for user_role[] enum array
const setupCustomTypeParsers = async () => {
  try {
    const result = await pool.query("SELECT oid FROM pg_type WHERE typname = '_user_role'");
    if (result.rows.length > 0) {
      const _user_role_oid = parseInt(result.rows[0].oid);
      
      const parseUserRoleArray = (val) => {
        if (!val) return [];
        // Simple parsing of Postgres array format "{item1,item2}"
        return val.replace(/{|}/g, '').split(',').filter(s => s.length > 0);
      };
      
      types.setTypeParser(_user_role_oid, parseUserRoleArray);
      logger.debug(`Registered custom parser for _user_role (OID: ${_user_role_oid})`);
    }
  } catch (error) {
    logger.warn('Failed to register custom type parsers:', error.message);
  }
};

// Database connection pool configuration
const poolConfig = process.env.DATABASE_URL 
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false
      },
      max: 20, // Limit pool size
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000, // Fail fast if DB is unreachable
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      database: process.env.DB_NAME || 'einhod_water',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
      max: 20, // Limit pool size
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    };

// Create the connection pool
const pool = new Pool(poolConfig);

// Handle pool errors
pool.on('error', (err, client) => {
  logger.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Test database connection
const connectDatabase = async () => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    logger.info('Database connection successful:', result.rows[0]);
    client.release();
    
    // Setup custom type parsers after initial connection
    await setupCustomTypeParsers();
    
    return true;
  } catch (error) {
    logger.error('Database connection failed:', error.message);
    throw error;
  }
};

// Query helper function
const query = async (text, params) => {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    
    logger.debug('Executed query', {
      query: text,
      duration: `${duration}ms`,
      rows: result.rowCount
    });
    
    return result;
  } catch (error) {
    logger.error('Query error:', {
      query: text,
      error: error.message
    });
    throw error;
  }
};

// Transaction helper
const transaction = async (callback) => {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

// Get a client from the pool for complex operations
const getClient = async () => {
  return await pool.connect();
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
  closePool
};
