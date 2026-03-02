// Check actual role column type in database
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkRoleType() {
  try {
    // Check column type
    const colType = await pool.query(`
      SELECT 
        column_name,
        data_type,
        udt_name,
        column_default
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND column_name = 'role'
    `);
    
    console.log('\n=== USERS.role column ===');
    console.log(colType.rows[0]);
    
    // Check if user_role enum exists
    const enumCheck = await pool.query(`
      SELECT typname, typtype, typarray
      FROM pg_type 
      WHERE typname IN ('user_role', '_user_role')
    `);
    
    console.log('\n=== user_role enum types ===');
    if (enumCheck.rows.length === 0) {
      console.log('❌ No user_role enum found!');
    } else {
      enumCheck.rows.forEach(row => {
        console.log(`${row.typname} (typtype: ${row.typtype}, typarray: ${row.typarray})`);
      });
    }
    
    // Check actual data
    const sample = await pool.query(`
      SELECT username, role, pg_typeof(role) as role_type
      FROM users 
      LIMIT 3
    `);
    
    console.log('\n=== Sample user roles ===');
    sample.rows.forEach(row => {
      console.log(`${row.username}: ${JSON.stringify(row.role)} (type: ${row.role_type})`);
    });
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkRoleType();
