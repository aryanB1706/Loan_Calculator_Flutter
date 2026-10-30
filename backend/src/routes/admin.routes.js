const express = require('express');

const { updateLoanStatus, autoDecideLoan } = require('../controllers/adminLoan.controller');
const authenticateAdmin = require('../middlewares/admin.middleware');
const validate = require('../middlewares/validate');
const { adminStatusUpdateSchema } = require('../validators/adminLoan.validator');

const router = express.Router();

router.use(authenticateAdmin);

router.patch('/loans/:id/status', validate(adminStatusUpdateSchema), updateLoanStatus);
router.post('/loans/:id/auto-decision', autoDecideLoan);

module.exports = router;
