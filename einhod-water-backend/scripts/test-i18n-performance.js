// Test i18n performance and deduplication
const { t } = require('../src/utils/i18n');

console.log('\n=== Testing i18n Performance & Deduplication ===\n');

// Test 1: Missing translation (should log only once)
console.log('Test 1: Missing translation key (called 1000x)');
console.time('missing-key-1000x');
for (let i = 0; i < 1000; i++) {
  t('ar', 'nonexistent_key_test');
}
console.timeEnd('missing-key-1000x');
console.log('Expected: 1 error log (deduplicated)\n');

// Test 2: Missing Arabic translation (should log only once)
console.log('Test 2: Missing Arabic translation (called 1000x)');
console.time('missing-arabic-1000x');
for (let i = 0; i < 1000; i++) {
  t('ar', 'some_english_only_key');
}
console.timeEnd('missing-arabic-1000x');
console.log('Expected: 1 warning log (deduplicated)\n');

// Test 3: Valid translation (should not log)
console.log('Test 3: Valid translation (called 10000x)');
console.time('valid-key-10000x');
for (let i = 0; i < 10000; i++) {
  t('en', 'error_insufficient_inventory', { current: 10, delivered: 20, unit: 'gallons' });
}
console.timeEnd('valid-key-10000x');
console.log('Expected: 0 logs\n');

console.log('✅ Performance test complete');
console.log('Check that logs are deduplicated (only 1 error + 1 warning total)');
