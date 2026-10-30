const AppError = require('../utils/AppError');
const { HTTP_STATUS, MESSAGES } = require('../constants');
const {
  LOAN_AMOUNT,
  LOAN_TENURE_MONTHS,
  ANNUAL_INTEREST_RATE_PERCENT,
} = require('../constants/loanRules');

function roundMoney(value) {
  return Math.round(value * 100) / 100;
}

/**
 * Validates the business limits. The HTTP validator rejects the same values,
 * but keeping the guard here protects every direct caller of the service.
 */
function assertLoanTerms({ amount, tenureMonths }) {
  const errors = [];

  if (!Number.isInteger(amount) || amount < LOAN_AMOUNT.MIN || amount > LOAN_AMOUNT.MAX) {
    errors.push({
      field: 'amount',
      message: `amount must be a whole number between ${LOAN_AMOUNT.MIN} and ${LOAN_AMOUNT.MAX}`,
    });
  }

  if (
    !Number.isInteger(tenureMonths) ||
    tenureMonths < LOAN_TENURE_MONTHS.MIN ||
    tenureMonths > LOAN_TENURE_MONTHS.MAX
  ) {
    errors.push({
      field: 'tenureMonths',
      message: `tenureMonths must be a whole number between ${LOAN_TENURE_MONTHS.MIN} and ${LOAN_TENURE_MONTHS.MAX}`,
    });
  }

  if (errors.length > 0) {
    throw new AppError(MESSAGES.VALIDATION_FAILED, HTTP_STATUS.UNPROCESSABLE_ENTITY, errors);
  }
}

/**
 * Standard reducing-balance EMI:
 *   EMI = P * r * (1 + r)^n / ((1 + r)^n - 1)
 * where r is the monthly rate (annual / 12 / 100) and n is the tenure in months.
 */
function calculateEmi(amount, tenureMonths, annualRatePercent = ANNUAL_INTEREST_RATE_PERCENT) {
  const monthlyRate = annualRatePercent / 12 / 100;
  const growth = Math.pow(1 + monthlyRate, tenureMonths);

  return (amount * monthlyRate * growth) / (growth - 1);
}

function calculateLoan({ amount, tenureMonths }) {
  assertLoanTerms({ amount, tenureMonths });

  const emi = roundMoney(calculateEmi(amount, tenureMonths));
  const totalPayable = roundMoney(emi * tenureMonths);
  const totalInterest = roundMoney(totalPayable - amount);

  return {
    emi,
    totalPayable,
    totalInterest,
    interestRate: ANNUAL_INTEREST_RATE_PERCENT,
  };
}

module.exports = { calculateLoan, calculateEmi };
