const crypto = require('node:crypto');

const config = require('../config');
const AppError = require('../utils/AppError');
const { HTTP_STATUS } = require('../constants');

function keysMatch(provided, expected) {
  const providedBuffer = Buffer.from(provided);
  const expectedBuffer = Buffer.from(expected);

  if (providedBuffer.length !== expectedBuffer.length) return false;

  return crypto.timingSafeEqual(providedBuffer, expectedBuffer);
}

/**
 * A small stand-in for admin auth: callers send the shared ADMIN_API_KEY in the
 * x-admin-api-key header. This avoids building an admin user/role system just
 * for the demo, and must be replaced with real admin accounts before launch.
 */
const authenticateAdmin = (req, _res, next) => {
  if (!config.adminApiKey) {
    return next(new AppError('Admin API is not configured', HTTP_STATUS.SERVICE_UNAVAILABLE));
  }

  const providedKey = req.get('x-admin-api-key');

  if (!providedKey || !keysMatch(providedKey, config.adminApiKey)) {
    return next(new AppError('Invalid admin API key', HTTP_STATUS.UNAUTHORIZED));
  }

  return next();
};

module.exports = authenticateAdmin;
