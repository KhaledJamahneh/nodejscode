// Seed historical data to make app look used for a long time
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'einhod_water',
  password: process.env.DB_PASSWORD || 'postgres',
  port: process.env.DB_PORT || 5432,
});

async function seedHistoricalData() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('🌱 Seeding historical data...');
    
    // Get existing users
    const { rows: clients } = await client.query(
      "SELECT cp.id as profile_id, u.id as user_id, cp.full_name FROM client_profiles cp JOIN users u ON cp.user_id = u.id WHERE 'client' = ANY(u.role)"
    );
    
    const { rows: workers } = await client.query(
      "SELECT wp.id as profile_id, u.id as user_id, wp.full_name FROM worker_profiles wp JOIN users u ON wp.user_id = u.id WHERE 'delivery_worker' = ANY(u.role)"
    );
    
    console.log(`Found ${clients.length} clients and ${workers.length} workers`);
    
    // Create historical deliveries (last 6 months)
    console.log('Creating historical deliveries...');
    let deliveryCount = 0;
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - 6);
    
    for (let i = 0; i < 500; i++) {
      const clientData = clients[Math.floor(Math.random() * clients.length)];
      const worker = workers[Math.floor(Math.random() * workers.length)];
      
      const deliveryDate = new Date(startDate.getTime() + Math.random() * (Date.now() - startDate.getTime()));
      const gallons = [50, 100, 150, 200][Math.floor(Math.random() * 4)];
      const status = Math.random() > 0.1 ? 'completed' : 'cancelled';
      
      await client.query(
        `INSERT INTO deliveries (client_id, worker_id, delivery_date, scheduled_time, gallons_delivered, status)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [clientData.profile_id, worker.profile_id, deliveryDate.toISOString().split('T')[0], 
         `${Math.floor(Math.random() * 12 + 8)}:00:00`, gallons, status]
      );
      deliveryCount++;
    }
    console.log(`✅ Created ${deliveryCount} historical deliveries`);
    
    // Create historical requests
    console.log('Creating historical requests...');
    let requestCount = 0;
    
    for (let i = 0; i < 300; i++) {
      const clientData = clients[Math.floor(Math.random() * clients.length)];
      const worker = workers[Math.floor(Math.random() * workers.length)];
      
      const requestDate = new Date(startDate.getTime() + Math.random() * (Date.now() - startDate.getTime()));
      const gallons = [50, 100, 150, 200][Math.floor(Math.random() * 4)];
      const status = ['completed', 'completed', 'completed', 'cancelled'][Math.floor(Math.random() * 4)];
      
      await client.query(
        `INSERT INTO delivery_requests (client_id, requested_gallons, status, priority, assigned_worker_id, created_at)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [clientData.profile_id, gallons, status, Math.random() > 0.8 ? 'urgent' : 'non_urgent',
         status === 'completed' ? worker.profile_id : null, requestDate]
      );
      requestCount++;
    }
    console.log(`✅ Created ${requestCount} historical requests`);
    
    // Create historical payments
    console.log('Creating historical payments...');
    let paymentCount = 0;
    
    for (let i = 0; i < 400; i++) {
      const clientData = clients[Math.floor(Math.random() * clients.length)];
      const paymentDate = new Date(startDate.getTime() + Math.random() * (Date.now() - startDate.getTime()));
      const amount = Math.floor(Math.random() * 500 + 100);
      
      await client.query(
        `INSERT INTO payments (payer_id, amount, payment_method, payment_status, payment_date)
         VALUES ($1, $2, $3, $4, $5)`,
        [clientData.user_id, amount, Math.random() > 0.5 ? 'cash' : 'bank_transfer', 'completed', paymentDate]
      );
      paymentCount++;
    }
    console.log(`✅ Created ${paymentCount} historical payments`);
    
    // Create historical expenses
    console.log('Creating historical expenses...');
    let expenseCount = 0;
    
    const expenseCategories = ['fuel', 'maintenance', 'salary', 'supplies', 'utilities'];
    
    for (let i = 0; i < 200; i++) {
      const workerData = workers[Math.floor(Math.random() * workers.length)];
      const expenseDate = new Date(startDate.getTime() + Math.random() * (Date.now() - startDate.getTime()));
      const amount = Math.floor(Math.random() * 300 + 50);
      const category = expenseCategories[Math.floor(Math.random() * expenseCategories.length)];
      
      await client.query(
        `INSERT INTO expenses (worker_id, amount, description, expense_date, payment_method)
         VALUES ($1, $2, $3, $4, $5)`,
        [workerData.profile_id, amount, `${category} expense`, expenseDate, Math.random() > 0.5 ? 'worker_pocket' : 'company_pocket']
      );
      expenseCount++;
    }
    console.log(`✅ Created ${expenseCount} historical expenses`);
    
    // Update client debts randomly
    console.log('Updating client debts...');
    for (const clientData of clients.slice(0, 30)) {
      const debt = Math.floor(Math.random() * 500);
      await client.query(
        'UPDATE client_profiles SET current_debt = $1 WHERE user_id = $2',
        [debt, clientData.user_id]
      );
    }
    console.log(`✅ Updated debts for 30 clients`);
    
    // Update worker advances randomly
    console.log('Updating worker advances...');
    for (const workerData of workers.slice(0, 20)) {
      const advance = Math.floor(Math.random() * 300);
      await client.query(
        'UPDATE worker_profiles SET debt_advances = $1 WHERE user_id = $2',
        [advance, workerData.user_id]
      );
    }
    console.log(`✅ Updated advances for 20 workers`);
    
    await client.query('COMMIT');
    
    console.log('\n✨ Historical data seeding completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - ${deliveryCount} deliveries`);
    console.log(`   - ${requestCount} requests`);
    console.log(`   - ${paymentCount} payments`);
    console.log(`   - ${expenseCount} expenses`);
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error seeding historical data:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

seedHistoricalData().catch(console.error);
