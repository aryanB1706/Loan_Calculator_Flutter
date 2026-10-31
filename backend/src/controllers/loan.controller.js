const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../constants');
const { LOAN_MESSAGES } = require('../constants/loanRules');
const loanCalculatorService = require('../services/loanCalculator.service');
const eligibilityService = require('../services/eligibility.service');
const loanApplicationService = require('../services/loanApplication.service');

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

const applyForLoan = asyncHandler(async (req, res) => {
  const application = await loanApplicationService.applyForLoan(req.user, req.body);

  return sendSuccess(res, {
    statusCode: HTTP_STATUS.CREATED,
    message: LOAN_MESSAGES.APPLICATION_SUBMITTED,
    data: { application: application.toJSON() },
  });
});

const listApplications = asyncHandler(async (req, res) => {
  const { applications, pagination } = await loanApplicationService.listApplications(
    req.user,
    req.query
  );

  return sendSuccess(res, {
    message: LOAN_MESSAGES.APPLICATIONS_FETCHED,
    data: {
      applications: applications.map((application) => application.toJSON()),
      pagination,
    },
  });
});

const getApplication = asyncHandler(async (req, res) => {
  const application = await loanApplicationService.getApplicationById(req.user, req.params.id);

  return sendSuccess(res, {
    message: LOAN_MESSAGES.APPLICATION_FETCHED,
    data: { application: application.toJSON() },
  });
});

module.exports = {
  calculateLoan,
  checkEligibility,
  applyForLoan,
  listApplications,
  getApplication,
};
