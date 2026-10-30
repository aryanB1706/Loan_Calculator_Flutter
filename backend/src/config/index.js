const Joi = require('joi');

require('dotenv').config();

const envSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
  PORT: Joi.number().port().default(5000),

  MONGO_URI: Joi.string()
    .pattern(/^mongodb(\+srv)?:\/\//)
    .required()
    .messages({
      'string.pattern.base': 'MONGO_URI must start with mongodb:// or mongodb+srv://',
    }),

  CORS_ORIGIN: Joi.string().default('*'),

  // Optional in development/test so the rest of the API keeps working without
  // admin access. Required in production (checked below).
  ADMIN_API_KEY: Joi.string().min(16).optional(),

  JWT_ACCESS_SECRET: Joi.string().min(32).required(),
  JWT_ACCESS_EXPIRES_IN: Joi.string().default('15m'),
  JWT_REFRESH_SECRET: Joi.string().min(32).required(),
  JWT_REFRESH_EXPIRES_IN: Joi.string().default('7d'),

  OTP_MODE: Joi.string().valid('demo', 'console', 'sms').default('console'),
  OTP_SMS_PROVIDER: Joi.string().valid('fast2sms', 'msg91').default('msg91'),
  OTP_EXPIRES_IN_MINUTES: Joi.number().integer().positive().default(5),
  OTP_RESEND_COOLDOWN_SECONDS: Joi.number().integer().positive().default(30),
  OTP_MAX_ATTEMPTS: Joi.number().integer().positive().default(3),

  RATE_LIMIT_WINDOW_MS: Joi.number()
    .integer()
    .positive()
    .default(15 * 60 * 1000),
  RATE_LIMIT_MAX: Joi.number().integer().positive().default(100),
  SEND_OTP_RATE_LIMIT_WINDOW_MS: Joi.number()
    .integer()
    .positive()
    .default(15 * 60 * 1000),
  SEND_OTP_RATE_LIMIT_MAX: Joi.number().integer().positive().default(5),
}).unknown();

const { error, value: env } = envSchema.validate(process.env, {
  abortEarly: false,
  stripUnknown: false,
});

if (error) {
  console.error(
    `Invalid environment configuration:\n${error.details.map((d) => `  - ${d.message}`).join('\n')}`
  );
  process.exit(1);
}

// Demo mode uses a publicly known OTP, so it must never be enabled in production.
if (env.NODE_ENV === 'production' && env.OTP_MODE === 'demo') {
  console.error(
    'Invalid environment configuration:\n  - OTP_MODE=demo is not allowed when NODE_ENV=production'
  );
  process.exit(1);
}

// Admin endpoints are dangerously powerful, so production must configure them.
if (env.NODE_ENV === 'production' && !env.ADMIN_API_KEY) {
  console.error(
    'Invalid environment configuration:\n  - ADMIN_API_KEY is required when NODE_ENV=production'
  );
  process.exit(1);
}

const config = Object.freeze({
  env: env.NODE_ENV,
  isProduction: env.NODE_ENV === 'production',
  isTest: env.NODE_ENV === 'test',
  port: env.PORT,
  mongoUri: env.MONGO_URI,
  corsOrigin: env.CORS_ORIGIN === '*' ? '*' : env.CORS_ORIGIN.split(',').map((o) => o.trim()),
  adminApiKey: env.ADMIN_API_KEY || null,
  jwt: {
    accessSecret: env.JWT_ACCESS_SECRET,
    accessExpiresIn: env.JWT_ACCESS_EXPIRES_IN,
    refreshSecret: env.JWT_REFRESH_SECRET,
    refreshExpiresIn: env.JWT_REFRESH_EXPIRES_IN,
  },
  otp: {
    mode: env.OTP_MODE,
    smsProvider: env.OTP_SMS_PROVIDER,
    expiresInMinutes: env.OTP_EXPIRES_IN_MINUTES,
    resendCooldownSeconds: env.OTP_RESEND_COOLDOWN_SECONDS,
    maxAttempts: env.OTP_MAX_ATTEMPTS,
  },
  rateLimit: {
    windowMs: env.RATE_LIMIT_WINDOW_MS,
    max: env.RATE_LIMIT_MAX,
    sendOtpWindowMs: env.SEND_OTP_RATE_LIMIT_WINDOW_MS,
    sendOtpMax: env.SEND_OTP_RATE_LIMIT_MAX,
  },
});

module.exports = config;
