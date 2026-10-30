const { EventEmitter } = require('node:events');

// Internal event bus. Notification delivery will be added later as a listener;
// the workflow only announces what changed.
const loanEvents = new EventEmitter();

const LOAN_EVENTS = Object.freeze({
  STATUS_CHANGED: 'loan.status.changed',
});

module.exports = { loanEvents, LOAN_EVENTS };
