const mongoose = require('mongoose');

const { INDIAN_MOBILE_REGEX } = require('../utils/phone');

const userSchema = new mongoose.Schema(
  {
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      match: [INDIAN_MOBILE_REGEX, 'Invalid Indian mobile number'],
    },
    profileCompleted: {
      type: Boolean,
      default: false,
    },
    // Only the hash is stored so a leaked database cannot be used to mint tokens.
    refreshTokenHash: {
      type: String,
      default: null,
      select: false,
    },
  },
  { timestamps: true }
);

userSchema.set('toJSON', {
  transform: (_doc, ret) => {
    delete ret.refreshTokenHash;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('User', userSchema);
