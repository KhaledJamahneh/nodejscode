// Check payment constraints
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkPaymentConstraints() {
  try {
    // Check constraints on payments table
    const constraints = await pool.query(`
      SELECT 
        conname as constraint_name,
        pg_get_constraintdef(oid) as definition
      FROM pg_constraint
      WHERE conrelid = 'payments'::regclass
      AND conname LIKE '%amount%'
    `);
    
    console.log('\n=== Constraints on payments.amount ===\n');
    if (constraints.rows.length === 0) {
      console.log('❌ No constraints found on amount column');
    } else {
      constraints.rows.forEach(row => {
        console.log(`${row.constraint_name}:`);
        console.log(`  ${row.definition}\n`);
      });
    }
    
    // Test zero payment
    console.log('🧪 Testing zero payment...');
    try {
      await pool.query(`
        INSERT INTO payments (payer_id, amount, payment_method, payment_status)
        VALUES (1, 0.00, 'cash', 'completed')
      `);
      console.log('   ⚠️  WARNING: Zero payment allowed!');
      await pool.query('DELETE FROM payments WHERE amount = 0.00');
    } catch (error) {
      console.log('   ✅ PASSED: Zero payment blocked');
    }
    
    // Test negative payment
    console.log('\n🧪 Testing negative payment...');
    try {
      await pool.query(`
        INSERT INTO payments (payer_id, amount, payment_method, payment_status)
        VALUES (1, -100.00, 'cash', 'completed')
      `);
      console.log('   ⚠️  WARNING: Negative payment allowed!');
      await pool.query('DELETE FROM payments WHERE amount < 0');
    } catch (error) {
      console.log('   ✅ PASSED: Negative payment blocked');
    }
    
    // Check expenses table too
    const expenseConstraints = await pool.query(`
      SELECT 
        conname as constraint_name,
        pg_get_constraintdef(oid) as definition
      FROM pg_constraint
      WHERE conrelid = 'expenses'::regclass
      AND conname LIKE '%amount%'
    `);
    
    console.log('\n=== Constraints on expenses.amount ===\n');
    if (expenseConstraints.rows.length === 0) {
      console.log('❌ No constraints found on amount column');
    } else {
      expenseConstraints.rows.forEach(row => {
        console.log(`${row.constraint_name}:`);
        console.log(`  ${row.definition}\n`);
      });
    }
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkPaymentConstraints();
