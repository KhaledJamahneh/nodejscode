
const translationLoader = require('./translation-loader');
const logger = require('./logger');

// Deduplicate warning logs in production
const warnedKeys = new Set();

/**
 * Escape HTML special characters to prevent XSS
 * @param {string} str - String to escape
 * @returns {string} - Escaped string
 */
const escapeHtml = (str) => {
  if (typeof str !== 'string') return str;
  
  const htmlEscapeMap = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '/': '&#x2F;'
  };
  
  return str.replace(/[&<>"'/]/g, (char) => htmlEscapeMap[char]);
};

/**
 * Arabic pluralization rules for numbers
 * @param {number} count - The number
 * @param {object} forms - {zero, one, two, few, many, other}
 */
const pluralizeArabic = (count, forms) => {
  if (count === 0) return forms.zero || forms.other;
  if (count === 1) return forms.one;
  if (count === 2) return forms.two;
  if (count >= 3 && count <= 10) return forms.few;
  if (count >= 11 && count <= 99) return forms.many;
  return forms.other;
};

/**
 * English pluralization rules
 * @param {number} count - The number
 * @param {object} forms - {one, other}
 */
const pluralizeEnglish = (count, forms) => {
  return count === 1 ? forms.one : forms.other;
};

/**
 * Get pluralized unit
 * @param {string} lang - Language code
 * @param {string} unit - Unit name
 * @param {number} count - Count for pluralization
 */
const getUnit = (lang, unit, count) => {
  const normalized = normalizeLanguage(lang);
  const units = translationLoader.loadUnits();
  const unitForms = units[normalized]?.[unit];
  
  if (!unitForms) return unit;
  
  if (normalized === 'ar') {
    return pluralizeArabic(count, unitForms);
  } else {
    return pluralizeEnglish(count, unitForms);
  }
};

/**
 * Normalize language code to supported language
 * @param {string} lang - Language code (e.g., 'en', 'ar', 'fr', null, undefined)
 * @returns {string} - Normalized language code ('en' or 'ar')
 */
const normalizeLanguage = (lang) => {
  if (!lang || typeof lang !== 'string') return 'en';
  
  const normalized = lang.toLowerCase().trim();
  
  // Arabic variants
  if (normalized === 'ar' || normalized.startsWith('ar-')) return 'ar';
  
  // English variants
  if (normalized === 'en' || normalized.startsWith('en-')) return 'en';
  
  // Default to English for unsupported languages
  return 'en';
};

/**
 * Get localized string with parameter interpolation
 * @param {string} lang - Language code (e.g., 'en', 'ar', 'fr', null)
 * @param {string} key - Translation key
 * @param {object} params - Parameters for interpolation (e.g., { amount: 5, unit: 'gallon', worker: 'John', delivery_time: '2pm' })
 * @param {object} options - { escape: boolean } - Whether to escape HTML (default: true)
 * @returns {string} - Interpolated message
 */
const t = (lang, key, params = {}, options = { escape: true }) => {
  const userLang = normalizeLanguage(lang);
  const messages = translationLoader.loadMessages();
  
  // Try user's language first
  let message = messages[userLang]?.[key];
  
  // Fallback to English if missing
  if (!message && userLang !== 'en') {
    message = messages.en?.[key];
    if (message) {
      // Deduplicate warnings in production
      const warnKey = `${key}:${userLang}`;
      if (!warnedKeys.has(warnKey)) {
        warnedKeys.add(warnKey);
        logger.warn('Missing translation', {
          key,
          requestedLang: userLang,
          fallbackLang: 'en'
        });
      }
    }
  }
  
  // Last resort: return key itself
  if (!message) {
    // Deduplicate errors in production
    if (!warnedKeys.has(key)) {
      warnedKeys.add(key);
      logger.error('Translation key not found', {
        key,
        requestedLang: userLang,
        availableLanguages: Object.keys(messages)
      });
    }
    return key;
  }
  
  // Handle unit pluralization if amount and unit are provided
  if (params.amount !== undefined && params.unit) {
    const unitText = getUnit(userLang, params.unit, params.amount);
    params = { ...params, unit: unitText };
  }
  
  // Escape parameters if enabled (default)
  const processedParams = options.escape
    ? Object.keys(params).reduce((acc, key) => {
        acc[key] = escapeHtml(params[key]);
        return acc;
      }, {})
    : params;
  
  // Generic parameter interpolation - replace all {param} placeholders
  Object.keys(processedParams).forEach(param => {
    const placeholder = `{${param}}`;
    message = message.replace(new RegExp(placeholder, 'g'), processedParams[param]);
  });
  
  return message;
};

/**
 * Get language metadata for frontend rendering
 * @param {string} lang - Language code (e.g., 'en', 'ar', 'fr', null)
 * @returns {object} - { dir: 'ltr'|'rtl', locale: string }
 */
const getLanguageMetadata = (lang) => {
  const normalized = normalizeLanguage(lang);
  
  const metadata = {
    en: { dir: 'ltr', locale: 'en-US' },
    ar: { dir: 'rtl', locale: 'ar-SA' }
  };
  
  return metadata[normalized] || metadata.en;
};

/**
 * Reload translations (for production updates)
 */
const reloadTranslations = () => {
  translationLoader.reload();
};

module.exports = { t, getLanguageMetadata, reloadTranslations, normalizeLanguage };
