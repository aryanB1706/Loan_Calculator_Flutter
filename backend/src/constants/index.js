const HTTP_STATUS = Object.freeze({
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_SERVER_ERROR: 500,
});

const MESSAGES = Object.freeze({
  HEALTH_OK: 'Service is healthy',
  ROUTE_NOT_FOUND: 'Route not found',
  INTERNAL_ERROR: 'Something went wrong',
  VALIDATION_FAILED: 'Validation failed',
  RATE_LIMIT_EXCEEDED: 'Too many requests, please try again later',
});

module.exports = { HTTP_STATUS, MESSAGES };
