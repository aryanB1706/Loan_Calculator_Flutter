const Joi = require('joi');

const { LOAN_STATUS_VALUES } = require('../constants/loanRules');

const adminStatusUpdateSchema = Joi.object({
  status: Joi.string()
    .valid(...LOAN_STATUS_VALUES)
    .required()
    .messages({
      'string.base': 'status must be a string',
      'any.only': `status must be one of: ${LOAN_STATUS_VALUES.join(', ')}`,
      'any.required': 'status is required',
    }),
  note: Joi.string().trim().max(500).allow('').optional().messages({
    'string.base': 'note must be a string',
    'string.max': 'note must be at most 500 characters',
  }),
});

module.exports = { adminStatusUpdateSchema };
