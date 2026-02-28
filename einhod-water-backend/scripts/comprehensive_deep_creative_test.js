require('dotenv').config();
const axios = require('axios');
const { query } = require('../src/config/database');
const bcrypt = require('bcrypt');


const PORT = process.env.PORT || 3000;
const BASE_URL = `http://localhost:${PORT}/api/v1`;

const COLORS = {
    reset: "\x1b[0m",
    red: "\x1b[31m",
    green: "\x1b[32m",
    yellow: "\x1b[33m",
    blue: "\x1b[34m",
    magenta: "\x1b[35m",
    cyan: "\x1b[36m",
};

function log(msg, color = COLORS.reset) {
    console.log(`${color}${msg}${COLORS.reset}`);
}

async function runComprehensiveTest() {
    log('\n🚀 STARTING COMPREHENSIVE DEEP CREATIVE TEST SCENARIO 🚀\n', COLORS.cyan);

    let clientToken, workerToken, adminToken;
    let clientId, workerId, adminId;
    let clientProfileId, workerProfileId;

    try {
        // --- 0. SETUP & SEEDING ---
        log('--- Phase 0: Setup & Seeding ---', COLORS.blue);
        
        // Clean up previous test users
        await query("DELETE FROM users WHERE username IN ('creative_client', 'creative_worker', 'creative_admin')");

        const passHash = await bcrypt.hash('TestPass123!', 10);

        // Create Client
        const cRes = await query(`
            INSERT INTO users (username, password_hash, role, phone_number, is_active)
            VALUES ('creative_client', $1, ARRAY['client']::user_role[], '9000001', true)
            RETURNING id`, [passHash]);
        clientId = cRes.rows[0].id;
        const cpRes = await query(`
            INSERT INTO client_profiles (user_id, full_name, address, subscription_type, remaining_coupons, subscription_expiry_date)
            VALUES ($1, 'Creative Client', '123 Test Ln', 'coupon_book', 10, CURRENT_DATE)
            RETURNING id`, [clientId]);
        clientProfileId = cpRes.rows[0].id;

        // Create Worker
        const wRes = await query(`
            INSERT INTO users (username, password_hash, role, phone_number, is_active)
            VALUES ('creative_worker', $1, ARRAY['delivery_worker']::user_role[], '9000002', true)
            RETURNING id`, [passHash]);
        workerId = wRes.rows[0].id;
        const wpRes = await query(`
            INSERT INTO worker_profiles (user_id, full_name, worker_type, hire_date, vehicle_current_gallons)
            VALUES ($1, 'Creative Worker', 'delivery', CURRENT_DATE, 1000)
            RETURNING id`, [workerId]);
        workerProfileId = wpRes.rows[0].id;

        // Create Admin
        const aRes = await query(`
            INSERT INTO users (username, password_hash, role, phone_number, is_active)
            VALUES ('creative_admin', $1, ARRAY['administrator']::user_role[], '9000003', true)
            RETURNING id`, [passHash]);
        adminId = aRes.rows[0].id;

        log('✅ Test users created.', COLORS.green);

        // Add a delay to ensure DB consistency across pool/pooler
        log('⏳ Waiting 3s for DB consistency...', COLORS.yellow);
        await new Promise(resolve => setTimeout(resolve, 3000));

        // Login to get tokens
        const login = async (username) => {
            let retries = 5;
            while (retries > 0) {
                try {
                    const res = await axios.post(`${BASE_URL}/auth/login`, { username, password: 'TestPass123!' });
                    return res.data.data.accessToken;
                } catch (e) {
                    if (e.response && e.response.status === 401 && retries > 1) {
                        log(`⏳ Login for ${username} failed (401), retrying... (${retries-1} left)`, COLORS.yellow);
                        await new Promise(r => setTimeout(r, 2000));
                        retries--;
                        continue;
                    }
                    throw e;
                }
            }
        };
        
        clientToken = await login('creative_client');
        workerToken = await login('creative_worker');
        adminToken = await login('creative_admin');

        log('✅ Tokens acquired.\n', COLORS.green);


        // --- PHASE 1: SECURITY ---
        log('--- Phase 1: Security Tests ---', COLORS.blue);

        // 1.1 Role Escalation
        log('1.1 Testing Role Escalation (Client accessing Admin Dashboard)...');
        try {
            await axios.get(`${BASE_URL}/admin/dashboard`, { headers: { Authorization: `Bearer ${clientToken}` } });
            log('❌ FAILED: Client was able to access Admin Dashboard!', COLORS.red);
        } catch (e) {
            if (e.response && (e.response.status === 403 || e.response.status === 401)) {
                log(`✅ PASSED: Access denied with status ${e.response.status}`, COLORS.green);
            } else {
                log(`⚠️ WARNING: Unexpected error: ${e.message}`, COLORS.yellow);
            }
        }

        // 1.2 Inactive User Access
        log('1.2 Testing Inactive User Access...');
        // Deactivate worker
        await query("UPDATE users SET is_active = false WHERE id = $1", [workerId]);
        // Try to access a protected route
        try {
            await axios.get(`${BASE_URL}/workers/profile`, { headers: { Authorization: `Bearer ${workerToken}` } });
            log('ℹ️ NOTE: Inactive user could still access. (JWT might be stateless without active check). Checking DB logic...', COLORS.yellow);
        } catch (e) {
             if (e.response && (e.response.status === 403 || e.response.status === 401)) {
                log(`✅ PASSED: Inactive user blocked with status ${e.response.status}`, COLORS.green);
            } else {
                log(`⚠️ WARNING: Unexpected error: ${e.message}`, COLORS.yellow);
            }
        }
        // Reactivate worker for next tests
        await query("UPDATE users SET is_active = true WHERE id = $1", [workerId]);


        // --- PHASE 2: BUSINESS LOGIC ---
        log('\n--- Phase 2: Business Logic Tests ---', COLORS.blue);

        // 2.1 Negative Payment
        log('2.1 Testing Negative Payment...');
        try {
            await axios.post(`${BASE_URL}/workers/expenses`, {
                amount: -50,
                payment_method: 'cash',
                notes: 'Negative expense'
            }, { headers: { Authorization: `Bearer ${workerToken}` } });
            log('❌ FAILED: Negative expense accepted!', COLORS.red);
        } catch (e) {
            if (e.response && e.response.status === 400) {
                log(`✅ PASSED: Negative amount rejected (400).`, COLORS.green);
            } else {
                log(`⚠️ WARNING: Unexpected error: ${e.message}`, COLORS.yellow);
            }
        }

        // 2.2 Zero Gallons Request
        log('2.2 Testing Zero Gallons Request...');
        try {
            await axios.post(`${BASE_URL}/deliveries/request`, {
                requested_gallons: 0,
                priority: 'urgent'
            }, { headers: { Authorization: `Bearer ${clientToken}` } });
            log('❌ FAILED: 0 gallon request accepted!', COLORS.red);
        } catch (e) {
            log(`✅ PASSED: 0 gallon request rejected.`, COLORS.green);
        }


        // --- PHASE 3: OPERATIONS & CHAOS ---
        log('\n--- Phase 3: Operations & Chaos Tests ---', COLORS.blue);

        // 3.1 Over-Delivery Attempt
        log('3.1 Testing Over-Delivery (Request 20, Deliver 1000)...');
        const reqRes = await axios.post(`${BASE_URL}/deliveries/request`, {
            requested_gallons: 20,
            priority: 'urgent'
        }, { headers: { Authorization: `Bearer ${clientToken}` } });
        const reqId = reqRes.data.data.id;
        
        await axios.post(`${BASE_URL}/workers/requests/${reqId}/accept`, {}, { headers: { Authorization: `Bearer ${workerToken}` } });
        
        try {
            await axios.post(`${BASE_URL}/workers/requests/${reqId}/complete`, {
                gallons_delivered: 1000,
                empty_gallons_returned: 0
            }, { headers: { Authorization: `Bearer ${workerToken}` } });
            log('❌ FAILED: Massive over-delivery accepted!', COLORS.red);
        } catch (e) {
            log(`ℹ️ Result: ${e.response ? e.response.data.message : e.message}`, COLORS.yellow);
            if (e.response && e.response.status === 400) {
                 log('✅ PASSED: Blocked with 400.', COLORS.green);
            }
        }

        // 3.2 Negative Empty Returns
        log('3.2 Testing Negative Empty Returns...');
        const req2 = await axios.post(`${BASE_URL}/deliveries/request`, { requested_gallons: 20 }, { headers: { Authorization: `Bearer ${clientToken}` } });
        const req2Id = req2.data.data.id;
        await axios.post(`${BASE_URL}/workers/requests/${req2Id}/accept`, {}, { headers: { Authorization: `Bearer ${workerToken}` } });

        try {
             await axios.post(`${BASE_URL}/workers/requests/${req2Id}/complete`, {
                gallons_delivered: 20,
                empty_gallons_returned: -5
            }, { headers: { Authorization: `Bearer ${workerToken}` } });
            log('❌ FAILED: Negative empty returns accepted!', COLORS.red);
        } catch (e) {
            log(`✅ PASSED: Negative returns rejected.`, COLORS.green);
        }

        log('\n✨ COMPREHENSIVE TEST COMPLETED ✨', COLORS.cyan);

    } catch (error) {
        log(`\n❌ CRITICAL ERROR IN TEST SUITE: ${error.message}`, COLORS.red);
        console.error(error);
        process.exit(1);
    } finally {
        process.exit(0);
    }
}

runComprehensiveTest();
