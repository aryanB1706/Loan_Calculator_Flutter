const config = require('../../config');
const DemoOtpSender = require('./demoOtpSender');
const ConsoleOtpSender = require('./consoleOtpSender');
const SmsOtpSender = require('./smsOtpSender');

/** Selects the OTP delivery strategy from OTP_MODE. */
function getOtpSender() {
  switch (config.otp.mode) {
    case 'demo':
      return new DemoOtpSender();
    case 'console':
      return new ConsoleOtpSender();
    case 'sms':
      return new SmsOtpSender(config.otp.smsProvider);
    default:
      throw new Error(`Unsupported OTP_MODE: ${config.otp.mode}`);
  }
}

module.exports = { getOtpSender };
