const config = require('../config');
const { HTTP_STATUS } = require('../constants');
const AppError = require('../utils/AppError');
const Otp = require('../models/Otp');
const User = require('../models/User');
const { generateOtp, hashOtp, compareOtp } = require('../utils/otp');
const { normalizePhone } = require('../utils/phone');
const {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
  hashToken,
} = require('../utils/token');
const otpService = require('./otp');

const OTP_TTL_MS = config.otp.expiresInMinutes * 60 * 1000;
const RESEND_COOLDOWN_MS = config.otp.resendCooldownSeconds * 1000;

// Demo mode is for local/staging app testing: no SMS is sent and the code is fixed.
const DEMO_OTP = '123456';

async function issueTokens(user) {
  const accessToken = signAccessToken(user._id);
  const refreshToken = signRefreshToken(user._id);

  user.refreshTokenHash = hashToken(refreshToken);
  await user.save();

  return { accessToken, refreshToken };
}

async function sendOtp(rawPhone) {
  const phone = normalizePhone(rawPhone);
  const now = Date.now();

  const existingOtp = await Otp.findOne({ phone }).sort({ createdAt: -1 });

  if (existingOtp) {
    const cooldownEndsAt = existingOtp.createdAt.getTime() + RESEND_COOLDOWN_MS;

    if (cooldownEndsAt > now) {
      const retryAfterSeconds = Math.ceil((cooldownEndsAt - now) / 1000);
      throw new AppError(
        `Please wait ${retryAfterSeconds} seconds before requesting a new OTP`,
        HTTP_STATUS.TOO_MANY_REQUESTS,
        [{ field: 'retryAfterSeconds', message: String(retryAfterSeconds) }]
      );
    }
  }

  const otp = config.otp.mode === 'demo' ? DEMO_OTP : generateOtp();
  const otpHash = await hashOtp(otp);
  const expiresAt = new Date(now + OTP_TTL_MS);

  // Only one active OTP per phone keeps verification unambiguous.
  await Otp.deleteMany({ phone });
  await Otp.create({ phone, otpHash, expiresAt });

  let delivery;
  try {
    delivery = await otpService.getOtpSender().send(phone, otp);
  } catch (err) {
    console.error('[auth] OTP delivery failed:', err.message);
    await Otp.deleteMany({ phone });
    throw new AppError(
      'Failed to send OTP. Please try again later.',
      HTTP_STATUS.INTERNAL_SERVER_ERROR
    );
  }

  const response = {
    phone,
    expiresInSeconds: Math.floor(OTP_TTL_MS / 1000),
    resendAfterSeconds: config.otp.resendCooldownSeconds,
    provider: delivery.provider,
  };

  return response;
}

async function verifyOtp(rawPhone, otp) {
  const phone = normalizePhone(rawPhone);
  const record = await Otp.findOne({ phone }).sort({ createdAt: -1 });

  if (!record) {
    throw new AppError('OTP not requested or already used', HTTP_STATUS.BAD_REQUEST);
  }

  if (record.expiresAt.getTime() <= Date.now()) {
    await Otp.deleteOne({ _id: record._id });
    throw new AppError('OTP has expired. Please request a new one.', HTTP_STATUS.BAD_REQUEST);
  }

  if (record.attempts >= config.otp.maxAttempts) {
    await Otp.deleteOne({ _id: record._id });
    throw new AppError('Too many wrong attempts. Please request a new OTP.', HTTP_STATUS.BAD_REQUEST);
  }

  const isMatch = await compareOtp(otp, record.otpHash);

  if (!isMatch) {
    record.attempts += 1;

    // Invalidate the OTP once the attempt budget is exhausted.
    if (record.attempts >= config.otp.maxAttempts) {
      await Otp.deleteOne({ _id: record._id });
      throw new AppError(
        'Too many wrong attempts. Please request a new OTP.',
        HTTP_STATUS.BAD_REQUEST
      );
    }

    await record.save();

    const attemptsRemaining = config.otp.maxAttempts - record.attempts;
    throw new AppError('Invalid OTP', HTTP_STATUS.BAD_REQUEST, [
      { field: 'attemptsRemaining', message: String(attemptsRemaining) },
    ]);
  }

  await Otp.deleteOne({ _id: record._id });

  let user = await User.findOne({ phone });
  const isNewUser = !user;

  if (isNewUser) {
    user = await User.create({ phone });
  }

  const { accessToken, refreshToken } = await issueTokens(user);

  return {
    accessToken,
    refreshToken,
    isNewUser,
    profileCompleted: user.profileCompleted,
    user: user.toJSON(),
  };
}

async function refreshTokens(refreshToken) {
  let payload;

  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw new AppError('Invalid or expired refresh token', HTTP_STATUS.UNAUTHORIZED);
  }

  if (payload.type !== 'refresh') {
    throw new AppError('Invalid refresh token', HTTP_STATUS.UNAUTHORIZED);
  }

  const user = await User.findById(payload.sub).select('+refreshTokenHash');

  if (!user || !user.refreshTokenHash) {
    throw new AppError('Refresh token is no longer valid', HTTP_STATUS.UNAUTHORIZED);
  }

  // Rotation: the presented token must be the one currently on record.
  if (hashToken(refreshToken) !== user.refreshTokenHash) {
    throw new AppError('Refresh token has been revoked', HTTP_STATUS.UNAUTHORIZED);
  }

  return issueTokens(user);
}

async function logout(userId) {
  await User.findByIdAndUpdate(userId, { $set: { refreshTokenHash: null } });
}

module.exports = { sendOtp, verifyOtp, refreshTokens, logout };
