// Test robust array parsing with edge cases
const parseArray = require('postgres-array').parse;

console.log('\n=== Testing Robust Array Parser ===\n');

// Test cases
const testCases = [
  { input: '{admin}', expected: ['admin'] },
  { input: '{admin,worker}', expected: ['admin', 'worker'] },
  { input: '{}', expected: [] },
  { input: '{admin,worker,client}', expected: ['admin', 'worker', 'client'] },
  // Edge case: quoted values with commas (if ever needed)
  { input: '{"admin","support,level1"}', expected: ['admin', 'support,level1'] },
  // Edge case: values with spaces
  { input: '{"admin user","worker"}', expected: ['admin user', 'worker'] },
];

testCases.forEach(({ input, expected }) => {
  const result = parseArray(input);
  const pass = JSON.stringify(result) === JSON.stringify(expected);
  console.log(`${pass ? '✅' : '❌'} Input: ${input}`);
  console.log(`   Expected: ${JSON.stringify(expected)}`);
  console.log(`   Got: ${JSON.stringify(result)}`);
  console.log();
});

console.log('=== Testing with Database ===\n');
const db = require('../src/config/database');

setTimeout(async () => {
  const result = await db.query('SELECT id, email, role FROM users LIMIT 1');
  const user = result.rows[0];
  
  console.log('User role:', user.role);
  console.log('Is Array:', Array.isArray(user.role));
  console.log('Type:', typeof user.role);
  
  db.closePool();
}, 1000);
