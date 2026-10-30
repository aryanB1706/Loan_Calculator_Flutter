const rateLimit = require('express-rate-limit');

const config = require('../config');
const { HTTP_STATUS, MESSAGES } = require('../constants');

const apiLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: MESSAGES.RATE_LIMIT_EXCEEDED,
    });
  },
});

module.exports = apiLimiter;
