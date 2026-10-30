const rateLimit = require('express-rate-limit');

const config = require('../config');
const { HTTP_STATUS, MESSAGES } = require('../constants');

function rateLimitHandler(req, res) {
  res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
    success: false,
    message: MESSAGES.RATE_LIMIT_EXCEEDED,
  });
}

const apiLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
});

// OTP sending is more sensitive than normal reads, so it gets its own budget.
const sendOtpLimiter = rateLimit({
  windowMs: config.rateLimit.sendOtpWindowMs,
  max: config.rateLimit.sendOtpMax,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
});

module.exports = { apiLimiter, sendOtpLimiter };
