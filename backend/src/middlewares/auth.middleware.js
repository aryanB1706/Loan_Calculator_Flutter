const AppError = require('../utils/AppError');
const asyncHandler = require('../utils/asyncHandler');
const { HTTP_STATUS } = require('../constants');
const User = require('../models/User');
const { verifyAccessToken } = require('../utils/token');

/** Verifies the Bearer access token and attaches the user to req.user. */
const authenticate = asyncHandler(async (req, _res, next) => {
  const [scheme, token] = (req.headers.authorization || '').split(' ');

  if (scheme !== 'Bearer' || !token) {
    throw new AppError('Authentication required', HTTP_STATUS.UNAUTHORIZED);
  }

  const payload = verifyAccessToken(token);

  if (payload.type !== 'access') {
    throw new AppError('Invalid authentication token', HTTP_STATUS.UNAUTHORIZED);
  }

  const user = await User.findById(payload.sub);

  if (!user) {
    throw new AppError('User no longer exists', HTTP_STATUS.UNAUTHORIZED);
  }

  req.user = user;
  next();
});

module.exports = authenticate;
