const mongoose = require('mongoose');

const Loan = require('../models/Loan');
const Repayment = require('../models/Repayment');
const AppError = require('../utils/AppError');
const { HTTP_STATUS } = require('../constants');
const { LOAN_STATUS } = require('../constants/loanRules');
const { REPAYMENT_STATUS } = require('../constants/repaymentRules');
const { CREDIT_SCORE_CHANGES } = require('../constants/creditScoreRules');
const { addMonths } = require('../utils/date');
const creditScoreService = require('./creditScore.service');

/**
 * Creates one pending row per EMI, due monthly starting one month after
 * disbursement. The unique (loan, installmentNumber) index makes this safe to
 * call more than once.
 */
async function generateScheduleForLoan(loan) {
  const existing = await Repayment.exists({ loan: loan._id });
  if (existing) return [];

  const disbursedAt = loan.updatedAt || new Date();
  const installments = Array.from({ length: loan.tenureMonths }, (_value, index) => {
    const installmentNumber = index + 1;

    return {
      loan: loan._id,
      user: loan.user,
      installmentNumber,
      dueDate: addMonths(disbursedAt, installmentNumber),
      amount: loan.emi,
      status: REPAYMENT_STATUS.PENDING,
      paidAt: null,
    };
  });

  try {
    return await Repayment.insertMany(installments);
  } catch (error) {
    // A second caller may have created the schedule first.
    if (error.code === 11000) return [];
    throw error;
  }
}

async function findOwnedDisbursedLoan(user, loanId) {
  if (!mongoose.Types.ObjectId.isValid(loanId)) {
    throw new AppError('Loan application not found', HTTP_STATUS.NOT_FOUND);
  }

  const loan = await Loan.findOne({ _id: loanId, user: user._id });

  if (!loan) {
    throw new AppError('Loan application not found', HTTP_STATUS.NOT_FOUND);
  }

  if (loan.status !== LOAN_STATUS.DISBURSED) {
    throw new AppError(
      'Repayments are available only after the loan is disbursed',
      HTTP_STATUS.CONFLICT
    );
  }

  return loan;
}

async function listRepayments(user, loanId) {
  const loan = await findOwnedDisbursedLoan(user, loanId);

  return Repayment.find({ loan: loan._id }).sort({ installmentNumber: 1 });
}

async function payInstallment(user, loanId, installmentNumber) {
  const loan = await findOwnedDisbursedLoan(user, loanId);
  const installment = Number(installmentNumber);

  if (!Number.isInteger(installment) || installment < 1) {
    throw new AppError('Installment not found', HTTP_STATUS.NOT_FOUND);
  }

  const repayment = await Repayment.findOne({
    loan: loan._id,
    installmentNumber: installment,
  });

  if (!repayment) {
    throw new AppError('Installment not found', HTTP_STATUS.NOT_FOUND);
  }

  const paidAt = new Date();
  const status = paidAt > repayment.dueDate ? REPAYMENT_STATUS.LATE : REPAYMENT_STATUS.PAID;

  // The filter makes a simultaneous second payment lose cleanly.
  const updated = await Repayment.findOneAndUpdate(
    { _id: repayment._id, status: REPAYMENT_STATUS.PENDING, paidAt: null },
    { $set: { status, paidAt } },
    { new: true }
  );

  if (!updated) {
    throw new AppError('Installment has already been paid', HTTP_STATUS.CONFLICT);
  }

  const isLate = status === REPAYMENT_STATUS.LATE;

  await creditScoreService.applyScoreChange(user, {
    change: isLate ? CREDIT_SCORE_CHANGES.LATE_REPAYMENT : CREDIT_SCORE_CHANGES.ON_TIME_REPAYMENT,
    reason: `${isLate ? 'Late' : 'On-time'} repayment for ${loan.applicationNumber} installment ${installment}`,
    loanId: loan._id,
    repaymentId: updated._id,
  });

  const unpaidInstallments = await Repayment.countDocuments({
    loan: loan._id,
    paidAt: null,
  });

  if (unpaidInstallments === 0) {
    await creditScoreService.applyScoreChange(user, {
      change: CREDIT_SCORE_CHANGES.ALL_INSTALLMENTS_PAID_BONUS,
      reason: `All installments paid bonus for ${loan.applicationNumber}`,
      loanId: loan._id,
    });
  }

  return {
    repayment: updated,
    creditScore: {
      score: user.creditScore,
      band: creditScoreService.getBand(user.creditScore),
    },
  };
}

module.exports = { generateScheduleForLoan, listRepayments, payInstallment };
