const OtpSender = require('./otpSender');

/**
 * Placeholder for a real SMS provider (Fast2SMS / MSG91).
 *
 * To enable it:
 *   1. Add provider credentials to .env.
 *   2. Implement send() below with the provider SDK or HTTP API.
 *   3. Set OTP_MODE=sms and OTP_SMS_PROVIDER=fast2sms (or msg91).
 *
 * Keep the return shape { provider } so the auth service does not change.
 */
class SmsOtpSender extends OtpSender {
  constructor(provider) {
    super();
    this.provider = provider;
  }

  async send(_phone, _otp) {
    throw new Error(
      `OTP_SMS_PROVIDER="${this.provider}" is not implemented yet. Implement SmsOtpSender.send() first.`
    );
  }
}

module.exports = SmsOtpSender;
