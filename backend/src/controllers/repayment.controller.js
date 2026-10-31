const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/apiResponse');
const { MESSAGES } = require('../constants');
const repaymentService = require('../services/repayment.service');

const listRepayments = asyncHandler(async (req, res) => {
  const repayments = await repaymentService.listRepayments(req.user, req.params.id);

  return sendSuccess(res, {
    message: MESSAGES.REPAYMENTS_FETCHED,
    data: {
      repayments: repayments.map((repayment) => repayment.toJSON()),
    },
  });
});

const payInstallment = asyncHandler(async (req, res) => {
  const result = await repaymentService.payInstallment(
    req.user,
    req.params.id,
    req.params.installmentNumber
  );

  return sendSuccess(res, {
    message: MESSAGES.REPAYMENT_PAID,
    data: {
      repayment: result.repayment.toJSON(),
      creditScore: result.creditScore,
    },
  });
});

module.exports = { listRepayments, payInstallment };
