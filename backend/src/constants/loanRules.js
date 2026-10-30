// Every loan rule lives here so the calculator, eligibility check and request
// validation always use the same numbers.

const LOAN_AMOUNT = Object.freeze({
  MIN: 10000,
  MAX: 500000,
});

const LOAN_TENURE_MONTHS = Object.freeze({
  MIN: 3,
  MAX: 60,
});

// The calculator endpoint is public and has no credit profile to personalise
// against, so one flat rate keeps the quote deterministic and explainable.
// Eligibility uses the same rate so the quote and the decision never disagree.
const ANNUAL_INTEREST_RATE_PERCENT = 12;

const ELIGIBILITY_RULES = Object.freeze({
  MIN_AGE: 21,
  MAX_AGE: 60,
  MIN_MONTHLY_INCOME: 15000,
  MIN_CREDIT_SCORE: 600,
  // FOIR = Fixed Obligation to Income Ratio. An EMI above half the income is
  // treated as unaffordable.
  MAX_FOIR_PERCENT: 50,
  // A borrower may request up to 10x their monthly income, subject to the
  // global amount cap.
  MAX_AMOUNT_MULTIPLIER: 10,
});

const LOAN_STATUS = Object.freeze({
  SUBMITTED: 'submitted',
  UNDER_REVIEW: 'under_review',
  APPROVED: 'approved',
  REJECTED: 'rejected',
  DISBURSED: 'disbursed',
});

const LOAN_STATUS_VALUES = Object.freeze(Object.values(LOAN_STATUS));

// Only these statuses mean "still being processed". Terminal applications do not
// stop the user from applying again.
const ACTIVE_LOAN_STATUSES = Object.freeze([LOAN_STATUS.SUBMITTED, LOAN_STATUS.UNDER_REVIEW]);

const LOAN_PURPOSE = Object.freeze({
  MIN_LENGTH: 3,
  MAX_LENGTH: 200,
});

const LOAN_PAGINATION = Object.freeze({
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 10,
  MAX_LIMIT: 50,
});

const LOAN_MESSAGES = Object.freeze({
  CALCULATED: 'Loan EMI calculated successfully',
  ELIGIBILITY_CHECKED: 'Loan eligibility checked successfully',
  APPLICATION_SUBMITTED: 'Loan application submitted successfully',
  APPLICATIONS_FETCHED: 'Loan applications fetched successfully',
  APPLICATION_FETCHED: 'Loan application fetched successfully',
  STATUS_UPDATED: 'Loan status updated successfully',
  AUTO_DECISION_COMPLETED: 'Loan auto-decision completed successfully',
});

module.exports = {
  LOAN_AMOUNT,
  LOAN_TENURE_MONTHS,
  ANNUAL_INTEREST_RATE_PERCENT,
  ELIGIBILITY_RULES,
  LOAN_STATUS,
  LOAN_STATUS_VALUES,
  ACTIVE_LOAN_STATUSES,
  LOAN_PURPOSE,
  LOAN_PAGINATION,
  LOAN_MESSAGES,
};
