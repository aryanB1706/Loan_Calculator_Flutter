const Joi = require('joi');

const {
  LOAN_AMOUNT,
  LOAN_TENURE_MONTHS,
  LOAN_PURPOSE,
  LOAN_PAGINATION,
} = require('../constants/loanRules');

const loanTermsFields = {
  amount: Joi.number()
    .integer()
    .min(LOAN_AMOUNT.MIN)
    .max(LOAN_AMOUNT.MAX)
    .required()
    .messages({
      'number.base': 'amount must be a number',
      'number.integer': 'amount must be a whole number',
      'number.min': `amount must be at least ${LOAN_AMOUNT.MIN}`,
      'number.max': `amount must be at most ${LOAN_AMOUNT.MAX}`,
      'any.required': 'amount is required',
    }),
  tenureMonths: Joi.number()
    .integer()
    .min(LOAN_TENURE_MONTHS.MIN)
    .max(LOAN_TENURE_MONTHS.MAX)
    .required()
    .messages({
      'number.base': 'tenureMonths must be a number',
      'number.integer': 'tenureMonths must be a whole number',
      'number.min': `tenureMonths must be at least ${LOAN_TENURE_MONTHS.MIN}`,
      'number.max': `tenureMonths must be at most ${LOAN_TENURE_MONTHS.MAX}`,
      'any.required': 'tenureMonths is required',
    }),
};

const calculateLoanSchema = Joi.object(loanTermsFields);
const eligibilitySchema = Joi.object(loanTermsFields);

const applyLoanSchema = Joi.object({
  amount: loanTermsFields.amount,
  tenureMonths: loanTermsFields.tenureMonths,
  purpose: Joi.string()
    .trim()
    .min(LOAN_PURPOSE.MIN_LENGTH)
    .max(LOAN_PURPOSE.MAX_LENGTH)
    .required()
    .messages({
      'string.base': 'purpose must be a string',
      'string.empty': 'purpose is required',
      'string.min': `purpose must be at least ${LOAN_PURPOSE.MIN_LENGTH} characters`,
      'string.max': `purpose must be at most ${LOAN_PURPOSE.MAX_LENGTH} characters`,
      'any.required': 'purpose is required',
    }),
});

const listApplicationsQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(LOAN_PAGINATION.DEFAULT_PAGE).messages({
    'number.base': 'page must be a number',
    'number.integer': 'page must be a whole number',
    'number.min': 'page must be at least 1',
  }),
  limit: Joi.number()
    .integer()
    .min(1)
    .max(LOAN_PAGINATION.MAX_LIMIT)
    .default(LOAN_PAGINATION.DEFAULT_LIMIT)
    .messages({
      'number.base': 'limit must be a number',
      'number.integer': 'limit must be a whole number',
      'number.min': 'limit must be at least 1',
      'number.max': `limit must be at most ${LOAN_PAGINATION.MAX_LIMIT}`,
    }),
});

module.exports = {
  calculateLoanSchema,
  eligibilitySchema,
  applyLoanSchema,
  listApplicationsQuerySchema,
};
