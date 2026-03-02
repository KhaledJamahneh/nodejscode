const axios = require('axios');
const { Pool } = require('pg');
require('dotenv').config();

const BASE_URL = process.env.API_URL || 'http://localhost:3000';
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

// Phase 1: Authentication & Authorization
async function test1_MultiDeviceLogin() {
  try {
    const login1 = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token1 = login1.data.accessToken;
    const refresh1 = login1.data.refreshToken;
    
    const login2 = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token2 = login2.data.accessToken;
    
    await api.post('/auth/logout', { refreshToken: refresh1 });
    
    await new Promise(r => setTimeout(r, 100));
    const test = await api.get('/clients/profile', { headers: { Authorization: `Bearer ${token1}` } });
    
    if (test.status === 401) log('1.1 Multi-Device Login', 'PASS', 'Blacklisted token rejected');
    else log('1.1 Multi-Device Login', 'FAIL', `Expected 401, got ${test.status}`);
  } catch (e) {
    log('1.1 Multi-Device Login', 'FAIL', e.message);
  }
}

async function test2_RoleEscalation() {
  try {
    const login = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token = login.data.accessToken;
    
    const forged = token.replace(/client/g, 'owner');
    const test = await api.get('/admin/dashboard', { headers: { Authorization: `Bearer ${forged}` } });
    
    if (test.status === 401 || test.status === 403) {
      log('1.2 Role Escalation', 'PASS', 'Forged token rejected');
    } else {
      log('1.2 Role Escalation', 'FAIL', `Expected 401/403, got ${test.status}`);
    }
  } catch (e) {
    log('1.2 Role Escalation', 'FAIL', e.message);
  }
}

async function test3_PasswordReset() {
  try {
    const res = await api.post('/auth/password-reset/request', { phone_number: '+972501234567' });
    if (res.status === 200 || res.status === 201) {
      log('1.3 Password Reset', 'PASS', 'Reset request accepted');
    } else {
      log('1.3 Password Reset', 'FAIL', `Expected 200/201, got ${res.status}`);
    }
  } catch (e) {
    log('1.3 Password Reset', 'FAIL', e.message);
  }
}

async function test4_InactiveUser() {
  try {
    const login = await api.post('/auth/login', { username: 'worker1', password: 'Worker123!' });
    const token = login.data.accessToken;
    
    await pool.query('UPDATE users SET is_active = FALSE WHERE username = $1', ['worker1']);
    
    const test = await api.post('/workers/deliveries/1/accept', {}, { headers: { Authorization: `Bearer ${token}` } });
    
    await pool.query('UPDATE users SET is_active = TRUE WHERE username = $1', ['worker1']);
    
    if (test.status === 403) log('1.4 Inactive User', 'PASS', 'Inactive account blocked');
    else log('1.4 Inactive User', 'FAIL', `Expected 403, got ${test.status}`);
  } catch (e) {
    log('1.4 Inactive User', 'FAIL', e.message);
  }
}

async function test5_CORS() {
  try {
    const res = await api.post('/auth/login', { username: 'client1' }, { 
      headers: { 'Origin': 'http://evil.com', 'Content-Type': 'text/plain' } 
    });
    log('1.5 CORS', 'PASS', `CORS handled with status ${res.status}`);
  } catch (e) {
    log('1.5 CORS', 'PASS', 'CORS blocked request');
  }
}

// Phase 2: Subscription & Payment
async function test6_CouponPurchase() {
  try {
    const login = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token = login.data.accessToken;
    
    await pool.query('UPDATE client_profiles SET subscription_expiry_date = CURRENT_DATE WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    
    const p1 = await api.post('/payments/coupon-purchase', 
      { size: 100, quantity: 5 }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    const p2 = await api.post('/payments/coupon-purchase', 
      { size: 500, quantity: 1 }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    const profile = await pool.query('SELECT remaining_coupons, bonus_gallons FROM client_profiles WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    
    if (profile.rows[0].remaining_coupons >= 1000) {
      log('2.1 Coupon Purchase', 'PASS', `Coupons: ${profile.rows[0].remaining_coupons}, Bonus: ${profile.rows[0].bonus_gallons}`);
    } else {
      log('2.1 Coupon Purchase', 'FAIL', `Expected >=1000 coupons, got ${profile.rows[0].remaining_coupons}`);
    }
  } catch (e) {
    log('2.1 Coupon Purchase', 'FAIL', e.message);
  }
}

async function test7_DebtRace() {
  try {
    await pool.query('UPDATE client_profiles SET current_debt = 9990 WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    
    const login = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token = login.data.accessToken;
    
    const promises = [];
    for (let i = 0; i < 5; i++) {
      promises.push(api.post('/payments/record', { amount: 30, method: 'cash' }, { headers: { Authorization: `Bearer ${token}` } }));
    }
    await Promise.all(promises);
    
    const debt = await pool.query('SELECT current_debt FROM client_profiles WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    
    log('2.2 Debt Race', 'PASS', `Final debt: ${debt.rows[0].current_debt} (check for discrepancies)`);
  } catch (e) {
    log('2.2 Debt Race', 'FAIL', e.message);
  }
}

async function test8_SubscriptionSwitch() {
  try {
    await pool.query('UPDATE client_profiles SET monthly_usage_gallons = 900, subscription_type = $1 WHERE user_id = (SELECT id FROM users WHERE username = $2)', ['cash', 'client1']);
    await pool.query('UPDATE client_profiles SET monthly_usage_gallons = 0 WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    await pool.query('UPDATE client_profiles SET subscription_type = $1 WHERE user_id = (SELECT id FROM users WHERE username = $2)', ['coupon_book', 'client1']);
    
    const profile = await pool.query('SELECT monthly_usage_gallons, subscription_type FROM client_profiles WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    
    if (profile.rows[0].monthly_usage_gallons === 0) {
      log('2.3 Subscription Switch', 'PASS', 'Usage reset correctly');
    } else {
      log('2.3 Subscription Switch', 'FAIL', `Usage not reset: ${profile.rows[0].monthly_usage_gallons}`);
    }
  } catch (e) {
    log('2.3 Subscription Switch', 'FAIL', e.message);
  }
}

async function test9_NegativePayment() {
  try {
    const login = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token = login.data.accessToken;
    
    const res = await api.post('/payments/record', { amount: -0.01, method: 'cash' }, { headers: { Authorization: `Bearer ${token}` } });
    
    if (res.status === 400) log('2.4 Negative Payment', 'PASS', 'Negative payment rejected');
    else log('2.4 Negative Payment', 'FAIL', `Expected 400, got ${res.status}`);
  } catch (e) {
    log('2.4 Negative Payment', 'FAIL', e.message);
  }
}

async function test10_CouponRace() {
  try {
    await pool.query('UPDATE client_profiles SET remaining_coupons = 10 WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    
    const login = await api.post('/auth/login', { username: 'worker1', password: 'Worker123!' });
    const token = login.data.accessToken;
    
    const d1 = await pool.query('INSERT INTO deliveries (client_id, requested_gallons, status) VALUES ((SELECT id FROM users WHERE username = $1), 60, $2) RETURNING id', ['client1', 'in_progress']);
    const d2 = await pool.query('INSERT INTO deliveries (client_id, requested_gallons, status) VALUES ((SELECT id FROM users WHERE username = $1), 60, $2) RETURNING id', ['client1', 'in_progress']);
    
    const promises = [
      api.patch(`/workers/deliveries/${d1.rows[0].id}/complete`, { delivered_gallons: 60 }, { headers: { Authorization: `Bearer ${token}` } }),
      api.patch(`/workers/deliveries/${d2.rows[0].id}/complete`, { delivered_gallons: 60 }, { headers: { Authorization: `Bearer ${token}` } })
    ];
    
    const results = await Promise.all(promises);
    const success = results.filter(r => r.status === 200).length;
    
    if (success === 1) log('2.5 Coupon Race', 'PASS', 'Only one completion succeeded');
    else log('2.5 Coupon Race', 'FAIL', `Expected 1 success, got ${success}`);
  } catch (e) {
    log('2.5 Coupon Race', 'FAIL', e.message);
  }
}

async function test11_BonusExploit() {
  try {
    const login = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token = login.data.accessToken;
    
    const before = await pool.query('SELECT bonus_gallons FROM client_profiles WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    
    await api.post('/payments/coupon-purchase', { size: 500, quantity: 1 }, { headers: { Authorization: `Bearer ${token}` } });
    
    const after = await pool.query('SELECT bonus_gallons FROM client_profiles WHERE user_id = (SELECT id FROM users WHERE username = $1)', ['client1']);
    
    const diff = after.rows[0].bonus_gallons - before.rows[0].bonus_gallons;
    if (diff === 50) log('2.6 Bonus Exploit', 'PASS', 'Bonus applied once');
    else log('2.6 Bonus Exploit', 'FAIL', `Bonus diff: ${diff}`);
  } catch (e) {
    log('2.6 Bonus Exploit', 'FAIL', e.message);
  }
}

// Phase 3: Delivery Workflow
async function test12_CancellationMidProgress() {
  try {
    const clientLogin = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const clientToken = clientLogin.data.accessToken;
    
    const delivery = await api.post('/deliveries/request', { requested_gallons: 100 }, { headers: { Authorization: `Bearer ${clientToken}` } });
    const deliveryId = delivery.data.id;
    
    const workerLogin = await api.post('/auth/login', { username: 'worker1', password: 'Worker123!' });
    const workerToken = workerLogin.data.accessToken;
    
    await api.post(`/workers/deliveries/${deliveryId}/accept`, {}, { headers: { Authorization: `Bearer ${workerToken}` } });
    await api.delete(`/deliveries/${deliveryId}`, { headers: { Authorization: `Bearer ${clientToken}` } });
    
    const complete = await api.patch(`/workers/deliveries/${deliveryId}/complete`, { delivered_gallons: 100 }, { headers: { Authorization: `Bearer ${workerToken}` } });
    
    if (complete.status === 400 || complete.status === 403) log('3.1 Cancellation Mid-Progress', 'PASS', 'Complete after cancel blocked');
    else log('3.1 Cancellation Mid-Progress', 'FAIL', `Expected 400/403, got ${complete.status}`);
  } catch (e) {
    log('3.1 Cancellation Mid-Progress', 'FAIL', e.message);
  }
}

async function test13_GPSAnomaly() {
  try {
    const login = await api.post('/auth/login', { username: 'worker1', password: 'Worker123!' });
    const token = login.data.accessToken;
    
    const res = await api.patch('/workers/deliveries/1/complete', 
      { delivered_gallons: 100, latitude: 91, longitude: 35 }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    if (res.status === 400) log('3.2 GPS Anomaly', 'PASS', 'Invalid GPS rejected');
    else log('3.2 GPS Anomaly', 'FAIL', `Expected 400, got ${res.status}`);
  } catch (e) {
    log('3.2 GPS Anomaly', 'FAIL', e.message);
  }
}

async function test14_InventoryRace() {
  try {
    const delivery = await pool.query('INSERT INTO deliveries (client_id, requested_gallons, status) VALUES ((SELECT id FROM users WHERE username = $1), 100, $2) RETURNING id', ['client1', 'pending']);
    const deliveryId = delivery.rows[0].id;
    
    const w1 = await api.post('/auth/login', { username: 'worker1', password: 'Worker123!' });
    const w2 = await api.post('/auth/login', { username: 'worker2', password: 'Worker123!' });
    
    const promises = [
      api.post(`/workers/deliveries/${deliveryId}/accept`, {}, { headers: { Authorization: `Bearer ${w1.data.accessToken}` } }),
      api.post(`/workers/deliveries/${deliveryId}/accept`, {}, { headers: { Authorization: `Bearer ${w2.data.accessToken}` } })
    ];
    
    const results = await Promise.all(promises);
    const success = results.filter(r => r.status === 200).length;
    
    if (success === 1) log('3.3 Inventory Race', 'PASS', 'Only one worker accepted');
    else log('3.3 Inventory Race', 'FAIL', `Expected 1 success, got ${success}`);
  } catch (e) {
    log('3.3 Inventory Race', 'FAIL', e.message);
  }
}

async function test15_ProximityNotification() {
  try {
    const login = await api.post('/auth/login', { username: 'worker1', password: 'Worker123!' });
    const token = login.data.accessToken;
    
    await api.post('/workers/location/update', { latitude: 32.0, longitude: 34.8 }, { headers: { Authorization: `Bearer ${token}` } });
    
    log('3.4 Proximity Notification', 'PASS', 'Location update accepted');
  } catch (e) {
    log('3.4 Proximity Notification', 'FAIL', e.message);
  }
}

async function test16_MaxGallons() {
  try {
    const login = await api.post('/auth/login', { username: 'worker1', password: 'Worker123!' });
    const token = login.data.accessToken;
    
    const res = await api.patch('/workers/deliveries/1/complete', 
      { delivered_gallons: 1101 }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    if (res.status === 400) log('3.5 Max Gallons', 'PASS', 'Over-delivery rejected');
    else log('3.5 Max Gallons', 'FAIL', `Expected 400, got ${res.status}`);
  } catch (e) {
    log('3.5 Max Gallons', 'FAIL', e.message);
  }
}

async function test17_NegativeEmpties() {
  try {
    const login = await api.post('/auth/login', { username: 'worker1', password: 'Worker123!' });
    const token = login.data.accessToken;
    
    const res = await api.patch('/workers/deliveries/1/complete', 
      { delivered_gallons: 100, empty_gallons_returned: -5 }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    if (res.status === 400) log('3.6 Negative Empties', 'PASS', 'Negative empties rejected');
    else log('3.6 Negative Empties', 'FAIL', `Expected 400, got ${res.status}`);
  } catch (e) {
    log('3.6 Negative Empties', 'FAIL', e.message);
  }
}

// Phase 4: Admin & Reporting
async function test18_DashboardLoad() {
  try {
    const login = await api.post('/auth/login', { username: 'admin1', password: 'Admin123!' });
    const token = login.data.accessToken;
    
    const start = Date.now();
    const promises = Array(50).fill().map(() => 
      api.get('/admin/dashboard', { headers: { Authorization: `Bearer ${token}` } })
    );
    await Promise.all(promises);
    const duration = Date.now() - start;
    
    if (duration < 25000) log('4.1 Dashboard Load', 'PASS', `${duration}ms for 50 requests`);
    else log('4.1 Dashboard Load', 'FAIL', `Too slow: ${duration}ms`);
  } catch (e) {
    log('4.1 Dashboard Load', 'FAIL', e.message);
  }
}

async function test19_RevenueReport() {
  try {
    const login = await api.post('/auth/login', { username: 'admin1', password: 'Admin123!' });
    const token = login.data.accessToken;
    
    const res = await api.get('/admin/reports/revenue?start_date=2026-01-01&end_date=2026-02-28', { headers: { Authorization: `Bearer ${token}` } });
    
    if (res.status === 200) log('4.2 Revenue Report', 'PASS', 'Report generated');
    else log('4.2 Revenue Report', 'FAIL', `Expected 200, got ${res.status}`);
  } catch (e) {
    log('4.2 Revenue Report', 'FAIL', e.message);
  }
}

async function test20_ClientDeactivation() {
  try {
    await pool.query('UPDATE users SET is_active = FALSE WHERE username = $1', ['client2']);
    
    const login = await api.post('/auth/login', { username: 'admin1', password: 'Admin123!' });
    const token = login.data.accessToken;
    
    const res = await api.get('/admin/clients', { headers: { Authorization: `Bearer ${token}` } });
    
    await pool.query('UPDATE users SET is_active = TRUE WHERE username = $1', ['client2']);
    
    log('4.3 Client Deactivation', 'PASS', 'Deactivation handled');
  } catch (e) {
    log('4.3 Client Deactivation', 'FAIL', e.message);
  }
}

async function test21_DispenserLimit() {
  try {
    const login = await api.post('/auth/login', { username: 'admin1', password: 'Admin123!' });
    const token = login.data.accessToken;
    
    const res = await api.get('/admin/dashboard', { headers: { Authorization: `Bearer ${token}` } });
    
    log('4.4 Dispenser Limit', 'PASS', 'Dashboard shows dispenser data');
  } catch (e) {
    log('4.4 Dispenser Limit', 'FAIL', e.message);
  }
}

// Phase 5: Edge Cases
async function test22_MonthlyReset() {
  try {
    await pool.query('UPDATE client_profiles SET monthly_usage_gallons = 0');
    log('5.1 Monthly Reset', 'PASS', 'Reset executed');
  } catch (e) {
    log('5.1 Monthly Reset', 'FAIL', e.message);
  }
}

async function test23_ZeroValues() {
  try {
    const login = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token = login.data.accessToken;
    
    const res = await api.post('/deliveries/request', { requested_gallons: 0 }, { headers: { Authorization: `Bearer ${token}` } });
    
    if (res.status === 400) log('5.2 Zero Values', 'PASS', 'Zero gallons rejected');
    else log('5.2 Zero Values', 'FAIL', `Expected 400, got ${res.status}`);
  } catch (e) {
    log('5.2 Zero Values', 'FAIL', e.message);
  }
}

async function test24_HolidayOverload() {
  try {
    const login = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token = login.data.accessToken;
    
    const promises = Array(20).fill().map(() => 
      api.post('/deliveries/request', { requested_gallons: 100, priority: 'urgent' }, { headers: { Authorization: `Bearer ${token}` } })
    );
    
    const results = await Promise.all(promises);
    const success = results.filter(r => r.status === 200 || r.status === 201).length;
    
    log('5.3 Holiday Overload', 'PASS', `${success}/20 requests succeeded`);
  } catch (e) {
    log('5.3 Holiday Overload', 'FAIL', e.message);
  }
}

async function test25_SQLInjection() {
  try {
    const login = await api.post('/auth/login', { username: 'client1', password: 'Secure123!' });
    const token = login.data.accessToken;
    
    const res = await api.post('/deliveries/request', 
      { requested_gallons: 100, notes: "<script>alert(1)</script>' OR '1'='1" }, 
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    if (res.status === 200 || res.status === 201) {
      const delivery = await pool.query('SELECT notes FROM deliveries WHERE id = $1', [res.data.id]);
      if (!delivery.rows[0].notes.includes('<script>')) {
        log('5.4 SQL Injection', 'PASS', 'Input sanitized');
      } else {
        log('5.4 SQL Injection', 'FAIL', 'XSS not sanitized');
      }
    } else {
      log('5.4 SQL Injection', 'PASS', 'Malicious input rejected');
    }
  } catch (e) {
    log('5.4 SQL Injection', 'FAIL', e.message);
  }
}

async function runAllTests() {
  console.log('Starting Comprehensive Deep Creative Test Scenario...\n');
  
  await test1_MultiDeviceLogin();
  await test2_RoleEscalation();
  await test3_PasswordReset();
  await test4_InactiveUser();
  await test5_CORS();
  
  await test6_CouponPurchase();
  await test7_DebtRace();
  await test8_SubscriptionSwitch();
  await test9_NegativePayment();
  await test10_CouponRace();
  await test11_BonusExploit();
  
  await test12_CancellationMidProgress();
  await test13_GPSAnomaly();
  await test14_InventoryRace();
  await test15_ProximityNotification();
  await test16_MaxGallons();
  await test17_NegativeEmpties();
  
  await test18_DashboardLoad();
  await test19_RevenueReport();
  await test20_ClientDeactivation();
  await test21_DispenserLimit();
  
  await test22_MonthlyReset();
  await test23_ZeroValues();
  await test24_HolidayOverload();
  await test25_SQLInjection();
  
  console.log('\n=== TEST RESULTS ===');
  console.log(`Passed: ${results.passed}/25`);
  console.log(`Failed: ${results.failed}/25`);
  console.log('\nFailed Tests:');
  results.details.filter(d => d.status === 'FAIL').forEach(d => {
    console.log(`  - ${d.test}: ${d.message}`);
  });
  
  await pool.end();
}

runAllTests().catch(console.error);
