const request = require('supertest');
const mongoose = require('mongoose');

const app = require('../src/app');
const config = require('../src/config');
const User = require('../src/models/User');
const Loan = require('../src/models/Loan');
const Counter = require('../src/models/Counter');
const { signAccessToken } = require('../src/utils/token');
const { LOAN_STATUS } = require('../src/constants/loanRules');

const PHONE = '9876500004';
const OTHER_PHONE = '9876500005';
const YEAR = new Date().getUTCFullYear();

const VALID_APPLICATION = {
  amount: 100000,
  tenureMonths: 12,
  purpose: 'Home renovation',
};

let user;
let otherUser;
let token;
let otherToken;

function yearsAgo(years) {
  const date = new Date();
  date.setUTCFullYear(date.getUTCFullYear() - years);
  return date;
}

function asUser(req, authToken = token) {
  return req.set('Authorization', `Bearer ${authToken}`);
}

async function createUser(phone, overrides = {}) {
  return User.create({
    phone,
    fullName: 'Aryan Kumar',
    dob: yearsAgo(30),
    gender: 'male',
    pan: 'ABCDE1234F',
    email: `${phone}@example.com`,
    monthlyIncome: 50000,
    employmentType: 'salaried',
    city: 'Delhi',
    profileCompleted: true,
    creditScore: 700,
    ...overrides,
  });
}

function apply(overrides = {}) {
  return asUser(request(app).post('/api/loans/apply')).send({
    ...VALID_APPLICATION,
    ...overrides,
  });
}

async function createApplication(userId, overrides = {}) {
  return Loan.create({
    user: userId,
    applicationNumber: `LN-${YEAR}-000001`,
    amount: 100000,
    tenureMonths: 12,
    interestRate: 12,
    emi: 8884.88,
    totalPayable: 106618.56,
    purpose: 'Test purpose',
    status: LOAN_STATUS.SUBMITTED,
    statusHistory: [
      {
        status: LOAN_STATUS.SUBMITTED,
        note: 'Application submitted',
        changedAt: new Date(),
      },
    ],
    ...overrides,
  });
}

beforeAll(async () => {
  await mongoose.connect(config.mongoUri);
  await Promise.all([User.init(), Loan.init(), Counter.init()]);
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

beforeEach(async () => {
  await Promise.all([Loan.deleteMany({}), Counter.deleteMany({}), User.deleteMany({})]);

  user = await createUser(PHONE);
  otherUser = await createUser(OTHER_PHONE, { pan: 'ABCDE1235F' });
  token = signAccessToken(user._id);
  otherToken = signAccessToken(otherUser._id);
});

describe('POST /api/loans/apply', () => {
  it('creates a submitted application for an eligible user', async () => {
    const res = await apply({ purpose: '  Home renovation  ' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);

    const application = res.body.data.application;
    expect(application.applicationNumber).toBe(`LN-${YEAR}-000001`);
    expect(application.user).toBe(user._id.toString());
    expect(application.amount).toBe(100000);
    expect(application.tenureMonths).toBe(12);
    expect(application.interestRate).toBe(12);
    expect(application.emi).toBe(8884.88);
    expect(application.totalPayable).toBe(106618.56);
    expect(application.purpose).toBe('Home renovation');
    expect(application.status).toBe(LOAN_STATUS.SUBMITTED);
    expect(application.statusHistory).toHaveLength(1);
    expect(application.statusHistory[0]).toEqual(
      expect.objectContaining({
        status: LOAN_STATUS.SUBMITTED,
        note: 'Application submitted',
        changedAt: expect.any(String),
      })
    );

    expect(await Loan.countDocuments({ user: user._id })).toBe(1);
  });

  it('rejects an ineligible user and does not save an application', async () => {
    user.creditScore = 550;
    await user.save();

    const res = await apply();

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('You are not eligible for this loan');
    expect(res.body.errors).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          field: 'eligibility',
          message: expect.stringContaining('at least 600'),
        }),
      ])
    );
    expect(await Loan.countDocuments({ user: user._id })).toBe(0);
  });

  it('blocks a second active application', async () => {
    const first = await apply();

    const res = await apply();

    expect(first.status).toBe(201);
    expect(res.status).toBe(409);
    expect(res.body.message).toContain('already have an active loan application');
    expect(res.body.message).toContain(first.body.data.application.applicationNumber);
    expect(await Loan.countDocuments({ user: user._id })).toBe(1);
  });

  it('also blocks a duplicate while the first application is under review', async () => {
    const first = await apply();
    await Loan.updateOne(
      { _id: first.body.data.application._id },
      { $set: { status: LOAN_STATUS.UNDER_REVIEW } }
    );

    const res = await apply();

    expect(res.status).toBe(409);
  });

  it('allows a new application after the previous one is rejected', async () => {
    const first = await apply();
    await Loan.updateOne(
      { _id: first.body.data.application._id },
      { $set: { status: LOAN_STATUS.REJECTED } }
    );

    const res = await apply();

    expect(res.status).toBe(201);
    expect(res.body.data.application.applicationNumber).toBe(`LN-${YEAR}-000002`);
  });

  it('requires a completed profile', async () => {
    user.profileCompleted = false;
    await user.save();

    const res = await apply();

    expect(res.status).toBe(422);
    expect(res.body.message).toContain('Complete your profile');
    expect(res.body.errors[0].field).toBe('profile');
    expect(await Loan.countDocuments({ user: user._id })).toBe(0);
  });

  it('requires a valid purpose', async () => {
    const res = await apply({ purpose: '  ' });

    expect(res.status).toBe(422);
    expect(res.body.errors[0].field).toBe('purpose');
  });

  it('requires authentication', async () => {
    const res = await request(app).post('/api/loans/apply').send(VALID_APPLICATION);

    expect(res.status).toBe(401);
  });
});

describe('GET /api/loans', () => {
  it('lists only the current user applications, newest first, with pagination', async () => {
    const older = await createApplication(user._id, {
      applicationNumber: `LN-${YEAR}-000001`,
      status: LOAN_STATUS.REJECTED,
    });
    const newer = await createApplication(user._id, {
      applicationNumber: `LN-${YEAR}-000002`,
      status: LOAN_STATUS.SUBMITTED,
    });
    await createApplication(otherUser._id, {
      applicationNumber: `LN-${YEAR}-000003`,
    });

    const firstPage = await asUser(request(app).get('/api/loans?page=1&limit=1'));

    expect(firstPage.status).toBe(200);
    expect(firstPage.body.data.applications).toHaveLength(1);
    expect(firstPage.body.data.applications[0]._id).toBe(newer._id.toString());
    expect(firstPage.body.data.pagination).toEqual({
      page: 1,
      limit: 1,
      total: 2,
      totalPages: 2,
    });

    const secondPage = await asUser(request(app).get('/api/loans?page=2&limit=1'));

    expect(secondPage.body.data.applications[0]._id).toBe(older._id.toString());
  });

  it('uses default pagination values', async () => {
    await createApplication(user._id);

    const res = await asUser(request(app).get('/api/loans'));

    expect(res.status).toBe(200);
    expect(res.body.data.pagination).toEqual({
      page: 1,
      limit: 10,
      total: 1,
      totalPages: 1,
    });
  });

  it('rejects an invalid pagination limit', async () => {
    const res = await asUser(request(app).get('/api/loans?limit=51'));

    expect(res.status).toBe(422);
    expect(res.body.errors[0].field).toBe('limit');
  });

  it('requires authentication', async () => {
    const res = await request(app).get('/api/loans');

    expect(res.status).toBe(401);
  });
});

describe('GET /api/loans/:id', () => {
  it('returns the application with its status history to the owner', async () => {
    const application = await createApplication(user._id);

    const res = await asUser(request(app).get(`/api/loans/${application._id}`));

    expect(res.status).toBe(200);
    expect(res.body.data.application._id).toBe(application._id.toString());
    expect(res.body.data.application.statusHistory).toHaveLength(1);
    expect(res.body.data.application.statusHistory[0].status).toBe(LOAN_STATUS.SUBMITTED);
  });

  it('hides another user application', async () => {
    const application = await createApplication(user._id);

    const res = await asUser(request(app).get(`/api/loans/${application._id}`), otherToken);

    expect(res.status).toBe(404);
  });

  it('returns 404 for a malformed application id', async () => {
    const res = await asUser(request(app).get('/api/loans/not-an-id'));

    expect(res.status).toBe(404);
  });

  it('requires authentication', async () => {
    const application = await createApplication(user._id);

    const res = await request(app).get(`/api/loans/${application._id}`);

    expect(res.status).toBe(401);
  });
});
