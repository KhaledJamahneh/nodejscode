// debug-client-profile.js
// Debug and fix client profile issues

require('dotenv').config();
const { query } = require('./src/config/database');

async function debugClientProfile() {
  console.log('=== CLIENT PROFILE DEBUG ===\n');

  try {
    // Get the token payload to find user ID
    // Since we can't decode the token here, let's check all client users
    
    console.log('1. Checking all client users...\n');
    
    const clientUsers = await query(
      `SELECT u.id, u.username, u.role, 
              cp.id as profile_id, cp.full_name
       FROM users u
       LEFT JOIN client_profiles cp ON u.id = cp.user_id
       WHERE u.role = 'client'`
    );

    if (clientUsers.rows.length === 0) {
      console.log('❌ No client users found in database!');
      console.log('\nRun this command to create test data:');
      console.log('node scripts/seed-test-data.js');
      process.exit(1);
    }

    console.log('Found', clientUsers.rows.length, 'client user(s):\n');

    for (const user of clientUsers.rows) {
      console.log(`User ID: ${user.id}`);
      console.log(`Username: ${user.username}`);
      console.log(`Role: ${user.role}`);
      
      if (user.profile_id) {
        console.log(`✅ Profile exists (ID: ${user.profile_id}, Name: ${user.full_name})`);
      } else {
        console.log(`❌ NO PROFILE - Creating one now...`);
        
        // Create missing profile
        await query(
          `INSERT INTO client_profiles (
            user_id, full_name, address, latitude, longitude,
            subscription_type, subscription_start_date, 
            subscription_end_date, subscription_expiry_date,
            remaining_coupons, monthly_usage_gallons, current_debt
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
          [
            user.id,
            'Client User',
            'Default Address - Please Update',
            31.9522,
            35.9332,
            'coupon_book',
            new Date(),
            new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year from now
            new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
            100,
            0,
            0
          ]
        );
        
        console.log(`✅ Profile created for user ${user.username}`);
      }
      console.log('---\n');
    }

    console.log('\n2. Verifying profiles...\n');
    
    const verification = await query(
      `SELECT u.username, cp.full_name, cp.subscription_type, cp.remaining_coupons
       FROM users u
       JOIN client_profiles cp ON u.id = cp.user_id
       WHERE u.role = 'client'`
    );

    console.log('✅ All client profiles verified:');
    verification.rows.forEach(row => {
      console.log(`   - ${row.username}: ${row.full_name} (${row.subscription_type}, ${row.remaining_coupons} coupons)`);
    });

    console.log('\n✅ All client users now have profiles!');
    console.log('\nYou can now test the GET /api/v1/clients/profile endpoint');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  process.exit(0);
}

debugClientProfile();
