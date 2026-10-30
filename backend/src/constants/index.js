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
  BAD_GATEWAY: 502,
  SERVICE_UNAVAILABLE: 503,
});

const GENDERS = Object.freeze(['male', 'female', 'other']);
const EMPLOYMENT_TYPES = Object.freeze(['salaried', 'self-employed']);
const DEFAULT_CREDIT_SCORE = 650;

const MESSAGES = Object.freeze({
  HEALTH_OK: 'Service is healthy',
  ROUTE_NOT_FOUND: 'Route not found',
  INTERNAL_ERROR: 'Something went wrong',
  VALIDATION_FAILED: 'Validation failed',
  RATE_LIMIT_EXCEEDED: 'Too many requests, please try again later',
  OTP_SENT: 'OTP sent successfully',
  OTP_VERIFIED: 'OTP verified successfully',
  TOKENS_REFRESHED: 'Tokens refreshed successfully',
  LOGGED_OUT: 'Logged out successfully',
  PROFILE_FETCHED: 'Profile fetched successfully',
  PROFILE_UPDATED: 'Profile updated successfully',
  USER_NOT_FOUND: 'User not found',
});

module.exports = {
  HTTP_STATUS,
  MESSAGES,
  GENDERS,
  EMPLOYMENT_TYPES,
  DEFAULT_CREDIT_SCORE,
};
