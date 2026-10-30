const mongoose = require('mongoose');

const config = require('../config');
const { HTTP_STATUS, MESSAGES } = require('../constants');
const AppError = require('../utils/AppError');

/** 404 handler: runs when no route matched the request. */
function notFoundHandler(req, _res, next) {
  next(new AppError(`${MESSAGES.ROUTE_NOT_FOUND}: ${req.method} ${req.originalUrl}`, HTTP_STATUS.NOT_FOUND));
}

/**
 * Converts known error types (AppError, Mongoose, JWT) into the project-wide
 * error shape: { success: false, message, errors? }.
 */
function errorHandler(err, req, res, _next) {
  let statusCode = err.statusCode || HTTP_STATUS.INTERNAL_SERVER_ERROR;
  let message = err.message || MESSAGES.INTERNAL_ERROR;
  let errors = err.errors;

  if (err instanceof mongoose.Error.ValidationError) {
    statusCode = HTTP_STATUS.UNPROCESSABLE_ENTITY;
    message = MESSAGES.VALIDATION_FAILED;
    errors = Object.values(err.errors).map((e) => ({
      field: e.path,
      message: e.message,
    }));
  } else if (err instanceof mongoose.Error.CastError) {
    statusCode = HTTP_STATUS.BAD_REQUEST;
    message = `Invalid value for field "${err.path}"`;
  } else if (err.code === 11000) {
    statusCode = HTTP_STATUS.CONFLICT;
    message = `Duplicate value for field "${Object.keys(err.keyValue || {}).join(', ')}"`;
  } else if (err.name === 'JsonWebTokenError') {
    statusCode = HTTP_STATUS.UNAUTHORIZED;
    message = 'Invalid authentication token';
  } else if (err.name === 'TokenExpiredError') {
    statusCode = HTTP_STATUS.UNAUTHORIZED;
    message = 'Authentication token expired';
  }

  if (!err.isOperational && statusCode === HTTP_STATUS.INTERNAL_SERVER_ERROR) {
    console.error('[error] Unhandled error:', err);
  }

  const body = { success: false, message };

  if (errors) body.errors = errors;
  // Expose stack traces only in development to help debugging.
  if (!config.isProduction && !err.isOperational) body.stack = err.stack;

  return res.status(statusCode).json(body);
}

module.exports = { notFoundHandler, errorHandler };
