const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/apiResponse');
const { HTTP_STATUS, MESSAGES } = require('../constants');
const authService = require('../services/auth.service');

const sendOtp = asyncHandler(async (req, res) => {
  const data = await authService.sendOtp(req.body.phone);

  return sendSuccess(res, {
    statusCode: HTTP_STATUS.OK,
    message: MESSAGES.OTP_SENT,
    data,
  });
});

const verifyOtp = asyncHandler(async (req, res) => {
  const data = await authService.verifyOtp(req.body.phone, req.body.otp);

  return sendSuccess(res, {
    statusCode: HTTP_STATUS.OK,
    message: MESSAGES.OTP_VERIFIED,
    data,
  });
});

const refresh = asyncHandler(async (req, res) => {
  const data = await authService.refreshTokens(req.body.refreshToken);

  return sendSuccess(res, {
    statusCode: HTTP_STATUS.OK,
    message: MESSAGES.TOKENS_REFRESHED,
    data,
  });
});

const logout = asyncHandler(async (req, res) => {
  await authService.logout(req.user._id);

  return sendSuccess(res, {
    statusCode: HTTP_STATUS.OK,
    message: MESSAGES.LOGGED_OUT,
  });
});

module.exports = { sendOtp, verifyOtp, refresh, logout };
