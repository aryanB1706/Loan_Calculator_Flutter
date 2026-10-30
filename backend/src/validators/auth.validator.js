const Joi = require('joi');

const { INDIAN_MOBILE_REGEX } = require('../utils/phone');

const phone = Joi.string()
  .trim()
  .pattern(INDIAN_MOBILE_REGEX)
  .required()
  .messages({
    'string.pattern.base': 'phone must be a valid Indian mobile number (10 digits starting 6-9, optional +91)',
    'any.required': 'phone is required',
  });

const sendOtpSchema = Joi.object({ phone });

const verifyOtpSchema = Joi.object({
  phone,
  otp: Joi.string()
    .pattern(/^\d{6}$/)
    .required()
    .messages({
      'string.pattern.base': 'otp must be a 6 digit code',
      'any.required': 'otp is required',
    }),
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required().messages({
    'any.required': 'refreshToken is required',
  }),
});

module.exports = { sendOtpSchema, verifyOtpSchema, refreshTokenSchema };
