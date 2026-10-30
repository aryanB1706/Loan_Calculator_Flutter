const request = require('supertest');
const mongoose = require('mongoose');

const app = require('../src/app');
const config = require('../src/config');
const User = require('../src/models/User');
const { signAccessToken } = require('../src/utils/token');

const PHONE = '9876500001';

let user;
let token;

function asUser(req) {
  return req.set('Authorization', `Bearer ${token}`);
}

function yearsAgo(years) {
  const date = new Date();
  date.setUTCFullYear(date.getUTCFullYear() - years);
  return date.toISOString().slice(0, 10);
}

function validProfile() {
  return {
    fullName: 'Aryan Kumar',
    dob: yearsAgo(25),
    gender: 'male',
    pan: 'abcde1234f',
    email: 'ARYAN@EXAMPLE.COM',
    monthlyIncome: 50000,
    employmentType: 'salaried',
    city: 'Delhi',
  };
}

beforeAll(async () => {
  await mongoose.connect(config.mongoUri);
  await User.init();
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

beforeEach(async () => {
  await User.deleteMany({});
  user = await User.create({
    phone: PHONE,
    refreshTokenHash: 'stored-refresh-hash',
    fcmTokens: ['device-token'],
  });
  token = signAccessToken(user._id);
});

describe('GET /api/users/me', () => {
  it('returns the profile without sensitive fields', async () => {
    const res = await asUser(request(app).get('/api/users/me'));

    expect(res.status).toBe(200);
    expect(res.body.data.user.phone).toBe(PHONE);
    expect(res.body.data.user.creditScore).toBe(650);
    expect(res.body.data.user.profileCompleted).toBe(false);
    expect(res.body.data.user.refreshTokenHash).toBeUndefined();
    expect(res.body.data.user.fcmTokens).toBeUndefined();
  });

  it('requires authentication', async () => {
    const res = await request(app).get('/api/users/me');

    expect(res.status).toBe(401);
  });
});

describe('PUT /api/users/me', () => {
  it('updates the full profile, normalizes values, and marks it complete', async () => {
    const res = await asUser(request(app).put('/api/users/me')).send(validProfile());

    expect(res.status).toBe(200);
    expect(res.body.data.user.profileCompleted).toBe(true);
    expect(res.body.data.user.pan).toBe('ABCDE1234F');
    expect(res.body.data.user.email).toBe('aryan@example.com');
    expect(res.body.data.user.fullName).toBe('Aryan Kumar');
    expect(res.body.data.user.creditScore).toBe(650);

    const stored = await User.findById(user._id);
    expect(stored.profileCompleted).toBe(true);
    expect(stored.pan).toBe('ABCDE1234F');
  });

  it('keeps profileCompleted false until every required field exists', async () => {
    const res = await asUser(request(app).put('/api/users/me')).send({ city: 'Mumbai' });

    expect(res.status).toBe(200);
    expect(res.body.data.user.city).toBe('Mumbai');
    expect(res.body.data.user.profileCompleted).toBe(false);
  });

  it('keeps profileCompleted true after a later partial update', async () => {
    await asUser(request(app).put('/api/users/me')).send(validProfile());

    const res = await asUser(request(app).put('/api/users/me')).send({ city: 'Mumbai' });

    expect(res.status).toBe(200);
    expect(res.body.data.user.city).toBe('Mumbai');
    expect(res.body.data.user.profileCompleted).toBe(true);
  });

  it('rejects a PAN already used by another user', async () => {
    await User.create({ phone: '9876500002', pan: 'ABCDE1234F' });

    const res = await asUser(request(app).put('/api/users/me')).send({
      pan: 'ABCDE1234F',
    });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Duplicate value/);
  });

  describe('validation', () => {
    const cases = [
      ['an invalid PAN', { pan: 'ABCDE123' }, 'pan'],
      ['an underage DOB', { dob: yearsAgo(17) }, 'dob'],
      ['an invalid email', { email: 'not-an-email' }, 'email'],
      ['zero income', { monthlyIncome: 0 }, 'monthlyIncome'],
      ['an invalid gender', { gender: 'unknown' }, 'gender'],
      ['an invalid employment type', { employmentType: 'business' }, 'employmentType'],
      ['an empty body', {}, null],
    ];

    it.each(cases)('rejects %s', async (_label, body, field) => {
      const res = await asUser(request(app).put('/api/users/me')).send(body);

      expect(res.status).toBe(422);
      expect(res.body.success).toBe(false);
      if (field) expect(res.body.errors[0].field).toBe(field);
    });
  });
});
