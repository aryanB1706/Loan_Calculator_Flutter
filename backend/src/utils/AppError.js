class AppError extends Error {
  /**
   * @param {string} message - Human readable error message
   * @param {number} statusCode - HTTP status code
   * @param {Array|Object} [errors] - Optional field level error details
   */
  constructor(message, statusCode, errors) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.errors = errors;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = AppError;
