const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/apiResponse');
const { LOAN_MESSAGES } = require('../constants/loanRules');
const adminLoanService = require('../services/adminLoan.service');

const updateLoanStatus = asyncHandler(async (req, res) => {
  const loan = await adminLoanService.updateLoanStatus(req.params.id, req.body);

  return sendSuccess(res, {
    message: LOAN_MESSAGES.STATUS_UPDATED,
    data: { loan: loan.toJSON() },
  });
});

const autoDecideLoan = asyncHandler(async (req, res) => {
  const loan = await adminLoanService.autoDecideLoan(req.params.id);

  return sendSuccess(res, {
    message: LOAN_MESSAGES.AUTO_DECISION_COMPLETED,
    data: { loan: loan.toJSON() },
  });
});

module.exports = { updateLoanStatus, autoDecideLoan };
