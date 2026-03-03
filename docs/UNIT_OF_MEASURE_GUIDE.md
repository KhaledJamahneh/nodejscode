# Unit of Measure Configuration Guide

## Current Implementation

The i18n system **already supports multiple units** through decoupled unit translations:

```javascript
// Units are separate from messages
t(lang, 'water_delivered_body', { amount: 5, unit: 'gallon' })
// → "5 gallons delivered to your location."

t(lang, 'water_delivered_body', { amount: 5, unit: 'liter' })
// → "5 liters delivered to your location."
```

---

## Architecture

### 1. Unit-Agnostic Messages

Messages use generic `{unit}` placeholder:

```json
{
  "en": {
    "water_delivered_body": "{amount} {unit} delivered to your location."
  },
  "ar": {
    "water_delivered_body": "تم توصيل {amount} {unit} إلى موقعك."
  }
}
```

### 2. Separate Unit Translations

Units are defined separately with pluralization:

```json
{
  "en": {
    "gallon": { "one": "gallon", "other": "gallons" },
    "liter": { "one": "liter", "other": "liters" },
    "bottle": { "one": "bottle", "other": "bottles" }
  },
  "ar": {
    "gallon": {
      "zero": "جالون",
      "one": "جالون",
      "two": "جالونان",
      "few": "جالونات",
      "many": "جالوناً",
      "other": "جالون"
    }
  }
}
```

### 3. Automatic Pluralization

The `t()` function automatically pluralizes units:

```javascript
t('en', 'water_delivered_body', { amount: 1, unit: 'gallon' })
// → "1 gallon delivered to your location."

t('en', 'water_delivered_body', { amount: 5, unit: 'gallon' })
// → "5 gallons delivered to your location."

t('ar', 'water_delivered_body', { amount: 3, unit: 'gallon' })
// → "تم توصيل 3 جالونات إلى موقعك." (Arabic plural form)
```

---

## Making Units Configurable

### Option 1: Regional Configuration (Recommended)

Add unit preference to system settings:

```sql
-- Add regional unit configuration
CREATE TABLE regional_settings (
  id SERIAL PRIMARY KEY,
  region_code VARCHAR(10) NOT NULL UNIQUE, -- 'US', 'SA', 'EU', etc.
  unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'gallon', -- 'gallon', 'liter', 'bottle'
  currency VARCHAR(10) NOT NULL DEFAULT 'USD',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default regions
INSERT INTO regional_settings (region_code, unit_of_measure, currency) VALUES
  ('US', 'gallon', 'USD'),
  ('SA', 'gallon', 'SAR'),
  ('EU', 'liter', 'EUR'),
  ('UK', 'liter', 'GBP');

-- Add region to users
ALTER TABLE users ADD COLUMN region_code VARCHAR(10) DEFAULT 'US';
ALTER TABLE users ADD FOREIGN KEY (region_code) REFERENCES regional_settings(region_code);
```

### Option 2: Client-Level Configuration

Allow individual clients to choose their preferred unit:

```sql
-- Add unit preference to client profiles
ALTER TABLE client_profiles ADD COLUMN preferred_unit VARCHAR(20) DEFAULT 'gallon';
ALTER TABLE client_profiles ADD CONSTRAINT check_unit 
  CHECK (preferred_unit IN ('gallon', 'liter', 'bottle'));
```

### Option 3: System-Wide Configuration

Simple environment variable for single-region deployments:

```bash
# .env
DEFAULT_UNIT=gallon  # or 'liter', 'bottle'
```

---

## Implementation Examples

### Example 1: Regional Unit Selection

```javascript
// src/controllers/worker.controller.js

const completeDelivery = async (req, res) => {
  // ... existing code ...
  
  await transaction(async (client) => {
    // Get client's regional unit preference
    const clientResult = await client.query(
      `SELECT cp.preferred_language, rs.unit_of_measure
       FROM client_profiles cp
       JOIN users u ON cp.user_id = u.id
       JOIN regional_settings rs ON u.region_code = rs.region_code
       WHERE cp.id = $1`,
      [delivery.client_id]
    );
    
    const { preferred_language, unit_of_measure } = clientResult.rows[0];
    
    // Create notification with regional unit
    await client.query(
      `INSERT INTO notifications (user_id, title, message) VALUES ($1, $2, $3)`,
      [
        userId,
        t(preferred_language, 'delivery_completed_title'),
        t(preferred_language, 'delivery_completed_body', {
          amount: gallons_delivered,
          unit: unit_of_measure // 'gallon', 'liter', or 'bottle'
        })
      ]
    );
  });
};
```

### Example 2: Client-Specific Unit

```javascript
// Allow client to set preferred unit in profile
const updateClientProfile = async (req, res) => {
  const { preferred_unit } = req.body;
  
  // Validate unit
  const validUnits = ['gallon', 'liter', 'bottle'];
  if (preferred_unit && !validUnits.includes(preferred_unit)) {
    return res.status(400).json({
      success: false,
      message: `Invalid unit. Must be one of: ${validUnits.join(', ')}`
    });
  }
  
  await query(
    'UPDATE client_profiles SET preferred_unit = $1 WHERE user_id = $2',
    [preferred_unit, req.user.id]
  );
  
  res.json({ success: true });
};
```

### Example 3: System-Wide Default

```javascript
// src/utils/i18n.js

const getDefaultUnit = () => {
  return process.env.DEFAULT_UNIT || 'gallon';
};

// Usage in controllers
t(lang, 'water_delivered_body', {
  amount: gallons_delivered,
  unit: client.preferred_unit || getDefaultUnit()
});
```

---

## Unit Conversion

If you need to convert between units:

```javascript
// src/utils/unit-converter.js

const CONVERSION_RATES = {
  gallon_to_liter: 3.78541,
  liter_to_gallon: 0.264172,
  gallon_to_bottle: 0.2, // 1 gallon = 5 bottles (20L bottles)
  bottle_to_gallon: 5
};

/**
 * Convert amount from one unit to another
 * @param {number} amount - Amount to convert
 * @param {string} fromUnit - Source unit
 * @param {string} toUnit - Target unit
 * @returns {number} - Converted amount
 */
const convertUnit = (amount, fromUnit, toUnit) => {
  if (fromUnit === toUnit) return amount;
  
  const conversionKey = `${fromUnit}_to_${toUnit}`;
  const rate = CONVERSION_RATES[conversionKey];
  
  if (!rate) {
    throw new Error(`Conversion from ${fromUnit} to ${toUnit} not supported`);
  }
  
  return Math.round(amount * rate * 100) / 100; // Round to 2 decimals
};

module.exports = { convertUnit };
```

### Usage Example

```javascript
const { convertUnit } = require('../utils/unit-converter');

// Store in database as gallons (canonical unit)
const gallons = 20;

// Display to user in their preferred unit
const clientUnit = client.preferred_unit || 'gallon';
const displayAmount = convertUnit(gallons, 'gallon', clientUnit);

// Send notification
await sendNotification(userId, {
  title: t(lang, 'water_delivered_title'),
  body: t(lang, 'water_delivered_body', {
    amount: displayAmount,
    unit: clientUnit
  })
});
```

---

## Database Schema Considerations

### Option A: Store in Canonical Unit (Recommended)

Store all amounts in a single unit (e.g., gallons) and convert for display:

```sql
-- All amounts stored as gallons
CREATE TABLE deliveries (
  id SERIAL PRIMARY KEY,
  gallons_delivered DECIMAL(10, 2) NOT NULL, -- Always in gallons
  -- ... other fields
);
```

**Pros:**
- Simple queries and aggregations
- No conversion errors in calculations
- Easy to change display unit without migrating data

**Cons:**
- Must convert for display

### Option B: Store Unit with Amount

Store both amount and unit:

```sql
CREATE TABLE deliveries (
  id SERIAL PRIMARY KEY,
  amount_delivered DECIMAL(10, 2) NOT NULL,
  unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'gallon',
  -- ... other fields
);
```

**Pros:**
- Preserves original unit
- No conversion needed for display

**Cons:**
- Complex aggregations (must convert to common unit)
- Harder to query (WHERE amount > 20 depends on unit)

**Recommendation:** Use Option A (canonical unit) for simplicity.

---

## Migration Path

### Phase 1: Add Configuration (No Breaking Changes)

```sql
-- Add unit preference (defaults to current behavior)
ALTER TABLE client_profiles ADD COLUMN preferred_unit VARCHAR(20) DEFAULT 'gallon';
```

### Phase 2: Update Controllers

```javascript
// Update notification calls to use preferred_unit
const unit = client.preferred_unit || 'gallon';
t(lang, 'water_delivered_body', { amount, unit });
```

### Phase 3: Add UI for Unit Selection

```javascript
// API endpoint for client to change unit
PATCH /api/v1/clients/profile
{
  "preferred_unit": "liter"
}
```

### Phase 4: Regional Rollout

```sql
-- Set default unit for specific regions
UPDATE users SET region_code = 'EU' WHERE country IN ('FR', 'DE', 'IT');
UPDATE regional_settings SET unit_of_measure = 'liter' WHERE region_code = 'EU';
```

---

## Testing

### Unit Test

```javascript
const { t } = require('../utils/i18n');

describe('Unit Localization', () => {
  it('should support gallons', () => {
    const msg = t('en', 'water_delivered_body', { amount: 5, unit: 'gallon' });
    expect(msg).toBe('5 gallons delivered to your location.');
  });

  it('should support liters', () => {
    const msg = t('en', 'water_delivered_body', { amount: 5, unit: 'liter' });
    expect(msg).toBe('5 liters delivered to your location.');
  });

  it('should support bottles', () => {
    const msg = t('en', 'water_delivered_body', { amount: 5, unit: 'bottle' });
    expect(msg).toBe('5 bottles delivered to your location.');
  });

  it('should pluralize correctly', () => {
    const msg1 = t('en', 'water_delivered_body', { amount: 1, unit: 'gallon' });
    expect(msg1).toContain('1 gallon');

    const msg2 = t('en', 'water_delivered_body', { amount: 2, unit: 'gallon' });
    expect(msg2).toContain('2 gallons');
  });
});
```

---

## Best Practices

### ✅ DO: Use Generic Unit Placeholder

```javascript
// ✅ CORRECT: Unit-agnostic message
"water_delivered_body": "{amount} {unit} delivered"

// ❌ WRONG: Hardcoded unit
"water_delivered_body": "{amount} gallons delivered"
```

### ✅ DO: Store in Canonical Unit

```javascript
// ✅ CORRECT: Store as gallons, convert for display
const gallons = 20;
const displayAmount = convertUnit(gallons, 'gallon', client.preferred_unit);
```

### ✅ DO: Validate Unit Input

```javascript
// ✅ CORRECT: Validate against allowed units
const validUnits = ['gallon', 'liter', 'bottle'];
if (!validUnits.includes(unit)) {
  throw new Error('Invalid unit');
}
```

### ❌ DON'T: Hardcode Units in Messages

```javascript
// ❌ WRONG: Can't change unit without rewriting translations
"water_delivered_body": "5 gallons delivered"

// ✅ CORRECT: Unit is a parameter
"water_delivered_body": "{amount} {unit} delivered"
```

---

## Summary

| Aspect | Current Implementation | Flexibility |
|--------|----------------------|-------------|
| Message structure | Unit-agnostic `{unit}` placeholder | ✅ Fully flexible |
| Unit translations | Separate `units.json` file | ✅ Easy to add units |
| Pluralization | Automatic per language | ✅ Handles all cases |
| Configuration | Not yet implemented | ⚠️ Needs database schema |

**Current Status:** The i18n system is **already designed** to support multiple units. You just need to add configuration (regional settings or client preferences) to make it user-selectable.

**Next Steps:**
1. Add `preferred_unit` column to `client_profiles` or `regional_settings` table
2. Update controllers to pass unit parameter to `t()` function
3. Add API endpoint for users to change their preferred unit
4. (Optional) Add unit conversion utility if storing in canonical unit
