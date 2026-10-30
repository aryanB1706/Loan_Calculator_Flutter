const AppError = require('../utils/AppError');
const { HTTP_STATUS, MESSAGES } = require('../constants');

/**
 * Validates req.body against a Joi schema and replaces it with the sanitized
 * value (unknown fields stripped, strings trimmed).
 */
const validate = (schema) => (req, _res, next) => {
  const { error, value } = schema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    const errors = error.details.map((detail) => ({
      field: detail.path.join('.'),
      message: detail.message.replace(/"/g, ''),
    }));

    return next(new AppError(MESSAGES.VALIDATION_FAILED, HTTP_STATUS.UNPROCESSABLE_ENTITY, errors));
  }

  req.body = value;
  return next();
};

module.exports = validate;
