process.env.OTP_MODE = 'demo';

const { spawnSync } = require('child_process');
const path = require('path');
const request = require('supertest');
const mongoose = require('mongoose');

const app = require('../src/app');
const config = require('../src/config');
const Otp = require('../src/models/Otp');
const User = require('../src/models/User');

const PHONE = '9123456780';

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
});

describe('OTP_MODE=demo', () => {
  it('accepts only the fixed 123456 OTP and sends no SMS', async () => {
    const sendRes = await request(app).post('/api/auth/send-otp').send({ phone: PHONE });

    expect(sendRes.status).toBe(200);
    expect(sendRes.body.data.provider).toBe('demo');
    expect(sendRes.body.data.otp).toBeUndefined();
    expect(sendRes.body.data.demoOtp).toBe('123456');

    const wrongRes = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: PHONE, otp: '654321' });
    expect(wrongRes.status).toBe(400);

    const res = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: PHONE, otp: '123456' });
    expect(res.status).toBe(200);
    expect(res.body.data.accessToken).toEqual(expect.any(String));
    expect(res.body.data.isNewUser).toBe(true);
  });

  it('is rejected when NODE_ENV=production', () => {
    const result = spawnSync(process.execPath, ['-e', "require('./src/config')"], {
      cwd: path.join(__dirname, '..'),
      env: { ...process.env, NODE_ENV: 'production', OTP_MODE: 'demo' },
      encoding: 'utf8',
    });

    expect(result.status).toBe(1);
    expect(result.stderr).toContain('OTP_MODE=demo is not allowed');
  });
});
