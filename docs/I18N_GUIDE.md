# Internationalization (i18n) Guide

## Current Implementation

The system uses a **robust language normalization** approach that gracefully handles:
- Invalid language codes (null, undefined, empty string)
- Unsupported languages (French, Spanish, etc.)
- Language variants (en-US, en-GB, ar-SA, ar-EG)

---

## Language Normalization

### How It Works

```javascript
const { normalizeLanguage } = require('./utils/i18n');

normalizeLanguage('en');        // → 'en'
normalizeLanguage('ar');        // → 'ar'
normalizeLanguage('en-US');     // → 'en'
normalizeLanguage('ar-SA');     // → 'ar'
normalizeLanguage('fr');        // → 'en' (fallback)
normalizeLanguage('es');        // → 'en' (fallback)
normalizeLanguage(null);        // → 'en' (fallback)
normalizeLanguage(undefined);   // → 'en' (fallback)
normalizeLanguage('');          // → 'en' (fallback)
normalizeLanguage('INVALID');   // → 'en' (fallback)
```

### Supported Languages

| Language | Code | Variants | Direction |
|----------|------|----------|-----------|
| English | `en` | `en-US`, `en-GB`, `en-CA` | LTR |
| Arabic | `ar` | `ar-SA`, `ar-EG`, `ar-AE` | RTL |

**Default:** English (`en`) for all unsupported languages

---

## Database Schema

### User Language Preference

```sql
-- users table
ALTER TABLE users ADD COLUMN preferred_language VARCHAR(10) DEFAULT 'en';

-- client_profiles table (already exists)
ALTER TABLE client_profiles ADD COLUMN preferred_language VARCHAR(10) DEFAULT 'en';

-- Constraints
ALTER TABLE users ADD CONSTRAINT check_language 
  CHECK (preferred_language IN ('en', 'ar'));
```

**Note:** Database constraint is optional. The normalization function handles invalid values gracefully.

---

## Usage Examples

### Example 1: Null Language in Database

```javascript
// Database: user.preferred_language = NULL

const { t } = require('./utils/i18n');

// Before (Vulnerable)
t(user.preferred_language, 'delivery_completed_title')
// → 'delivery_completed_title' (raw key) ❌

// After (Protected)
t(user.preferred_language, 'delivery_completed_title')
// → 'Delivery Completed' (English fallback) ✅
```

### Example 2: Unsupported Language

```javascript
// Database: user.preferred_language = 'fr' (French)

// Before (Vulnerable)
t('fr', 'delivery_completed_title')
// → 'delivery_completed_title' (raw key) ❌

// After (Protected)
t('fr', 'delivery_completed_title')
// → 'Delivery Completed' (English fallback) ✅
```

### Example 3: Language Variants

```javascript
// Database: user.preferred_language = 'en-US'

t('en-US', 'delivery_completed_title')
// → 'Delivery Completed' (normalized to 'en') ✅

// Database: user.preferred_language = 'ar-SA'

t('ar-SA', 'delivery_completed_title')
// → 'تم التوصيل' (normalized to 'ar') ✅
```

---

## Adding a New Language

### Step 1: Update Normalization Function

```javascript
// src/utils/i18n.js

const normalizeLanguage = (lang) => {
  if (!lang || typeof lang !== 'string') return 'en';
  
  const normalized = lang.toLowerCase().trim();
  
  // Arabic variants
  if (normalized === 'ar' || normalized.startsWith('ar-')) return 'ar';
  
  // English variants
  if (normalized === 'en' || normalized.startsWith('en-')) return 'en';
  
  // French variants (NEW)
  if (normalized === 'fr' || normalized.startsWith('fr-')) return 'fr';
  
  // Spanish variants (NEW)
  if (normalized === 'es' || normalized.startsWith('es-')) return 'es';
  
  // Default to English for unsupported languages
  return 'en';
};
```

### Step 2: Add Translation Files

```json
// src/locales/messages.json
{
  "en": {
    "delivery_completed_title": "Delivery Completed",
    "delivery_completed_body": "Your water has been delivered"
  },
  "ar": {
    "delivery_completed_title": "تم التوصيل",
    "delivery_completed_body": "تم توصيل المياه الخاصة بك"
  },
  "fr": {
    "delivery_completed_title": "Livraison terminée",
    "delivery_completed_body": "Votre eau a été livrée"
  },
  "es": {
    "delivery_completed_title": "Entrega completada",
    "delivery_completed_body": "Tu agua ha sido entregada"
  }
}
```

### Step 3: Add Unit Translations

```json
// src/locales/units.json
{
  "en": {
    "gallon": { "one": "gallon", "other": "gallons" }
  },
  "ar": {
    "gallon": {
      "zero": "جالون",
      "one": "جالون واحد",
      "two": "جالونان",
      "few": "جالونات",
      "many": "جالون",
      "other": "جالون"
    }
  },
  "fr": {
    "gallon": { "one": "gallon", "other": "gallons" }
  },
  "es": {
    "gallon": { "one": "galón", "other": "galones" }
  }
}
```

### Step 4: Add Language Metadata

```javascript
// src/utils/i18n.js

const getLanguageMetadata = (lang) => {
  const normalized = normalizeLanguage(lang);
  
  const metadata = {
    en: { dir: 'ltr', locale: 'en-US' },
    ar: { dir: 'rtl', locale: 'ar-SA' },
    fr: { dir: 'ltr', locale: 'fr-FR' },  // NEW
    es: { dir: 'ltr', locale: 'es-ES' }   // NEW
  };
  
  return metadata[normalized] || metadata.en;
};
```

### Step 5: Update Pluralization (if needed)

```javascript
// French pluralization (same as English)
const pluralizeFrench = (count, forms) => {
  return count === 1 ? forms.one : forms.other;
};

// Spanish pluralization (same as English)
const pluralizeSpanish = (count, forms) => {
  return count === 1 ? forms.one : forms.other;
};

const getUnit = (lang, unit, count) => {
  const normalized = normalizeLanguage(lang);
  const units = translationLoader.loadUnits();
  const unitForms = units[normalized]?.[unit];
  
  if (!unitForms) return unit;
  
  switch (normalized) {
    case 'ar':
      return pluralizeArabic(count, unitForms);
    case 'fr':
      return pluralizeFrench(count, unitForms);
    case 'es':
      return pluralizeSpanish(count, unitForms);
    default:
      return pluralizeEnglish(count, unitForms);
  }
};
```

### Step 6: Reload Translations (Production)

```bash
# Hot-reload without restarting server
curl -X POST http://localhost:3000/api/v1/admin/translations/reload \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Fallback Chain

The system uses a **three-tier fallback** approach:

```
User's Language → English → Raw Key
```

### Example Flow

```javascript
// User language: 'fr' (French, not yet supported)
t('fr', 'delivery_completed_title')

// Step 1: Normalize 'fr' → 'en' (fallback to English)
// Step 2: Look up messages.en['delivery_completed_title']
// Step 3: Found → return "Delivery Completed" ✅

// If English also missing (rare):
// Step 4: Log error, return raw key 'delivery_completed_title'
```

---

## Testing

### Test Cases

```javascript
const { normalizeLanguage, t } = require('./utils/i18n');

// Test normalization
console.assert(normalizeLanguage('en') === 'en');
console.assert(normalizeLanguage('ar') === 'ar');
console.assert(normalizeLanguage('en-US') === 'en');
console.assert(normalizeLanguage('ar-SA') === 'ar');
console.assert(normalizeLanguage('fr') === 'en'); // Fallback
console.assert(normalizeLanguage(null) === 'en'); // Fallback
console.assert(normalizeLanguage('') === 'en'); // Fallback

// Test translation with invalid language
console.assert(t('fr', 'delivery_completed_title') === 'Delivery Completed');
console.assert(t(null, 'delivery_completed_title') === 'Delivery Completed');
console.assert(t(undefined, 'delivery_completed_title') === 'Delivery Completed');

// Test translation with valid language
console.assert(t('en', 'delivery_completed_title') === 'Delivery Completed');
console.assert(t('ar', 'delivery_completed_title') === 'تم التوصيل');
```

---

## Migration Guide

### Existing Users with NULL Language

```sql
-- Set default language for existing users
UPDATE users SET preferred_language = 'en' WHERE preferred_language IS NULL;
UPDATE client_profiles SET preferred_language = 'en' WHERE preferred_language IS NULL;

-- Or use region-based detection
UPDATE users 
SET preferred_language = CASE 
  WHEN country_code IN ('SA', 'AE', 'EG', 'JO', 'LB') THEN 'ar'
  ELSE 'en'
END
WHERE preferred_language IS NULL;
```

### Existing Users with Unsupported Language

```sql
-- Find users with unsupported languages
SELECT preferred_language, COUNT(*) 
FROM users 
WHERE preferred_language NOT IN ('en', 'ar')
GROUP BY preferred_language;

-- Option 1: Reset to English
UPDATE users SET preferred_language = 'en' 
WHERE preferred_language NOT IN ('en', 'ar');

-- Option 2: Keep as-is (normalization handles it)
-- No action needed - system will fallback to English automatically
```

---

## Monitoring

### Log Analysis

```bash
# Find users with unsupported languages
grep "normalizeLanguage" logs/combined.log | grep -v "en\|ar"

# Find missing translations
grep "Missing translation" logs/combined.log

# Find translation key errors
grep "Translation key not found" logs/error.log
```

### Metrics to Track

1. **Language Distribution**
   ```sql
   SELECT preferred_language, COUNT(*) 
   FROM users 
   GROUP BY preferred_language;
   ```

2. **Fallback Rate**
   - Count of `normalizeLanguage` calls that return 'en' for non-English input
   - Target: < 1% (most users should have valid language)

3. **Missing Translation Rate**
   - Count of "Missing translation" warnings
   - Target: 0 (all keys should exist in all languages)

---

## Best Practices

### ✅ DO: Always Use Normalization

```javascript
// ✅ CORRECT
const userLang = normalizeLanguage(user.preferred_language);
const message = t(userLang, 'key');

// ✅ ALSO CORRECT (normalization happens inside t())
const message = t(user.preferred_language, 'key');
```

### ✅ DO: Validate Language on User Update

```javascript
// API endpoint: PATCH /api/v1/users/profile
const { normalizeLanguage } = require('./utils/i18n');

const updateProfile = async (req, res) => {
  const { preferred_language } = req.body;
  
  // Normalize before saving
  const normalized = normalizeLanguage(preferred_language);
  
  await query(
    'UPDATE users SET preferred_language = $1 WHERE id = $2',
    [normalized, req.user.id]
  );
  
  res.json({ success: true, language: normalized });
};
```

### ✅ DO: Provide Language Selector in UI

```javascript
// API endpoint: GET /api/v1/languages
const getLanguages = (req, res) => {
  res.json({
    languages: [
      { code: 'en', name: 'English', nativeName: 'English', dir: 'ltr' },
      { code: 'ar', name: 'Arabic', nativeName: 'العربية', dir: 'rtl' }
    ]
  });
};
```

### ❌ DON'T: Trust User Input Directly

```javascript
// ❌ WRONG
const message = t(req.body.language, 'key'); // User could send 'fr', null, etc.

// ✅ CORRECT
const normalized = normalizeLanguage(req.body.language);
const message = t(normalized, 'key');
```

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Null language | Raw key returned ❌ | English fallback ✅ |
| Unsupported language | Raw key returned ❌ | English fallback ✅ |
| Language variants | Not handled ❌ | Normalized ✅ |
| Scalability | Brittle ❌ | Extensible ✅ |
| User experience | Broken messages ❌ | Always readable ✅ |

**Key Principle:** Graceful degradation - always show something readable, never raw keys.
