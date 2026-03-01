// Test stack trace sanitization
process.env.NODE_ENV = 'production';
const logger = require('../src/utils/logger');

console.log('\n=== Testing Stack Trace Sanitization ===\n');

try {
  // Trigger an error with a stack trace
  const obj = null;
  obj.someMethod();
} catch (error) {
  console.log('Original stack trace:');
  console.log(error.stack);
  
  console.log('\n--- Logging to Winston (production mode) ---\n');
  logger.error('Test error with stack trace', { 
    error: error.message,
    stack: error.stack 
  });
  
  console.log('\n✅ Check logs/error.log to verify paths are sanitized\n');
}
