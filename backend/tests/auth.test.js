const request = require('supertest');
const mongoose = require('mongoose');

const app = require('../src/app');
const config = require('../src/config');
const Otp = require('../src/models/Otp');
const User = require('../src/models/User');
const otpService = require('../src/services/otp');

const PHONE = '9876543210';

let lastOtp;

function wrongOtp(otp) {
  return otp === '000000' ? '111111' : '000000';
}

function sendOtp(phone = PHONE) {
  return request(app).post('/api/auth/send-otp').send({ phone });
}

function verifyOtp(phone, otp) {
  return request(app).post('/api/auth/verify-otp').send({ phone, otp });
}

beforeAll(async () => {
  await mongoose.connect(config.mongoUri);
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

beforeEach(async () => {
  await Otp.deleteMany({});
  await User.deleteMany({});
  lastOtp = undefined;

  // Capture the generated OTP without depending on a real SMS provider.
  jest.spyOn(otpService, 'getOtpSender').mockReturnValue({
    send: async (_phone, otp) => {
      lastOtp = otp;
      return { provider: 'test' };
    },
  });
});

afterEach(() => {
  jest.restoreAllMocks();
});

describe('POST /api/auth/send-otp', () => {
  it('sends an OTP and does not expose it outside development', async () => {
    const res = await sendOtp();

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.phone).toBe(PHONE);
    expect(res.body.data.otp).toBeUndefined();
    expect(lastOtp).toMatch(/^\d{6}$/);

    const stored = await Otp.findOne({ phone: PHONE });
    expect(stored).not.toBeNull();
    expect(stored.otpHash).not.toBe(lastOtp);
  });

  it('rejects invalid Indian mobile numbers', async () => {
    const res = await sendOtp('1234567890');

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.errors[0].field).toBe('phone');
  });

  it('enforces the resend cooldown', async () => {
    expect((await sendOtp()).status).toBe(200);

    const res = await sendOtp();

    expect(res.status).toBe(429);
    expect(res.body.success).toBe(false);
    expect(res.body.errors[0].field).toBe('retryAfterSeconds');
  });
});

describe('POST /api/auth/verify-otp', () => {
  it('creates a user, returns tokens, and logout revokes the refresh token', async () => {
    await sendOtp();

    const res = await verifyOtp(PHONE, lastOtp);

    expect(res.status).toBe(200);
    expect(res.body.data.isNewUser).toBe(true);
    expect(res.body.data.profileCompleted).toBe(false);
    expect(res.body.data.accessToken).toEqual(expect.any(String));
    expect(res.body.data.refreshToken).toEqual(expect.any(String));
    expect(res.body.data.user.phone).toBe(PHONE);
    expect(res.body.data.user.refreshTokenHash).toBeUndefined();

    const storedUser = await User.findOne({ phone: PHONE }).select('+refreshTokenHash');
    expect(storedUser).not.toBeNull();
    expect(storedUser.refreshTokenHash).toEqual(expect.any(String));
    expect(storedUser.refreshTokenHash).not.toBe(res.body.data.refreshToken);

    const logoutRes = await request(app)
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${res.body.data.accessToken}`);
    expect(logoutRes.status).toBe(200);

    const refreshRes = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: res.body.data.refreshToken });
    expect(refreshRes.status).toBe(401);
  });

  it('reuses the existing user on later logins', async () => {
    await User.create({ phone: PHONE });
    await sendOtp();

    const res = await verifyOtp(PHONE, lastOtp);

    expect(res.status).toBe(200);
    expect(res.body.data.isNewUser).toBe(false);
    expect(await User.countDocuments({ phone: PHONE })).toBe(1);
  });

  it('invalidates the OTP after 3 wrong attempts', async () => {
    await sendOtp();

    for (let attempt = 0; attempt < 2; attempt += 1) {
      const res = await verifyOtp(PHONE, wrongOtp(lastOtp));
      expect(res.status).toBe(400);
      expect(res.body.message).toBe('Invalid OTP');
    }

    const thirdRes = await verifyOtp(PHONE, wrongOtp(lastOtp));
    expect(thirdRes.status).toBe(400);
    expect(thirdRes.body.message).toMatch(/Too many wrong attempts/);

    const correctRes = await verifyOtp(PHONE, lastOtp);
    expect(correctRes.status).toBe(400);
    expect(await Otp.countDocuments({ phone: PHONE })).toBe(0);
  });

  it('rejects an expired OTP', async () => {
    await sendOtp();

    await Otp.updateMany({ phone: PHONE }, { $set: { expiresAt: new Date(Date.now() - 1000) } });

    const res = await verifyOtp(PHONE, lastOtp);

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/expired/i);
  });
});

describe('POST /api/auth/refresh', () => {
  it('rotates the refresh token and rejects reuse of the old one', async () => {
    await sendOtp();
    const verifyRes = await verifyOtp(PHONE, lastOtp);
    const { refreshToken } = verifyRes.body.data;

    const res = await request(app).post('/api/auth/refresh').send({ refreshToken });

    expect(res.status).toBe(200);
    expect(res.body.data.accessToken).toEqual(expect.any(String));
    expect(res.body.data.refreshToken).toEqual(expect.any(String));
    expect(res.body.data.refreshToken).not.toBe(refreshToken);

    const reuseRes = await request(app).post('/api/auth/refresh').send({ refreshToken });
    expect(reuseRes.status).toBe(401);
  });

  it('rejects an invalid refresh token', async () => {
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: 'not-a-real-token' });

    expect(res.status).toBe(401);
  });
});
