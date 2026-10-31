const express = require('express');

const { getMe, updateMe, getMyCreditScore } = require('../controllers/user.controller');
const authenticate = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate');
const { profileUpdateSchema } = require('../validators/user.validator');

const router = express.Router();

router.get('/me', authenticate, getMe);
router.get('/me/credit-score', authenticate, getMyCreditScore);
router.put('/me', authenticate, validate(profileUpdateSchema), updateMe);

module.exports = router;
