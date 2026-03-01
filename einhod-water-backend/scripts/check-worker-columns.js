// Check worker_profiles columns
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkColumns() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, column_default
      FROM information_schema.columns 
      WHERE table_name = 'worker_profiles'
      ORDER BY ordinal_position
    `);
    
    console.log('\n=== worker_profiles columns ===\n');
    result.rows.forEach((row) => {
      console.log(`${row.column_name} (${row.data_type}) ${row.column_default || ''}`);
    });
    
    await pool.end();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkColumns();
