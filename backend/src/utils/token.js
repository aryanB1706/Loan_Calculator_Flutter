const crypto = require('crypto');
const jwt = require('jsonwebtoken');

const config = require('../config');

function signAccessToken(userId) {
  return jwt.sign({ sub: userId.toString(), type: 'access' }, config.jwt.accessSecret, {
    expiresIn: config.jwt.accessExpiresIn,
  });
}

function signRefreshToken(userId) {
  // jti keeps every refresh token unique even when two are issued in the same second.
  return jwt.sign(
    { sub: userId.toString(), type: 'refresh', jti: crypto.randomUUID() },
    config.jwt.refreshSecret,
    { expiresIn: config.jwt.refreshExpiresIn }
  );
}

function verifyAccessToken(token) {
  return jwt.verify(token, config.jwt.accessSecret);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, config.jwt.refreshSecret);
}

/**
 * Refresh tokens are stored as SHA-256 hashes. Unlike passwords, they are
 * high-entropy random values, so a fast hash is safe and keeps refresh cheap.
 */
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

module.exports = {
  signAccessToken,
  signRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  hashToken,
};
