// Run inventory constraints migration
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function addInventoryConstraints() {
  try {
    console.log('🔒 Adding inventory constraints to worker_profiles...\n');
    
    // Read migration file
    const migrationSQL = fs.readFileSync(
      path.join(__dirname, '../migrations/add_inventory_constraints.sql'),
      'utf8'
    );
    
    // Execute migration
    await pool.query(migrationSQL);
    
    console.log('✅ Constraints added successfully!\n');
    
    // Verify constraints
    const constraints = await pool.query(`
      SELECT 
        conname as constraint_name,
        pg_get_constraintdef(oid) as definition
      FROM pg_constraint
      WHERE conrelid = 'worker_profiles'::regclass
      AND conname LIKE '%gallon%'
      ORDER BY conname
    `);
    
    console.log('📋 Active constraints:');
    constraints.rows.forEach(row => {
      console.log(`   ✓ ${row.constraint_name}`);
      console.log(`     ${row.definition}\n`);
    });
    
    // Test negative value (should fail)
    console.log('🧪 Testing negative inventory...');
    try {
      await pool.query(`
        UPDATE worker_profiles 
        SET vehicle_current_gallons = -100 
        WHERE id = 1
      `);
      console.log('   ❌ FAILED: Negative inventory still allowed!');
    } catch (error) {
      console.log('   ✅ PASSED: Negative inventory blocked');
    }
    
    // Test over-capacity (should fail)
    console.log('\n🧪 Testing over-capacity...');
    try {
      await pool.query(`
        UPDATE worker_profiles 
        SET vehicle_current_gallons = 99999 
        WHERE id = 1
      `);
      console.log('   ❌ FAILED: Over-capacity still allowed!');
    } catch (error) {
      console.log('   ✅ PASSED: Over-capacity blocked');
    }
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

addInventoryConstraints();
