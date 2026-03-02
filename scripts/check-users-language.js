// Check if users table has language column
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkUsersLanguage() {
  try {
    const result = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND (column_name LIKE '%language%' OR column_name LIKE '%lang%')
    `);
    
    console.log('\n=== Language columns in USERS table ===\n');
    if (result.rows.length === 0) {
      console.log('✅ No language column found in users table');
    } else {
      result.rows.forEach(row => console.log(`- ${row.column_name}`));
    }
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkUsersLanguage();
