
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkRevenue() {
  try {
    const res = await pool.query(`
      SELECT SUM(amount) as total_revenue, COUNT(*) as count
      FROM payments
      WHERE payment_status = 'completed'
    `);
    console.log('Total revenue:', res.rows[0].total_revenue);
    console.log('Total count:', res.rows[0].count);
    
    const allRes = await pool.query(`
      SELECT id, amount, payment_status, description FROM payments
    `);
    console.log('All payments:', JSON.stringify(allRes.rows, null, 2));
    
    await pool.end();
  } catch (err) {
    console.error('Error checking revenue:', err);
    process.exit(1);
  }
}

checkRevenue();
