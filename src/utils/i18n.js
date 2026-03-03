// src/utils/i18n.js
const messages = require('../locales/messages.json');
const units = require('../locales/units.json');

/**
 * Get message in specified language
 * @param {string} key - Message key
 * @param {string} lang - Language code (en, ar)
 * @param {object} params - Parameters to replace in message
 * @returns {string} Localized message
 */
function getMessage(key, lang = 'en', params = {}) {
  const langMessages = messages[lang] || messages.en;
  let message = langMessages[key] || messages.en[key] || key;
  
  // Replace parameters
  Object.keys(params).forEach(param => {
    message = message.replace(new RegExp(`{${param}}`, 'g'), params[param]);
  });
  
  return message;
}

/**
 * Get unit translation
 * @param {string} unit - Unit key
 * @param {string} lang - Language code
 * @returns {string} Localized unit
 */
function getUnit(unit, lang = 'en') {
  const langUnits = units[lang] || units.en;
  return langUnits[unit] || units.en[unit] || unit;
}

/**
 * Get language from request headers
 * @param {object} req - Express request object
 * @returns {string} Language code
 */
function getLanguage(req) {
  const acceptLanguage = req.headers['accept-language'];
  if (!acceptLanguage) return 'en';
  
  // Parse Accept-Language header
  const lang = acceptLanguage.split(',')[0].split('-')[0].toLowerCase();
  return ['en', 'ar'].includes(lang) ? lang : 'en';
}

/**
 * Localize response
 * @param {object} req - Express request object
 * @param {string} messageKey - Message key
 * @param {object} params - Parameters
 * @returns {string} Localized message
 */
function localizeResponse(req, messageKey, params = {}) {
  const lang = getLanguage(req);
  return getMessage(messageKey, lang, params);
}

/**
 * Localize status
 * @param {string} status - Status value
 * @param {string} lang - Language code
 * @returns {string} Localized status
 */
function localizeStatus(status, lang = 'en') {
  const statusKey = `status_${status}`;
  return getMessage(statusKey, lang);
}

/**
 * Localize priority
 * @param {string} priority - Priority value
 * @param {string} lang - Language code
 * @returns {string} Localized priority
 */
function localizePriority(priority, lang = 'en') {
  const priorityKey = `priority_${priority}`;
  return getMessage(priorityKey, lang);
}

module.exports = {
  getMessage,
  getUnit,
  getLanguage,
  localizeResponse,
  localizeStatus,
  localizePriority
};
