// Run financial constraints migration
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function addFinancialConstraints() {
  try {
    console.log('💰 Adding financial constraints...\n');
    
    const migrationSQL = fs.readFileSync(
      path.join(__dirname, '../migrations/add_financial_constraints.sql'),
      'utf8'
    );
    
    await pool.query(migrationSQL);
    
    console.log('✅ Constraints added successfully!\n');
    
    // Verify payments
    console.log('📋 Testing payments table:');
    try {
      await pool.query(`INSERT INTO payments (payer_id, amount, payment_method) VALUES (1, 0, 'cash')`);
      console.log('   ❌ FAILED: Zero payment allowed');
    } catch (error) {
      console.log('   ✅ PASSED: Zero payment blocked');
    }
    
    try {
      await pool.query(`INSERT INTO payments (payer_id, amount, payment_method) VALUES (1, -50, 'cash')`);
      console.log('   ❌ FAILED: Negative payment allowed');
    } catch (error) {
      console.log('   ✅ PASSED: Negative payment blocked');
    }
    
    // Verify expenses
    console.log('\n📋 Testing expenses table:');
    try {
      await pool.query(`INSERT INTO expenses (worker_id, amount, description, expense_date, payment_method) VALUES (1, 0, 'test', CURRENT_DATE, 'worker_pocket')`);
      console.log('   ❌ FAILED: Zero expense allowed');
    } catch (error) {
      console.log('   ✅ PASSED: Zero expense blocked');
    }
    
    try {
      await pool.query(`INSERT INTO expenses (worker_id, amount, description, expense_date, payment_method) VALUES (1, -50, 'test', CURRENT_DATE, 'worker_pocket')`);
      console.log('   ❌ FAILED: Negative expense allowed');
    } catch (error) {
      console.log('   ✅ PASSED: Negative expense blocked');
    }
    
    // List all financial constraints
    const constraints = await pool.query(`
      SELECT 
        t.tablename,
        c.conname as constraint_name,
        pg_get_constraintdef(c.oid) as definition
      FROM pg_constraint c
      JOIN pg_class cl ON c.conrelid = cl.oid
      JOIN pg_tables t ON cl.relname = t.tablename
      WHERE t.schemaname = 'public'
      AND (c.conname LIKE '%amount%' OR c.conname LIKE '%price%')
      AND c.contype = 'c'
      ORDER BY t.tablename, c.conname
    `);
    
    console.log('\n📊 Active financial constraints:');
    constraints.rows.forEach(row => {
      console.log(`\n   ${row.tablename}.${row.constraint_name}`);
      console.log(`   ${row.definition}`);
    });
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

addFinancialConstraints();
