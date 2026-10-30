const mongoose = require('mongoose');

const { INDIAN_MOBILE_REGEX } = require('../utils/phone');

const otpSchema = new mongoose.Schema(
  {
    phone: {
      type: String,
      required: true,
      trim: true,
      match: [INDIAN_MOBILE_REGEX, 'Invalid Indian mobile number'],
    },
    otpHash: {
      type: String,
      required: true,
    },
    expiresAt: {
      type: Date,
      required: true,
    },
    attempts: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

// TTL index: MongoDB removes expired OTPs automatically. Application code still
// checks expiry because the TTL monitor runs about once per minute.
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
otpSchema.index({ phone: 1, createdAt: -1 });

module.exports = mongoose.model('Otp', otpSchema);
