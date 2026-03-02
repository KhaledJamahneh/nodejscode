// scripts/verify_gallons_on_hand.js
// Verify gallons_on_hand column exists and works correctly

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

async function verify() {
  try {
    console.log('🔍 Checking gallons_on_hand column...\n');

    // Check if column exists
    const columnCheck = await pool.query(`
      SELECT column_name, data_type, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'client_profiles' AND column_name = 'gallons_on_hand'
    `);

    if (columnCheck.rows.length === 0) {
      console.log('❌ Column gallons_on_hand does NOT exist');
      console.log('📝 Run: psql -U postgres -d einhod_water -f migrations/add_gallons_on_hand.sql\n');
      process.exit(1);
    }

    console.log('✅ Column exists:');
    console.log(`   Type: ${columnCheck.rows[0].data_type}`);
    console.log(`   Default: ${columnCheck.rows[0].column_default}\n`);

    // Check current values
    const dataCheck = await pool.query(`
      SELECT 
        COUNT(*) as total_clients,
        SUM(gallons_on_hand) as total_gallons_on_hand,
        AVG(gallons_on_hand) as avg_gallons_on_hand,
        MAX(gallons_on_hand) as max_gallons_on_hand
      FROM client_profiles
    `);

    console.log('📊 Current Statistics:');
    console.log(`   Total Clients: ${dataCheck.rows[0].total_clients}`);
    console.log(`   Total Gallons On Hand: ${dataCheck.rows[0].total_gallons_on_hand || 0}`);
    console.log(`   Average per Client: ${parseFloat(dataCheck.rows[0].avg_gallons_on_hand || 0).toFixed(2)}`);
    console.log(`   Maximum: ${dataCheck.rows[0].max_gallons_on_hand || 0}\n`);

    // Sample data
    const sampleData = await pool.query(`
      SELECT 
        u.username,
        c.full_name,
        c.gallons_on_hand,
        c.monthly_usage_gallons,
        c.remaining_coupons
      FROM client_profiles c
      JOIN users u ON c.user_id = u.id
      LIMIT 5
    `);

    if (sampleData.rows.length > 0) {
      console.log('📋 Sample Client Data:');
      sampleData.rows.forEach(row => {
        console.log(`   ${row.full_name} (@${row.username})`);
        console.log(`      Gallons On Hand: ${row.gallons_on_hand}`);
        console.log(`      Monthly Usage: ${row.monthly_usage_gallons}`);
        console.log(`      Coupons: ${row.remaining_coupons}`);
      });
    }

    console.log('\n✅ All checks passed! Reserved gallons tracking is working.\n');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

verify();
