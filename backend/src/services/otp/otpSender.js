/**
 * Contract for OTP delivery providers.
 *
 * Implementations return { provider } after attempting delivery. Delivery
 * failures should throw so the auth service can invalidate the OTP.
 */
class OtpSender {
  // eslint-disable-next-line no-unused-vars
  async send(phone, otp) {
    throw new Error('OtpSender.send() must be implemented by a subclass');
  }
}

module.exports = OtpSender;
