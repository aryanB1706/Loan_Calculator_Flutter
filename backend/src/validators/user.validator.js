const Joi = require('joi');

const { GENDERS, EMPLOYMENT_TYPES } = require('../constants');
const { calculateAge } = require('../utils/date');
const { PAN_REGEX } = require('../utils/pan');

const MIN_AGE = 18;

const profileUpdateSchema = Joi.object({
  fullName: Joi.string().trim().min(2).max(100),
  dob: Joi.date()
    .iso()
    .custom((value, helpers) => {
      if (calculateAge(value) < MIN_AGE) {
        return helpers.error('date.minAge');
      }
      return value;
    })
    .messages({
      'date.minAge': `You must be at least ${MIN_AGE} years old`,
      'date.format': 'dob must be a valid ISO date (YYYY-MM-DD)',
    }),
  gender: Joi.string().valid(...GENDERS),
  pan: Joi.string()
    .trim()
    .uppercase()
    .pattern(PAN_REGEX)
    .messages({
      'string.pattern.base': 'pan must match the format ABCDE1234F',
    }),
  email: Joi.string().trim().lowercase().email(),
  monthlyIncome: Joi.number().positive().messages({
    'number.positive': 'monthlyIncome must be greater than 0',
  }),
  employmentType: Joi.string().valid(...EMPLOYMENT_TYPES),
  city: Joi.string().trim().min(2).max(100),
})
  .min(1)
  .messages({
    'object.min': 'At least one profile field is required',
  });

module.exports = { profileUpdateSchema };
