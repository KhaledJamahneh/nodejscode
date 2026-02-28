// scripts/seed-test-data.js
// Create test data for development

require('dotenv').config();
const bcrypt = require('bcrypt');
const { query } = require('../src/config/database');
const logger = require('../src/utils/logger');

async function seedTestData() {
  console.log('🌱 Seeding test data...\n');

  try {
    // Create test client user
    console.log('1. Creating test client user...');
    const password = 'Client123!';
    const passwordHash = await bcrypt.hash(password, 12);

    const userResult = await query(
      `INSERT INTO users (username, email, phone_number, password_hash, role)
       VALUES ($1, $2, $3, $4, $5::text[]::user_role[])
       ON CONFLICT (username) DO UPDATE SET password_hash = $4
       RETURNING id`,
      ['testclient', 'client@test.com', '+1234567891', passwordHash, ['client']]
    );

    const userId = userResult.rows[0].id;
    console.log('✅ Test client user created (ID:', userId + ')');
    console.log('   Username: testclient');
    console.log('   Password: Client123!');

    // Create client profile
    console.log('\n2. Creating client profile...');
    const profileResult = await query(
      `INSERT INTO client_profiles (
        user_id, full_name, address, latitude, longitude,
        subscription_type, subscription_start_date, subscription_end_date,
        subscription_expiry_date, remaining_coupons, monthly_usage_gallons,
        current_debt
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       ON CONFLICT (user_id) DO UPDATE SET
        full_name = $2,
        address = $3,
        subscription_expiry_date = $9,
        remaining_coupons = $10
       RETURNING id`,
      [
        userId,
        'John Doe',
        '123 Main Street, City Center, Apartment 4B',
        31.9522,  // Example latitude (Amman, Jordan)
        35.9332,  // Example longitude
        'coupon_book',
        new Date('2024-01-01'),
        new Date('2024-12-31'),
        new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
        85,  // remaining coupons
        450.50,  // monthly usage
        0  // no debt
      ]
    );

    const profileId = profileResult.rows[0].id;
    console.log('✅ Client profile created (ID:', profileId + ')');

    // Create a worker for deliveries
    console.log('\n3. Creating test delivery worker...');
    const workerPasswordHash = await bcrypt.hash('Worker123!', 12);
    
    const workerUserResult = await query(
      `INSERT INTO users (username, email, phone_number, password_hash, role)
       VALUES ($1, $2, $3, $4, $5::text[]::user_role[])
       ON CONFLICT (username) DO UPDATE SET password_hash = $4
       RETURNING id`,
      ['testworker', 'worker@test.com', '+1234567892', workerPasswordHash, ['delivery_worker']]
    );

    const workerUserId = workerUserResult.rows[0].id;

    await query(
      `INSERT INTO worker_profiles (
        user_id, full_name, worker_type, hire_date, current_salary,
        vehicle_current_gallons
      ) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id) DO UPDATE SET full_name = $2
       RETURNING id`,
      [workerUserId, 'Ahmed Ali', 'delivery', new Date('2023-01-15'), 2000, 50]
    );

    console.log('✅ Test worker created');
    console.log('   Username: testworker');
    console.log('   Password: Worker123!');

    // Create some delivery history
    console.log('\n4. Creating delivery history...');
    
    const workerProfile = await query(
      'SELECT id FROM worker_profiles WHERE user_id = $1',
      [workerUserId]
    );
    const workerProfileId = workerProfile.rows[0].id;

    // Create 5 completed deliveries (past)
    for (let i = 0; i < 5; i++) {
      const daysAgo = (i + 1) * 7; // Weekly deliveries
      const deliveryDate = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
      
      await query(
        `INSERT INTO deliveries (
          client_id, worker_id, delivery_date, actual_delivery_time,
          gallons_delivered, status, delivery_latitude, delivery_longitude, is_main_list
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          profileId,
          workerProfileId,
          deliveryDate,
          deliveryDate,
          20, // 20 gallons each delivery
          'completed',
          31.9522,
          35.9332,
          true
        ]
      );
    }

    console.log('✅ Created 5 completed delivery records');

    // Create 3 scheduled deliveries for today (pending)
    console.log('\n5. Creating scheduled deliveries for today...');
    
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];
    
    const scheduledTimes = ['09:00:00', '14:00:00', '16:30:00'];
    
    for (let i = 0; i < 3; i++) {
      await query(
        `INSERT INTO deliveries (
          client_id, worker_id, delivery_date, scheduled_time,
          gallons_delivered, status, is_main_list
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          profileId,
          workerProfileId,
          todayStr,
          scheduledTimes[i],
          20,
          'pending',
          true
        ]
      );
    }

    console.log('✅ Created 3 scheduled deliveries for today');

    // Create a dispenser asset
    console.log('\n6. Creating dispenser asset...');
    
    const dispenserResult = await query(
      `INSERT INTO dispensers (
        serial_number, dispenser_type, status, purchase_date,
        current_location_type, current_client_id
      ) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (serial_number) DO UPDATE SET current_client_id = $6
       RETURNING id`,
      ['DSP-2024-001', 'touch', 'used', new Date('2024-01-15'), 'client', profileId]
    );

    const dispenserId = dispenserResult.rows[0].id;

    await query(
      `INSERT INTO client_assets (
        client_id, dispenser_id, asset_type, quantity, assigned_date
      ) VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT DO NOTHING`,
      [profileId, dispenserId, 'dispenser', 1, new Date('2024-01-15')]
    );

    console.log('✅ Created dispenser asset');

    // Create some payment history
    console.log('\n7. Creating payment history...');
    
    await query(
      `INSERT INTO payments (
        payer_id, amount, payment_method, payment_status,
        payment_date, description
      ) VALUES ($1, $2, $3, $4, $5, $6)`,
      [userId, 150.00, 'cash', 'completed', new Date(Date.now() - 15 * 24 * 60 * 60 * 1000), 'Subscription renewal']
    );

    await query(
      `INSERT INTO payments (
        payer_id, amount, payment_method, payment_status,
        payment_date, description
      ) VALUES ($1, $2, $3, $4, $5, $6)`,
      [userId, 200.00, 'credit_card', 'completed', new Date(Date.now() - 45 * 24 * 60 * 60 * 1000), 'Coupon book purchase']
    );

    console.log('✅ Created payment records');

    // Create a filling station for onsite worker
    console.log('\n8. Creating filling station...');
    await query(
      `INSERT INTO filling_stations (name, address, current_status, manager_id)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT DO NOTHING`,
      ['Main Processing Station', 'Industrial Zone, Block 7', 'open', 4]
    );
    console.log('✅ Created filling station');

    console.log('\n✨ Test data seeding complete!\n');
    console.log('═══════════════════════════════════════');
    console.log('TEST ACCOUNTS:');
    console.log('═══════════════════════════════════════');
    console.log('Owner:');
    console.log('  Username: owner');
    console.log('  Password: Admin123!');
    console.log('  Role: owner\n');
    console.log('Client:');
    console.log('  Username: testclient');
    console.log('  Password: Client123!');
    console.log('  Role: client\n');
    console.log('Worker:');
    console.log('  Username: testworker');
    console.log('  Password: Worker123!');
    console.log('  Role: delivery_worker\n');
    console.log('On-site Worker:');
    console.log('  Username: khaled');
    console.log('  Password: Admin123!');
    console.log('  Role: onsite_worker, administrator');
    console.log('═══════════════════════════════════════\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding data:', error);
    process.exit(1);
  }
}

seedTestData();
