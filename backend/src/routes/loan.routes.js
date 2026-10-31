const express = require('express');

const {
  calculateLoan,
  checkEligibility,
  applyForLoan,
  listApplications,
  getApplication,
} = require('../controllers/loan.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate');
const {
  calculateLoanSchema,
  eligibilitySchema,
  applyLoanSchema,
  listApplicationsQuerySchema,
} = require('../validators/loan.validator');

const router = express.Router();

// Public: the calculator only needs the requested amount and tenure and returns
// no personal data, so users can explore EMIs before signing in.
router.post('/calculate', validate(calculateLoanSchema), calculateLoan);

// Authenticated: eligibility and applications use the signed-in user's profile.
router.post('/eligibility', authenticate, validate(eligibilitySchema), checkEligibility);
router.post('/apply', authenticate, validate(applyLoanSchema), applyForLoan);
router.get('/', authenticate, validate(listApplicationsQuerySchema, 'query'), listApplications);
router.get('/:id', authenticate, getApplication);

module.exports = router;
