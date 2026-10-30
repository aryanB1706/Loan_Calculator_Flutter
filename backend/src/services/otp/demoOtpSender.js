const OtpSender = require('./otpSender');

/**
 * Demo sender: no SMS is sent. The auth service generates the fixed demo OTP,
 * and this sender only records that demo delivery happened.
 */
class DemoOtpSender extends OtpSender {
  async send(phone, otp) {
    console.log(`[otp] demo mode: ${phone} -> ${otp} (no SMS sent)`);
    return { provider: 'demo' };
  }
}

module.exports = DemoOtpSender;
