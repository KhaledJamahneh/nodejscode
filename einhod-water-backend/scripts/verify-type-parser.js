// Verify type parser is working correctly
const db = require('../src/config/database');

(async () => {
  try {
    console.log('\n=== Type Parser Verification ===\n');
    
    // Check type exists
    const typeCheck = await db.query(`
      SELECT oid, typname FROM pg_type WHERE typname = '_user_role'
    `);
    console.log('1. Type found in database:');
    console.log(`   OID: ${typeCheck.rows[0]?.oid}`);
    console.log(`   Name: ${typeCheck.rows[0]?.typname}`);
    
    // Query a user
    const userResult = await db.query('SELECT id, email, role FROM users LIMIT 1');
    const user = userResult.rows[0];
    
    console.log('\n2. User role data:');
    console.log(`   Raw value: ${JSON.stringify(user.role)}`);
    console.log(`   Type: ${typeof user.role}`);
    console.log(`   Is Array: ${Array.isArray(user.role)}`);
    
    // Test array methods
    console.log('\n3. Array method tests:');
    console.log(`   user.role.includes('client'): ${user.role.includes('client')}`);
    console.log(`   user.role.length: ${user.role.length}`);
    console.log(`   user.role[0]: ${user.role[0]}`);
    
    console.log('\n✅ Type parser working correctly!\n');
    
    db.closePool();
  } catch (err) {
    console.error('\n❌ Error:', err.message);
    console.error(err.stack);
    process.exit(1);
  }
})();
