const { HTTP_STATUS } = require('../constants');

/**
 * Sends a successful response using the project-wide shape:
 * { success: true, message, data }
 */
function sendSuccess(res, { statusCode = HTTP_STATUS.OK, message = 'OK', data = null } = {}) {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
}

module.exports = { sendSuccess };
