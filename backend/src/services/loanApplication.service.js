const mongoose = require('mongoose');

const Loan = require('../models/Loan');
const Counter = require('../models/Counter');
const AppError = require('../utils/AppError');
const { HTTP_STATUS } = require('../constants');
const { LOAN_STATUS, ACTIVE_LOAN_STATUSES } = require('../constants/loanRules');
const loanCalculatorService = require('./loanCalculator.service');
const eligibilityService = require('./eligibility.service');

const APPLICATION_NUMBER_PREFIX = 'LN';

async function generateApplicationNumber() {
  const year = new Date().getUTCFullYear();
  const counter = await Counter.findByIdAndUpdate(
    `loan-${year}`,
    { $inc: { seq: 1 } },
    { new: true, upsert: true, setDefaultsOnInsert: false }
  );

  return `${APPLICATION_NUMBER_PREFIX}-${year}-${String(counter.seq).padStart(6, '0')}`;
}

function assertProfileCompleted(user) {
  if (user.profileCompleted !== true) {
    throw new AppError(
      'Complete your profile before applying for a loan',
      HTTP_STATUS.UNPROCESSABLE_ENTITY,
      [{ field: 'profile', message: 'Your profile is incomplete.' }]
    );
  }
}

async function findActiveApplication(userId) {
  return Loan.findOne({
    user: userId,
    status: { $in: [...ACTIVE_LOAN_STATUSES] },
  }).select('applicationNumber status');
}

/**
 * Applies the duplicate rule: one user may have only one application that is
 * still being processed (submitted or under_review). This prevents accidental
 * double applications and duplicate credit checks. Rejected and disbursed
 * applications are terminal for this rule, so the user can apply again.
 */
async function assertNoActiveApplication(userId) {
  const activeApplication = await findActiveApplication(userId);

  if (activeApplication) {
    throw new AppError(
      `You already have an active loan application (${activeApplication.applicationNumber}). Wait for it to be approved, rejected, or disbursed before applying again.`,
      HTTP_STATUS.CONFLICT
    );
  }
}

async function applyForLoan(user, { amount, tenureMonths, purpose }) {
  assertProfileCompleted(user);
  await assertNoActiveApplication(user._id);

  // Eligibility is always recalculated on the server from the stored profile;
  // the client only supplies the requested amount and tenure.
  const eligibility = eligibilityService.checkEligibility(user, { amount, tenureMonths });

  if (!eligibility.eligible) {
    throw new AppError(
      'You are not eligible for this loan',
      HTTP_STATUS.UNPROCESSABLE_ENTITY,
      eligibility.reasons.map((message) => ({ field: 'eligibility', message }))
    );
  }

  const quote = loanCalculatorService.calculateLoan({ amount, tenureMonths });
  const applicationNumber = await generateApplicationNumber();
  const submittedAt = new Date();

  try {
    return await Loan.create({
      user: user._id,
      applicationNumber,
      amount,
      tenureMonths,
      interestRate: quote.interestRate,
      emi: quote.emi,
      totalPayable: quote.totalPayable,
      purpose,
      status: LOAN_STATUS.SUBMITTED,
      statusHistory: [
        {
          status: LOAN_STATUS.SUBMITTED,
          note: 'Application submitted',
          changedAt: submittedAt,
        },
      ],
    });
  } catch (error) {
    // Covers the race where two requests pass the service check together.
    if (error.code === 11000 && error.keyPattern && error.keyPattern.user) {
      throw new AppError(
        'You already have an active loan application. Wait for it to be processed before applying again.',
        HTTP_STATUS.CONFLICT
      );
    }

    throw error;
  }
}

async function listApplications(user, { page, limit }) {
  const filter = { user: user._id };
  const skip = (page - 1) * limit;

  const [applications, total] = await Promise.all([
    Loan.find(filter).sort({ createdAt: -1, _id: -1 }).skip(skip).limit(limit),
    Loan.countDocuments(filter),
  ]);

  return {
    applications,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

async function getApplicationById(user, applicationId) {
  if (!mongoose.Types.ObjectId.isValid(applicationId)) {
    throw new AppError('Loan application not found', HTTP_STATUS.NOT_FOUND);
  }

  // Scoping by user means another user's application is indistinguishable from
  // a missing one.
  const application = await Loan.findOne({
    _id: applicationId,
    user: user._id,
  });

  if (!application) {
    throw new AppError('Loan application not found', HTTP_STATUS.NOT_FOUND);
  }

  return application;
}

module.exports = {
  applyForLoan,
  listApplications,
  getApplicationById,
};
