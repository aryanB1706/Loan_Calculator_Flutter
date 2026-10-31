const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/apiResponse');
const { MESSAGES } = require('../constants');
const userService = require('../services/user.service');
const creditScoreService = require('../services/creditScore.service');

const getMe = asyncHandler(async (req, res) => {
  const user = userService.getProfile(req.user);

  return sendSuccess(res, {
    message: MESSAGES.PROFILE_FETCHED,
    data: { user: user.toJSON() },
  });
});

const updateMe = asyncHandler(async (req, res) => {
  const user = await userService.updateProfile(req.user, req.body);

  return sendSuccess(res, {
    message: MESSAGES.PROFILE_UPDATED,
    data: { user: user.toJSON() },
  });
});

const getMyCreditScore = asyncHandler(async (req, res) => {
  const summary = await creditScoreService.getCreditScoreSummary(req.user);

  return sendSuccess(res, {
    message: MESSAGES.CREDIT_SCORE_FETCHED,
    data: summary,
  });
});

module.exports = { getMe, updateMe, getMyCreditScore };
