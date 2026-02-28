
const translations = {
  en: {
    delivery_completed_title: "Delivery Completed",
    delivery_completed_body: (amount) => `Your delivery of ${amount} gallons has been completed.`,
    request_accepted_title: "Request Accepted",
    request_accepted_body: (worker) => `${worker} has accepted your delivery request and is on the way.`,
    scheduled_accepted_title: "Delivery Accepted",
    scheduled_accepted_body: (worker) => `${worker} has accepted your scheduled delivery and is on the way.`,
    water_delivered_title: "Water Delivered",
    water_delivered_body: (amount) => `${amount} gallons delivered to your location.`
  },
  ar: {
    delivery_completed_title: "اكتمل التوصيل",
    delivery_completed_body: (amount) => `تم اكتمال توصيل ${amount} جالون بنجاح.`,
    request_accepted_title: "تم قبول الطلب",
    request_accepted_body: (worker) => `قام ${worker} بقبول طلب التوصيل الخاص بك وهو في الطريق إليك.`,
    scheduled_accepted_title: "تم قبول التوصيل",
    scheduled_accepted_body: (worker) => `قام ${worker} بقبول التوصيل المجدول وهو في الطريق إليك.`,
    water_delivered_title: "تم توصيل المياه",
    water_delivered_body: (amount) => `تم توصيل ${amount} جالون إلى موقعك.`
  }
};

/**
 * Get localized string
 * @param {string} lang - 'en' or 'ar'
 * @param {string} key - Translation key
 * @param {any} param - Parameter for template functions
 */
const t = (lang, key, param) => {
  const userLang = lang === 'ar' ? 'ar' : 'en';
  const entry = translations[userLang][key];
  if (typeof entry === 'function') return entry(param);
  return entry || key;
};

module.exports = { t };
