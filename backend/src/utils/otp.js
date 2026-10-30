const crypto = require('crypto');
const bcrypt = require('bcryptjs');

const BCRYPT_ROUNDS = 10;

/** Generates a 6 digit numeric OTP (leading zeros preserved). */
function generateOtp() {
  return crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
}

/** OTPs are stored hashed so a database leak does not expose valid codes. */
function hashOtp(otp) {
  return bcrypt.hash(otp, BCRYPT_ROUNDS);
}

function compareOtp(otp, hash) {
  return bcrypt.compare(otp, hash);
}

module.exports = { generateOtp, hashOtp, compareOtp };
