const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/apiResponse');
const { LOAN_MESSAGES } = require('../constants/loanRules');
const loanCalculatorService = require('../services/loanCalculator.service');
const eligibilityService = require('../services/eligibility.service');

const calculateLoan = asyncHandler(async (req, res) => {
  const quote = loanCalculatorService.calculateLoan(req.body);

  return sendSuccess(res, {
    message: LOAN_MESSAGES.CALCULATED,
    data: quote,
  });
});

const checkEligibility = asyncHandler(async (req, res) => {
  const result = eligibilityService.checkEligibility(req.user, req.body);

  return sendSuccess(res, {
    message: LOAN_MESSAGES.ELIGIBILITY_CHECKED,
    data: result,
  });
});

module.exports = { calculateLoan, checkEligibility };
