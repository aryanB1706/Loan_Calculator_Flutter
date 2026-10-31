const mongoose = require('mongoose');

const { GENDERS, EMPLOYMENT_TYPES } = require('../constants');
const { CREDIT_SCORE } = require('../constants/creditScoreRules');
const { PAN_REGEX } = require('../utils/pan');
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
    fullName: {
      type: String,
      trim: true,
    },
    dob: {
      type: Date,
    },
    gender: {
      type: String,
      enum: GENDERS,
    },
    // sparse + unique lets many users exist without a PAN during onboarding.
    pan: {
      type: String,
      trim: true,
      uppercase: true,
      match: [PAN_REGEX, 'Invalid PAN format'],
      unique: true,
      sparse: true,
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
    },
    monthlyIncome: {
      type: Number,
      min: 0,
    },
    employmentType: {
      type: String,
      enum: EMPLOYMENT_TYPES,
    },
    city: {
      type: String,
      trim: true,
    },
    profileCompleted: {
      type: Boolean,
      default: false,
    },
    creditScore: {
      type: Number,
      default: CREDIT_SCORE.DEFAULT,
      min: CREDIT_SCORE.MIN,
      max: CREDIT_SCORE.MAX,
    },
    // Device tokens for later FCM work; never exposed through the API.
    fcmTokens: {
      type: [String],
      default: [],
      select: false,
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
    delete ret.fcmTokens;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('User', userSchema);
