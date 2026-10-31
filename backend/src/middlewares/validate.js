const AppError = require('../utils/AppError');
const { HTTP_STATUS, MESSAGES } = require('../constants');

/**
 * Validates a request part (body by default) against a Joi schema and replaces
 * it with the sanitized value (unknown fields stripped, strings trimmed).
 */
const validate =
  (schema, source = 'body') =>
  (req, _res, next) => {
    const { error, value } = schema.validate(req[source], {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message.replace(/"/g, ''),
      }));

      return next(
        new AppError(MESSAGES.VALIDATION_FAILED, HTTP_STATUS.UNPROCESSABLE_ENTITY, errors)
      );
    }

    req[source] = value;
    return next();
  };

module.exports = validate;
