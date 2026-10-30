const config = require('../../config');
const OtpSender = require('./otpSender');

/** Console sender: prints the OTP in server logs only. */
class ConsoleOtpSender extends OtpSender {
  async send(phone, otp) {
    console.log(`[otp] ${phone} -> ${otp} (valid for ${config.otp.expiresInMinutes} minutes)`);
    return { provider: 'console' };
  }
}

module.exports = ConsoleOtpSender;
