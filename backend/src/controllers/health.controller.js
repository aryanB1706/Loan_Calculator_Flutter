const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/apiResponse');
const { MESSAGES } = require('../constants');

const getHealth = asyncHandler(async (_req, res) => {
  return sendSuccess(res, {
    message: MESSAGES.HEALTH_OK,
    data: {
      status: 'ok',
      uptime: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
    },
  });
});

module.exports = { getHealth };
