const mongoose = require('mongoose');

const Loan = require('../models/Loan');
const User = require('../models/User');
const AppError = require('../utils/AppError');
const { HTTP_STATUS } = require('../constants');
const { LOAN_STATUS } = require('../constants/loanRules');
const loanWorkflowService = require('./loanWorkflow.service');
const eligibilityService = require('./eligibility.service');

async function findLoanOrThrow(loanId) {
  if (!mongoose.Types.ObjectId.isValid(loanId)) {
    throw new AppError('Loan application not found', HTTP_STATUS.NOT_FOUND);
  }

  const loan = await Loan.findById(loanId);

  if (!loan) {
    throw new AppError('Loan application not found', HTTP_STATUS.NOT_FOUND);
  }

  return loan;
}

async function updateLoanStatus(loanId, { status, note }) {
  const loan = await findLoanOrThrow(loanId);

  return loanWorkflowService.transitionLoan(loan, status, note);
}

/**
 * Basic approval decision: reload the applicant and run the same eligibility
 * rules again. Eligibility also includes the credit-score rule, so a score that
 * changed after submission is reflected here.
 */
async function autoDecideLoan(loanId) {
  const loan = await findLoanOrThrow(loanId);

  if (loan.status !== LOAN_STATUS.UNDER_REVIEW) {
    throw new AppError(
      `Auto decision requires an application under review (current status: ${loan.status})`,
      HTTP_STATUS.CONFLICT
    );
  }

  const user = await User.findById(loan.user);

  if (!user) {
    return loanWorkflowService.transitionLoan(
      loan,
      LOAN_STATUS.REJECTED,
      'Auto-rejected: applicant profile not found.'
    );
  }

  const decision = eligibilityService.checkEligibility(user, {
    amount: loan.amount,
    tenureMonths: loan.tenureMonths,
  });

  if (decision.eligible) {
    return loanWorkflowService.transitionLoan(
      loan,
      LOAN_STATUS.APPROVED,
      'Auto-approved: eligibility and credit score checks passed.'
    );
  }

  return loanWorkflowService.transitionLoan(
    loan,
    LOAN_STATUS.REJECTED,
    `Auto-rejected: ${decision.reasons.join(' ')}`
  );
}

module.exports = { updateLoanStatus, autoDecideLoan };
