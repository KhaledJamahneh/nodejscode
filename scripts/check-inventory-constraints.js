// Check database constraints on vehicle_current_gallons
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkInventoryConstraints() {
  try {
    // Check table constraints
    const constraints = await pool.query(`
      SELECT 
        conname as constraint_name,
        pg_get_constraintdef(oid) as definition
      FROM pg_constraint
      WHERE conrelid = 'worker_profiles'::regclass
      AND conname LIKE '%gallon%'
    `);
    
    console.log('\n=== Constraints on worker_profiles ===\n');
    if (constraints.rows.length === 0) {
      console.log('❌ No constraints found on gallon columns');
    } else {
      constraints.rows.forEach(row => {
        console.log(`${row.constraint_name}:`);
        console.log(`  ${row.definition}\n`);
      });
    }
    
    // Check column definition
    const colDef = await pool.query(`
      SELECT 
        column_name,
        data_type,
        column_default,
        is_nullable
      FROM information_schema.columns
      WHERE table_name = 'worker_profiles'
      AND column_name IN ('vehicle_current_gallons', 'vehicle_capacity')
    `);
    
    console.log('=== Column definitions ===\n');
    colDef.rows.forEach(row => {
      console.log(`${row.column_name}: ${row.data_type} DEFAULT ${row.column_default || 'NULL'}`);
    });
    
    // Test negative value
    console.log('\n=== Testing negative inventory ===\n');
    try {
      await pool.query(`
        UPDATE worker_profiles 
        SET vehicle_current_gallons = -100 
        WHERE id = 1
      `);
      console.log('⚠️  WARNING: Negative inventory allowed! No CHECK constraint.');
      // Rollback
      await pool.query(`
        UPDATE worker_profiles 
        SET vehicle_current_gallons = 0 
        WHERE id = 1
      `);
    } catch (error) {
      console.log('✅ Negative inventory blocked by constraint');
    }
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkInventoryConstraints();
