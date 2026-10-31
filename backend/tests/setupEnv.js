process.env.NODE_ENV = 'test';
process.env.PORT = '5001';
// Tests wipe their collections, so only a database named *_test is accepted.
// Set TEST_MONGO_URI to run them against a remote MongoDB (e.g. Atlas).
const testMongoUri = process.env.TEST_MONGO_URI || 'mongodb://127.0.0.1:27017/loan_calc_test';
const databaseName = new URL(testMongoUri).pathname.slice(1);

if (!databaseName.endsWith('_test')) {
  throw new Error(
    `Refusing to run tests against database "${databaseName}": name must end in _test`
  );
}

process.env.MONGO_URI = testMongoUri;
process.env.CORS_ORIGIN = '*';
process.env.ADMIN_API_KEY = 'test_admin_api_key_for_tests_only';
process.env.JWT_ACCESS_SECRET = 'test_access_secret_that_is_at_least_32_chars';
process.env.JWT_ACCESS_EXPIRES_IN = '15m';
process.env.JWT_REFRESH_SECRET = 'test_refresh_secret_that_is_at_least_32_chars';
process.env.JWT_REFRESH_EXPIRES_IN = '7d';
process.env.OTP_MODE = 'console';
process.env.OTP_SMS_PROVIDER = 'msg91';
process.env.OTP_EXPIRES_IN_MINUTES = '5';
process.env.OTP_RESEND_COOLDOWN_SECONDS = '30';
process.env.OTP_MAX_ATTEMPTS = '3';
process.env.RATE_LIMIT_WINDOW_MS = '900000';
process.env.RATE_LIMIT_MAX = '1000';
process.env.SEND_OTP_RATE_LIMIT_WINDOW_MS = '900000';
process.env.SEND_OTP_RATE_LIMIT_MAX = '1000';
