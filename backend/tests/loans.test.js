const request = require('supertest');
const mongoose = require('mongoose');

const app = require('../src/app');
const config = require('../src/config');
const User = require('../src/models/User');
const { signAccessToken } = require('../src/utils/token');

const PHONE = '9876500003';

let user;
let token;

function yearsAgo(years) {
  const date = new Date();
  date.setUTCFullYear(date.getUTCFullYear() - years);
  return date;
}

function asUser(req) {
  return req.set('Authorization', `Bearer ${token}`);
}

beforeAll(async () => {
  await mongoose.connect(config.mongoUri);
});
afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

beforeEach(async () => {
  await User.deleteMany({});
  user = await User.create({
    phone: PHONE,
    fullName: 'Aryan Kumar',
    dob: yearsAgo(30),
    gender: 'male',
    pan: 'ABCDE1234F',
    email: 'aryan@example.com',
    monthlyIncome: 50000,
    employmentType: 'salaried',
    city: 'Delhi',
    profileCompleted: true,
    creditScore: 700,
  });
  token = signAccessToken(user._id);
});

describe('POST /api/loans/calculate', () => {
  it('is public and returns the EMI breakdown', async () => {
    const res = await request(app)
      .post('/api/loans/calculate')
      .send({ amount: 100000, tenureMonths: 12 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toEqual({
      emi: 8884.88,
      totalPayable: 106618.56,
      totalInterest: 6618.56,
      interestRate: 12,
    });
  });

  it('rejects an amount below the minimum', async () => {
    const res = await request(app)
      .post('/api/loans/calculate')
      .send({ amount: 9999, tenureMonths: 12 });

    expect(res.status).toBe(422);
    expect(res.body.errors[0].field).toBe('amount');
  });

  it('rejects a tenure above the maximum', async () => {
    const res = await request(app)
      .post('/api/loans/calculate')
      .send({ amount: 100000, tenureMonths: 61 });

    expect(res.status).toBe(422);
    expect(res.body.errors[0].field).toBe('tenureMonths');
  });
});

describe('POST /api/loans/eligibility', () => {
  it('requires authentication', async () => {
    const res = await request(app)
      .post('/api/loans/eligibility')
      .send({ amount: 100000, tenureMonths: 12 });

    expect(res.status).toBe(401);
  });

  it('returns an eligible decision for a valid profile', async () => {
    const res = await asUser(request(app).post('/api/loans/eligibility')).send({
      amount: 100000,
      tenureMonths: 12,
    });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({
      eligible: true,
      maxEligibleAmount: 500000,
      reasons: [],
    });
  });

  it('returns plain-language reasons when a rule fails', async () => {
    user.monthlyIncome = 40000;
    await user.save();

    const res = await asUser(request(app).post('/api/loans/eligibility')).send({
      amount: 450000,
      tenureMonths: 60,
    });

    expect(res.status).toBe(200);
    expect(res.body.data.eligible).toBe(false);
    expect(res.body.data.maxEligibleAmount).toBe(400000);
    expect(res.body.data.reasons[0]).toContain('maximum loan amount you are eligible for');
  });
});
