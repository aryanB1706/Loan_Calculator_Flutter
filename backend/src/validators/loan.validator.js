const Joi = require('joi');

const { LOAN_AMOUNT, LOAN_TENURE_MONTHS } = require('../constants/loanRules');

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

module.exports = { calculateLoanSchema, eligibilitySchema };
