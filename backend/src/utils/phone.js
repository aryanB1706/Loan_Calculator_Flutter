const INDIAN_MOBILE_REGEX = /^(?:\+91)?[6-9]\d{9}$/;

/**
 * Stores phone numbers in a single canonical format (10 digits, no +91)
 * so OTP and User lookups always match.
 */
function normalizePhone(phone) {
  return String(phone).trim().replace(/^\+91/, '');
}

function isValidIndianPhone(phone) {
  return INDIAN_MOBILE_REGEX.test(String(phone).trim());
}

module.exports = { INDIAN_MOBILE_REGEX, normalizePhone, isValidIndianPhone };
