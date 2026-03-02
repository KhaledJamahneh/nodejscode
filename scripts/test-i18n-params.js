// Test i18n multi-parameter support
const { t } = require('../src/utils/i18n');

console.log('\n=== Testing i18n Multi-Parameter Support ===\n');

// Test English
const enMsg = t('en', 'error_insufficient_inventory', {
  current: 39,
  delivered: 50,
  unit: 'gallons'
});
console.log('English:');
console.log(enMsg);

// Test Arabic
const arMsg = t('ar', 'error_insufficient_inventory', {
  current: 39,
  delivered: 50,
  unit: 'جالون'
});
console.log('\nArabic:');
console.log(arMsg);

// Test insufficient coupons
const enCoupon = t('en', 'error_insufficient_coupons', {
  remaining: 5,
  required: 10
});
console.log('\nEnglish (coupons):');
console.log(enCoupon);

const arCoupon = t('ar', 'error_insufficient_coupons', {
  remaining: 5,
  required: 10
});
console.log('\nArabic (coupons):');
console.log(arCoupon);
