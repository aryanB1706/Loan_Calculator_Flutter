const request = require('supertest');
const mongoose = require('mongoose');

const app = require('../src/app');
const config = require('../src/config');
const User = require('../src/models/User');
const Loan = require('../src/models/Loan');
const Repayment = require('../src/models/Repayment');
const CreditScoreLog = require('../src/models/CreditScoreLog');
const { signAccessToken } = require('../src/utils/token');
const loanWorkflowService = require('../src/services/loanWorkflow.service');
const repaymentService = require('../src/services/repayment.service');
const { LOAN_STATUS } = require('../src/constants/loanRules');
const { REPAYMENT_STATUS } = require('../src/constants/repaymentRules');
const { CREDIT_SCORE_CHANGES } = require('../src/constants/creditScoreRules');

const PHONE = '9876500101';
const OTHER_PHONE = '9876500102';
const YEAR = new Date().getUTCFullYear();

let user;
let otherUser;
let token;
let otherToken;
let applicationSequence;

function yearsAgo(years) {
  const date = new Date();
  date.setUTCFullYear(date.getUTCFullYear() - years);
  return date;
}

function asUser(req, authToken = token) {
  return req.set('Authorization', `Bearer ${authToken}`);
}

async function createUser(phone, pan, overrides = {}) {
  return User.create({
    phone,
    fullName: 'Aryan Kumar',
    dob: yearsAgo(30),
    gender: 'male',
    pan,
    email: `${phone}@example.com`,
    monthlyIncome: 50000,
    employmentType: 'salaried',
    city: 'Delhi',
    profileCompleted: true,
    ...overrides,
  });
}

async function createLoan(status = LOAN_STATUS.APPROVED, overrides = {}) {
  applicationSequence += 1;

  return Loan.create({
    user: user._id,
    applicationNumber: `LN-${YEAR}-${String(applicationSequence).padStart(6, '0')}`,
    amount: 100000,
    tenureMonths: 12,
    interestRate: 12,
    emi: 8884.88,
    totalPayable: 106618.56,
    purpose: 'Test purpose',
    status,
    statusHistory: [
      {
        status,
        note: 'Created for test',
        changedAt: new Date(),
      },
    ],
    ...overrides,
  });
}

async function disburse(loan) {
  await loanWorkflowService.transitionLoan(loan, LOAN_STATUS.DISBURSED);
  return loan;
}

function getRepayments(loanId, authToken = token) {
  return asUser(request(app).get(`/api/loans/${loanId}/repayments`), authToken);
}

function payInstallment(loanId, installmentNumber, authToken = token) {
  return asUser(
    request(app).post(`/api/loans/${loanId}/repayments/${installmentNumber}/pay`),
    authToken
  );
}

beforeAll(async () => {
  await mongoose.connect(config.mongoUri);
  await Promise.all([User.init(), Loan.init(), Repayment.init(), CreditScoreLog.init()]);
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

beforeEach(async () => {
  await Promise.all([
    Repayment.deleteMany({}),
    CreditScoreLog.deleteMany({}),
    Loan.deleteMany({}),
    User.deleteMany({}),
  ]);

  user = await createUser(PHONE, 'ABCDE1234F');
  otherUser = await createUser(OTHER_PHONE, 'ABCDE1235F');
  token = signAccessToken(user._id);
  otherToken = signAccessToken(otherUser._id);
  applicationSequence = 0;
});

describe('repayment schedule', () => {
  it('creates one installment per month when the loan is disbursed', async () => {
    const loan = await createLoan(LOAN_STATUS.APPROVED);

    await disburse(loan);

    const installments = await Repayment.find({ loan: loan._id }).sort({
      installmentNumber: 1,
    });

    expect(installments).toHaveLength(12);
    expect(installments.map((item) => item.installmentNumber)).toEqual(
      Array.from({ length: 12 }, (_value, index) => index + 1)
    );
    expect(installments.every((item) => item.amount === 8884.88)).toBe(true);
    expect(
      installments.every((item) => item.status === REPAYMENT_STATUS.PENDING && item.paidAt === null)
    ).toBe(true);

    for (let index = 1; index < installments.length; index += 1) {
      expect(installments[index].dueDate.getTime()).toBeGreaterThan(
        installments[index - 1].dueDate.getTime()
      );
    }
  });

  it('is idempotent when called again', async () => {
    const loan = await disburse(await createLoan(LOAN_STATUS.APPROVED));

    await repaymentService.generateScheduleForLoan(loan);

    expect(await Repayment.countDocuments({ loan: loan._id })).toBe(12);
  });

  it('returns the schedule only to the owning user', async () => {
    const loan = await disburse(await createLoan(LOAN_STATUS.APPROVED));

    const ownerResponse = await getRepayments(loan._id);
    const otherResponse = await getRepayments(loan._id, otherToken);
    const anonymousResponse = await request(app).get(`/api/loans/${loan._id}/repayments`);

    expect(ownerResponse.status).toBe(200);
    expect(ownerResponse.body.data.repayments).toHaveLength(12);
    expect(ownerResponse.body.data.repayments[0].installmentNumber).toBe(1);
    expect(otherResponse.status).toBe(404);
    expect(anonymousResponse.status).toBe(401);
  });

  it('is unavailable before disbursement', async () => {
    const loan = await createLoan(LOAN_STATUS.APPROVED);

    const listResponse = await getRepayments(loan._id);
    const payResponse = await payInstallment(loan._id, 1);

    expect(listResponse.status).toBe(409);
    expect(payResponse.status).toBe(409);
    expect(listResponse.body.message).toContain('only after the loan is disbursed');
  });
});

describe('paying installments', () => {
  it('marks an on-time payment as paid and adds 10 points', async () => {
    const loan = await disburse(await createLoan(LOAN_STATUS.APPROVED));

    const res = await payInstallment(loan._id, 1);

    expect(res.status).toBe(200);
    expect(res.body.data.repayment.status).toBe(REPAYMENT_STATUS.PAID);
    expect(res.body.data.repayment.paidAt).toEqual(expect.any(String));
    expect(res.body.data.creditScore).toEqual({ score: 660, band: 'fair' });

    const storedUser = await User.findById(user._id);
    expect(storedUser.creditScore).toBe(660);

    const log = await CreditScoreLog.findOne({ loan: loan._id });
    expect(log).toEqual(
      expect.objectContaining({
        change: CREDIT_SCORE_CHANGES.ON_TIME_REPAYMENT,
        previousScore: 650,
        score: 660,
        repayment: expect.anything(),
      })
    );
    expect(log.reason).toContain('On-time repayment');

    const schedule = await getRepayments(loan._id);
    const first = schedule.body.data.repayments.find((item) => item.installmentNumber === 1);
    expect(first.status).toBe(REPAYMENT_STATUS.PAID);
  });

  it('marks a payment after the due date as late and subtracts 20 points', async () => {
    const loan = await disburse(await createLoan(LOAN_STATUS.APPROVED));

    await Repayment.updateOne(
      { loan: loan._id, installmentNumber: 1 },
      { $set: { dueDate: new Date(Date.now() - 60_000) } }
    );

    const res = await payInstallment(loan._id, 1);

    expect(res.status).toBe(200);
    expect(res.body.data.repayment.status).toBe(REPAYMENT_STATUS.LATE);
    expect(res.body.data.creditScore).toEqual({ score: 630, band: 'fair' });

    const log = await CreditScoreLog.findOne({ loan: loan._id });
    expect(log.change).toBe(CREDIT_SCORE_CHANGES.LATE_REPAYMENT);
    expect(log.reason).toContain('Late repayment');
  });

  it('rejects a second payment for the same installment', async () => {
    const loan = await disburse(await createLoan(LOAN_STATUS.APPROVED));

    expect((await payInstallment(loan._id, 1)).status).toBe(200);

    const res = await payInstallment(loan._id, 1);

    expect(res.status).toBe(409);
    expect(res.body.message).toContain('already been paid');
    expect(await CreditScoreLog.countDocuments({ loan: loan._id })).toBe(1);
    expect((await User.findById(user._id)).creditScore).toBe(660);
  });

  it('adds the 30 point bonus after the last installment, exactly once', async () => {
    const loan = await disburse(
      await createLoan(LOAN_STATUS.APPROVED, {
        amount: 30000,
        tenureMonths: 3,
        emi: 1000,
        totalPayable: 3000,
      })
    );

    const first = await payInstallment(loan._id, 1);
    const second = await payInstallment(loan._id, 2);
    const third = await payInstallment(loan._id, 3);

    expect(first.body.data.creditScore.score).toBe(660);
    expect(second.body.data.creditScore.score).toBe(670);
    expect(third.body.data.creditScore.score).toBe(710);
    expect(await Repayment.countDocuments({ loan: loan._id, paidAt: null })).toBe(0);

    const logs = await CreditScoreLog.find({ loan: loan._id }).sort({ _id: 1 });
    expect(logs).toHaveLength(4);
    expect(logs[3].change).toBe(CREDIT_SCORE_CHANGES.ALL_INSTALLMENTS_PAID_BONUS);
    expect(logs[3].reason).toContain('All installments paid bonus');

    const duplicate = await payInstallment(loan._id, 3);

    expect(duplicate.status).toBe(409);
    expect(await CreditScoreLog.countDocuments({ loan: loan._id })).toBe(4);
    expect((await User.findById(user._id)).creditScore).toBe(710);
  });

  it('requires the owner, a valid loan and a valid installment', async () => {
    const loan = await disburse(await createLoan(LOAN_STATUS.APPROVED));

    const otherResponse = await payInstallment(loan._id, 1, otherToken);
    const missingInstallment = await payInstallment(loan._id, 13);
    const invalidLoan = await payInstallment(new mongoose.Types.ObjectId(), 1);

    expect(otherResponse.status).toBe(404);
    expect(missingInstallment.status).toBe(404);
    expect(invalidLoan.status).toBe(404);
  });
});

describe('GET /api/users/me/credit-score', () => {
  it('returns the current score, band and recent changes', async () => {
    const before = await asUser(request(app).get('/api/users/me/credit-score'));

    expect(before.status).toBe(200);
    expect(before.body.data).toEqual({
      score: 650,
      band: 'fair',
      recentChanges: [],
    });

    const loan = await disburse(await createLoan(LOAN_STATUS.APPROVED));
    await payInstallment(loan._id, 1);

    const after = await asUser(request(app).get('/api/users/me/credit-score'));

    expect(after.status).toBe(200);
    expect(after.body.data.score).toBe(660);
    expect(after.body.data.band).toBe('fair');
    expect(after.body.data.recentChanges).toHaveLength(1);
    expect(after.body.data.recentChanges[0]).toEqual(
      expect.objectContaining({
        change: 10,
        previousScore: 650,
        score: 660,
        reason: expect.stringContaining('On-time repayment'),
        createdAt: expect.any(String),
      })
    );
  });

  it('requires authentication', async () => {
    const res = await request(app).get('/api/users/me/credit-score');

    expect(res.status).toBe(401);
  });
});
