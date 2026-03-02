
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkPayments() {
  try {
    const res = await pool.query(`
      SELECT p.id, p.amount, p.payment_status, p.description, p.payment_date, u.username
      FROM payments p
      JOIN users u ON p.payer_id = u.id
      ORDER BY p.payment_date DESC
      LIMIT 10
    `);
    console.log('Recent payments:', JSON.stringify(res.rows, null, 2));
    await pool.end();
  } catch (err) {
    console.error('Error checking payments:', err);
    process.exit(1);
  }
}

checkPayments();
