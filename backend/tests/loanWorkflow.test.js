const request = require('supertest');
const mongoose = require('mongoose');

const app = require('../src/app');
const config = require('../src/config');
const User = require('../src/models/User');
const Loan = require('../src/models/Loan');
const loanWorkflowService = require('../src/services/loanWorkflow.service');
const { loanEvents, LOAN_EVENTS } = require('../src/events/loanEvents');
const { LOAN_STATUS } = require('../src/constants/loanRules');
const AppError = require('../src/utils/AppError');

const PHONE = '9876500006';
const YEAR = new Date().getUTCFullYear();
const ADMIN_KEY = config.adminApiKey;

const ALL_STATUSES = Object.values(LOAN_STATUS);
const VALID_TRANSITIONS = [
  [LOAN_STATUS.SUBMITTED, LOAN_STATUS.UNDER_REVIEW],
  [LOAN_STATUS.UNDER_REVIEW, LOAN_STATUS.APPROVED],
  [LOAN_STATUS.UNDER_REVIEW, LOAN_STATUS.REJECTED],
  [LOAN_STATUS.APPROVED, LOAN_STATUS.DISBURSED],
];

let user;
let applicationSequence;

function yearsAgo(years) {
  const date = new Date();
  date.setUTCFullYear(date.getUTCFullYear() - years);
  return date;
}

function captureError(fn) {
  try {
    fn();
  } catch (error) {
    return error;
  }
  throw new Error('Expected the call to throw');
}

async function createUser(overrides = {}) {
  return User.create({
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
    ...overrides,
  });
}

async function createLoan(status = LOAN_STATUS.SUBMITTED, overrides = {}) {
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

function adminRequest(method, path, key = ADMIN_KEY) {
  return request(app)[method](path).set('x-admin-api-key', key);
}

function patchStatus(loanId, status, note) {
  return adminRequest('patch', `/api/admin/loans/${loanId}/status`).send({
    status,
    ...(note === undefined ? {} : { note }),
  });
}

function autoDecide(loanId) {
  return adminRequest('post', `/api/admin/loans/${loanId}/auto-decision`);
}

beforeAll(async () => {
  await mongoose.connect(config.mongoUri);
  await Promise.all([User.init(), Loan.init()]);
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

beforeEach(async () => {
  await Promise.all([Loan.deleteMany({}), User.deleteMany({})]);
  user = await createUser();
  applicationSequence = 0;
});

describe('loanWorkflowService state machine', () => {
  it.each(VALID_TRANSITIONS)('allows %s -> %s', (from, to) => {
    expect(loanWorkflowService.canTransition(from, to)).toBe(true);
    expect(() => loanWorkflowService.assertTransitionAllowed(from, to)).not.toThrow();
  });

  const invalidTransitions = ALL_STATUSES.flatMap((from) =>
    ALL_STATUSES.filter(
      (to) =>
        !VALID_TRANSITIONS.some(
          ([allowedFrom, allowedTo]) => allowedFrom === from && allowedTo === to
        )
    ).map((to) => [from, to])
  );

  it.each(invalidTransitions)('rejects %s -> %s', (from, to) => {
    expect(loanWorkflowService.canTransition(from, to)).toBe(false);

    const error = captureError(() => loanWorkflowService.assertTransitionAllowed(from, to));

    expect(error).toBeInstanceOf(AppError);
    expect(error.statusCode).toBe(409);
    expect(error.message).toContain(`Invalid loan status transition: ${from} -> ${to}`);
  });

  it('rejects an unknown target status', () => {
    const error = captureError(() =>
      loanWorkflowService.assertTransitionAllowed(LOAN_STATUS.SUBMITTED, 'unknown')
    );

    expect(error.statusCode).toBe(422);
    expect(error.message).toContain('Unknown loan status');
  });

  it('appends history, persists the change and emits an event', async () => {
    const loan = await createLoan(LOAN_STATUS.SUBMITTED);
    const listener = jest.fn();
    loanEvents.on(LOAN_EVENTS.STATUS_CHANGED, listener);

    try {
      const updated = await loanWorkflowService.transitionLoan(
        loan,
        LOAN_STATUS.UNDER_REVIEW,
        'Moved by admin'
      );

      expect(updated.status).toBe(LOAN_STATUS.UNDER_REVIEW);
      expect(updated.statusHistory).toHaveLength(2);
      expect(updated.statusHistory[1]).toEqual(
        expect.objectContaining({
          status: LOAN_STATUS.UNDER_REVIEW,
          note: 'Moved by admin',
          changedAt: expect.any(Date),
        })
      );

      const stored = await Loan.findById(loan._id);
      expect(stored.status).toBe(LOAN_STATUS.UNDER_REVIEW);

      expect(listener).toHaveBeenCalledTimes(1);
      expect(listener.mock.calls[0][0]).toEqual(
        expect.objectContaining({
          previousStatus: LOAN_STATUS.SUBMITTED,
          newStatus: LOAN_STATUS.UNDER_REVIEW,
          note: 'Moved by admin',
          loan: expect.objectContaining({
            _id: expect.anything(),
          }),
        })
      );
    } finally {
      loanEvents.off(LOAN_EVENTS.STATUS_CHANGED, listener);
    }
  });

  it('does not change or announce an invalid transition', async () => {
    const loan = await createLoan(LOAN_STATUS.SUBMITTED);
    const listener = jest.fn();
    loanEvents.on(LOAN_EVENTS.STATUS_CHANGED, listener);

    try {
      await expect(
        loanWorkflowService.transitionLoan(loan, LOAN_STATUS.APPROVED)
      ).rejects.toMatchObject({ statusCode: 409 });

      expect(loan.status).toBe(LOAN_STATUS.SUBMITTED);
      expect(loan.statusHistory).toHaveLength(1);
      expect(listener).not.toHaveBeenCalled();
    } finally {
      loanEvents.off(LOAN_EVENTS.STATUS_CHANGED, listener);
    }
  });

  it('stores the rejection reason when rejecting', async () => {
    const loan = await createLoan(LOAN_STATUS.UNDER_REVIEW);

    const updated = await loanWorkflowService.transitionLoan(
      loan,
      LOAN_STATUS.REJECTED,
      'Income is too low'
    );

    expect(updated.status).toBe(LOAN_STATUS.REJECTED);
    expect(updated.rejectionReason).toBe('Income is too low');
  });
});

describe('admin loan endpoints', () => {
  describe('authentication', () => {
    it('rejects a request without the admin key', async () => {
      const loan = await createLoan();

      const res = await request(app)
        .patch(`/api/admin/loans/${loan._id}/status`)
        .send({ status: LOAN_STATUS.UNDER_REVIEW });

      expect(res.status).toBe(401);
      expect(res.body.message).toBe('Invalid admin API key');
    });

    it('rejects a request with the wrong admin key', async () => {
      const loan = await createLoan();

      const res = await adminRequest(
        'patch',
        `/api/admin/loans/${loan._id}/status`,
        'wrong-key'
      ).send({ status: LOAN_STATUS.UNDER_REVIEW });

      expect(res.status).toBe(401);
    });
  });

  describe('PATCH /api/admin/loans/:id/status', () => {
    it('walks a loan through the valid states', async () => {
      const loan = await createLoan(LOAN_STATUS.SUBMITTED);

      const review = await patchStatus(loan._id, LOAN_STATUS.UNDER_REVIEW, 'Picked up by admin');
      const approve = await patchStatus(loan._id, LOAN_STATUS.APPROVED, 'Documents verified');
      const disburse = await patchStatus(loan._id, LOAN_STATUS.DISBURSED);

      expect(review.status).toBe(200);
      expect(review.body.data.loan.status).toBe(LOAN_STATUS.UNDER_REVIEW);
      expect(approve.body.data.loan.status).toBe(LOAN_STATUS.APPROVED);
      expect(disburse.body.data.loan.status).toBe(LOAN_STATUS.DISBURSED);
      expect(disburse.body.data.loan.statusHistory).toHaveLength(4);
      expect(disburse.body.data.loan.statusHistory[3].note).toBe('Loan disbursed');
    });

    it('rejects an invalid transition with a clear error', async () => {
      const loan = await createLoan(LOAN_STATUS.SUBMITTED);

      const res = await patchStatus(loan._id, LOAN_STATUS.APPROVED, 'Skip review');

      expect(res.status).toBe(409);
      expect(res.body.message).toBe(
        `Invalid loan status transition: ${LOAN_STATUS.SUBMITTED} -> ${LOAN_STATUS.APPROVED}`
      );

      const stored = await Loan.findById(loan._id);
      expect(stored.status).toBe(LOAN_STATUS.SUBMITTED);
      expect(stored.statusHistory).toHaveLength(1);
    });

    it('rejects an unknown status at validation time', async () => {
      const loan = await createLoan();

      const res = await patchStatus(loan._id, 'unknown');

      expect(res.status).toBe(422);
      expect(res.body.errors[0].field).toBe('status');
    });

    it('returns 404 for an unknown loan', async () => {
      const res = await patchStatus(new mongoose.Types.ObjectId(), LOAN_STATUS.UNDER_REVIEW);

      expect(res.status).toBe(404);
    });
  });

  describe('POST /api/admin/loans/:id/auto-decision', () => {
    it('approves an eligible application that is under review', async () => {
      const loan = await createLoan(LOAN_STATUS.UNDER_REVIEW);

      const res = await autoDecide(loan._id);

      expect(res.status).toBe(200);
      expect(res.body.data.loan.status).toBe(LOAN_STATUS.APPROVED);
      expect(res.body.data.loan.rejectionReason).toBeNull();
      expect(res.body.data.loan.statusHistory[1].note).toContain('Auto-approved');
    });

    it('rejects when the current credit score is below the minimum', async () => {
      const loan = await createLoan(LOAN_STATUS.UNDER_REVIEW);

      user.creditScore = 550;
      await user.save();

      const res = await autoDecide(loan._id);

      expect(res.status).toBe(200);
      expect(res.body.data.loan.status).toBe(LOAN_STATUS.REJECTED);
      expect(res.body.data.loan.rejectionReason).toContain('credit score');
      expect(res.body.data.loan.statusHistory[1].note).toContain('Auto-rejected');
    });

    it('only runs on applications under review', async () => {
      const loan = await createLoan(LOAN_STATUS.SUBMITTED);

      const res = await autoDecide(loan._id);

      expect(res.status).toBe(409);
      expect(res.body.message).toContain('requires an application under review');
    });
  });
});
