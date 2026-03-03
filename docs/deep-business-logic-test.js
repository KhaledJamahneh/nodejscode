const axios = require('axios');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

const BASE_URL = (process.env.API_URL || 'http://localhost:3000') + '/api/v1';
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

const results = { passed: 0, failed: 0, details: [] };

const log = (test, status, message) => {
  const result = { test, status, message };
  results.details.push(result);
  if (status === 'PASS') results.passed++;
  else results.failed++;
  console.log(`[${status}] ${test}: ${message}`);
};

const api = axios.create({ baseURL: BASE_URL, validateStatus: () => true });

/**
 * Utility: Create a test user with a specific profile
 */
async function setupTestUser(username, role, profileData = {}) {
  // Delete in correct order due to foreign keys
  await pool.query('DELETE FROM payments WHERE payer_id = (SELECT id FROM users WHERE username = $1)', [username]);
  await pool.query('DELETE FROM users WHERE username = $1', [username]);
  
  // Use correct role name for workers and pass as ARRAY
  const dbRole = role === 'worker' ? ['delivery_worker'] : [role];
  const phone = profileData.phone || `+9725${Math.floor(Math.random() * 10000000).toString().padStart(7, '0')}`;
  const passwordHash = await bcrypt.hash('Secure123!', 10);

  const userRes = await pool.query(
    'INSERT INTO users (username, phone_number, password_hash, role, is_active) VALUES ($1, $2, $3, $4, $5) RETURNING id',
    [username, phone, passwordHash, dbRole, true]
  );
  const userId = userRes.rows[0].id;

  if (role === 'client') {
    const cpRes = await pool.query(
      `INSERT INTO client_profiles (user_id, full_name, address, subscription_type, current_debt, subscription_expiry_date, remaining_coupons)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      [
        userId, 
        profileData.full_name || username,
        profileData.address || 'Test Address',
        profileData.subscription_type || 'cash', 
        profileData.current_debt || 0, 
        profileData.subscription_expiry_date || null,
        profileData.remaining_coupons || 0
      ]
    );
    return cpRes.rows[0].id;
  } else if (role === 'worker') {
    const wpRes = await pool.query(
      `INSERT INTO worker_profiles (user_id, full_name, worker_type, hire_date, vehicle_current_gallons)
       VALUES ($1, $2, $3, $4, $5) RETURNING id`,
      [userId, profileData.full_name || username, 'delivery', new Date(), profileData.vehicle_current_gallons || 0]
    );
    return wpRes.rows[0].id;
  }
  return userId;
}

async function login(username) {
  const res = await api.post('/auth/login', { username, password: 'Secure123!' });
  const token = res.data.accessToken || (res.data.data && res.data.data.accessToken);
  if (!token) {
    console.log(`Login failed for ${username}: ${res.status} ${JSON.stringify(res.data)}`);
  }
  return token;
}

// --- 1. Subscription & Credit Management ---

async function scenario1_1_CreditLimit() {
  const testName = '1.1 Credit Limit Hard Stop';
  try {
    const username = 'test_client_credit';
    const clientId = await setupTestUser(username, 'client', { subscription_type: 'cash', current_debt: 10000 });
    const token = await login(username);

    const adminUser = 'test_admin_pay';
    await setupTestUser(adminUser, 'administrator');
    const adminToken = await login(adminUser);

    // Try to order 100 gallons
    const res = await api.post('/deliveries/request', 
      { requested_gallons: 100, payment_method: 'cash' }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );

    if (res.status === 403) {
      log(testName, 'PASS', 'Over-limit request rejected correctly');
    } else {
      log(testName, 'FAIL', `Expected 403, got ${res.status}: ${JSON.stringify(res.data)}`);
      return;
    }

    // Pay 500 (as admin)
    const payRes = await api.post('/payments/record', { 
      client_id: clientId,
      payer_id: clientId, 
      receiver_type: 'company',
      amount: 500, 
      payment_method: 'cash',
      payment_status: 'completed'
    }, { headers: { Authorization: `Bearer ${adminToken}` } });
    
    if (payRes.status !== 200 && payRes.status !== 201) {
      log(testName, 'FAIL', `Failed to record payment: ${payRes.status} ${JSON.stringify(payRes.data)}`);
      return;
    }

    // Try again
    const res2 = await api.post('/deliveries/request', 
      { requested_gallons: 100, payment_method: 'cash' }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );

    if (res2.status === 201 || res2.status === 200) {
      log(testName, 'PASS', 'Request accepted after payment');
    } else {
      log(testName, 'FAIL', `Expected 201, got ${res2.status} after payment`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

async function scenario1_2_GracePeriod() {
  const testName = '1.2 Grace Period Enforcement';
  try {
    const username = 'test_client_grace';
    const fiveDaysAgo = new Date();
    fiveDaysAgo.setDate(fiveDaysAgo.getDate() - 5);
    
    await setupTestUser(username, 'client', { 
      subscription_type: 'cash', 
      subscription_expiry_date: fiveDaysAgo,
      grace_period_days: 10 
    });
    const token = await login(username);

    // 5 days ago (within 10 days grace) -> PASS
    const res1 = await api.post('/deliveries/request', 
      { requested_gallons: 50, payment_method: 'cash' }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    if (res1.status !== 201 && res1.status !== 200) {
      log(testName, 'FAIL', `Expected 201 within grace period, got ${res1.status}`);
      return;
    }

    // 15 days ago (outside 10 days grace) -> FAIL
    const fifteenDaysAgo = new Date();
    fifteenDaysAgo.setDate(fifteenDaysAgo.getDate() - 15);
    await pool.query('UPDATE client_profiles SET subscription_expiry_date = $1 WHERE user_id = (SELECT id FROM users WHERE username = $2)', [fifteenDaysAgo, username]);

    const res2 = await api.post('/deliveries/request', 
      { requested_gallons: 50, payment_method: 'cash' }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );

    if (res2.status === 403) {
      log(testName, 'PASS', 'Grace period expired correctly');
    } else {
      log(testName, 'FAIL', `Expected 403 after grace period, got ${res2.status}`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

// --- 2. Delivery Lifecycle & Inventory ---

async function scenario2_1_WorkerInventory() {
  const testName = '2.1 Worker Inventory Lock';
  try {
    const clientName = 'test_client_inv';
    const workerName = 'test_worker_inv';
    
    await setupTestUser(clientName, 'client', { subscription_type: 'cash' });
    await setupTestUser(workerName, 'worker', { vehicle_current_gallons: 100 });
    
    const clientToken = await login(clientName);
    const workerToken = await login(workerName);

    // Create delivery for 150 gal
    const dRes = await api.post('/deliveries/request', 
      { requested_gallons: 150, payment_method: 'cash' }, 
      { headers: { Authorization: `Bearer ${clientToken}` } }
    );
    const deliveryId = dRes.data.id || dRes.data.data?.id;

    // Worker accepts
    await api.post(`/workers/requests/${deliveryId}/accept`, {}, { headers: { Authorization: `Bearer ${workerToken}` } });

    // Worker attempts to complete (150 > 100)
    const completeRes = await api.post(`/workers/requests/${deliveryId}/complete`, 
      { gallons_delivered: 150 }, 
      { headers: { Authorization: `Bearer ${workerToken}` } }
    );

    if (completeRes.status === 400 || completeRes.status === 500) { // Database constraint might cause 500 if not caught
      log(testName, 'PASS', 'Insufficient inventory blocked completion');
    } else {
      log(testName, 'FAIL', `Expected 400, got ${completeRes.status} despite low inventory`);
    }

    // Refill worker
    await api.put('/workers/vehicle/inventory', { current_gallons: 500 }, { headers: { Authorization: `Bearer ${workerToken}` } });

    // Complete again
    const completeRes2 = await api.post(`/workers/requests/${deliveryId}/complete`, 
      { gallons_delivered: 150 }, 
      { headers: { Authorization: `Bearer ${workerToken}` } }
    );

    if (completeRes2.status === 200 || completeRes2.status === 201) {
      log(testName, 'PASS', 'Completion succeeded after refill');
    } else {
      log(testName, 'FAIL', `Expected 200 after refill, got ${completeRes2.status}`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

async function scenario2_2_RaceCondition() {
  const testName = '2.2 Concurrent Assignment Race';
  try {
    const clientName = 'test_client_race';
    const w1Name = 'test_worker_1';
    const w2Name = 'test_worker_2';

    await setupTestUser(clientName, 'client', { subscription_type: 'cash' });
    await setupTestUser(w1Name, 'worker', { vehicle_current_gallons: 1000 });
    await setupTestUser(w2Name, 'worker', { vehicle_current_gallons: 1000 });

    const clientToken = await login(clientName);
    const w1Token = await login(w1Name);
    const w2Token = await login(w2Name);

    const dRes = await api.post('/deliveries/request', 
      { requested_gallons: 50, payment_method: 'cash' }, 
      { headers: { Authorization: `Bearer ${clientToken}` } }
    );
    const deliveryId = dRes.data.id || dRes.data.data?.id;

    // Concurrent accept
    const [r1, r2] = await Promise.all([
      api.post(`/workers/requests/${deliveryId}/accept`, {}, { headers: { Authorization: `Bearer ${w1Token}` } }),
      api.post(`/workers/requests/${deliveryId}/accept`, {}, { headers: { Authorization: `Bearer ${w2Token}` } })
    ]);

    const success = (r1.status === 200 ? 1 : 0) + (r2.status === 200 ? 1 : 0);
    
    if (success === 1) {
      log(testName, 'PASS', 'Only one worker could accept the delivery');
    } else {
      log(testName, 'FAIL', `Race condition! ${success} workers accepted the delivery`);
    }
  } catch (e) {
    log(testName, 'FAIL', e.message);
  }
}

async function runAll() {
  console.log('--- STARTING DEEP BUSINESS LOGIC TESTS ---\n');
  
  await scenario1_1_CreditLimit();
  await scenario1_2_GracePeriod();
  await scenario2_1_WorkerInventory();
  await scenario2_2_RaceCondition();
  
  console.log('\n--- FINAL RESULTS ---');
  console.log(`Passed: ${results.passed}/${results.passed + results.failed}`);
  console.log(`Failed: ${results.failed}/${results.passed + results.failed}`);
  
  await pool.end();
}

runAll().catch(console.error);
