const express = require('express');

const { sendOtp, verifyOtp, refresh, logout } = require('../controllers/auth.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate');
const { sendOtpLimiter } = require('../middlewares/rateLimiter');
const {
  sendOtpSchema,
  verifyOtpSchema,
  refreshTokenSchema,
} = require('../validators/auth.validator');

const router = express.Router();

router.post('/send-otp', sendOtpLimiter, validate(sendOtpSchema), sendOtp);
router.post('/verify-otp', validate(verifyOtpSchema), verifyOtp);
router.post('/refresh', validate(refreshTokenSchema), refresh);
router.post('/logout', authenticate, logout);

module.exports = router;
