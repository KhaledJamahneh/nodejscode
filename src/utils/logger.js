// src/utils/logger.js
// Winston logger configuration

const winston = require('winston');
const path = require('path');

// Sanitize stack traces in production
const sanitizeStack = winston.format((info) => {
  if (process.env.NODE_ENV === 'production') {
    // Sanitize stack in error object
    if (info.stack) {
      info.stack = info.stack
        .split('\n')
        .map(line => line.replace(/\/.*?\/(einhod-water-backend|src)\//g, '$1/'))
        .join('\n');
    }
    
    // Sanitize stack in metadata
    if (info.meta && info.meta.stack) {
      info.meta.stack = info.meta.stack
        .split('\n')
        .map(line => line.replace(/\/.*?\/(einhod-water-backend|src)\//g, '$1/'))
        .join('\n');
    }
    
    // Sanitize any stack property in the info object
    Object.keys(info).forEach(key => {
      if (typeof info[key] === 'string' && info[key].includes('    at ')) {
        info[key] = info[key]
          .split('\n')
          .map(line => line.replace(/\/.*?\/(einhod-water-backend|src)\//g, '$1/'))
          .join('\n');
      }
    });
  }
  return info;
});

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  sanitizeStack(),
  winston.format.json()
);

// Console format for development
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  sanitizeStack(),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let msg = `${timestamp} [${level}]: ${message}`;
    
    // Add metadata if exists
    if (Object.keys(meta).length > 0) {
      msg += ` ${JSON.stringify(meta)}`;
    }
    
    return msg;
  })
);

// Create logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  transports: [
    // Write all logs to console
    new winston.transports.Console({
      format: consoleFormat
    }),
    
    // Write all errors to error.log
    new winston.transports.File({
      filename: path.join(__dirname, '../../logs/error.log'),
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    
    // Write all logs to combined.log
    new winston.transports.File({
      filename: path.join(__dirname, '../../logs/combined.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 5
    })
  ]
});

// Create logs directory if it doesn't exist
const fs = require('fs');
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

module.exports = logger;
