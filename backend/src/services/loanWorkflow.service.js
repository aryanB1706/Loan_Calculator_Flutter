const AppError = require('../utils/AppError');
const { HTTP_STATUS } = require('../constants');
const { LOAN_STATUS, LOAN_STATUS_VALUES } = require('../constants/loanRules');
const { loanEvents, LOAN_EVENTS } = require('../events/loanEvents');

// The complete state machine. A status absent from this map cannot be reached.
const ALLOWED_TRANSITIONS = Object.freeze({
  [LOAN_STATUS.SUBMITTED]: Object.freeze([LOAN_STATUS.UNDER_REVIEW]),
  [LOAN_STATUS.UNDER_REVIEW]: Object.freeze([LOAN_STATUS.APPROVED, LOAN_STATUS.REJECTED]),
  [LOAN_STATUS.APPROVED]: Object.freeze([LOAN_STATUS.DISBURSED]),
  [LOAN_STATUS.REJECTED]: Object.freeze([]),
  [LOAN_STATUS.DISBURSED]: Object.freeze([]),
});

const DEFAULT_STATUS_NOTES = Object.freeze({
  [LOAN_STATUS.UNDER_REVIEW]: 'Application moved to under review',
  [LOAN_STATUS.APPROVED]: 'Application approved',
  [LOAN_STATUS.REJECTED]: 'Application rejected',
  [LOAN_STATUS.DISBURSED]: 'Loan disbursed',
});

function getAllowedTransitions(status) {
  return ALLOWED_TRANSITIONS[status] || [];
}

function canTransition(fromStatus, toStatus) {
  return getAllowedTransitions(fromStatus).includes(toStatus);
}

function assertTransitionAllowed(fromStatus, toStatus) {
  if (!LOAN_STATUS_VALUES.includes(toStatus)) {
    throw new AppError(`Unknown loan status: ${toStatus}`, HTTP_STATUS.UNPROCESSABLE_ENTITY);
  }

  if (!canTransition(fromStatus, toStatus)) {
    throw new AppError(
      `Invalid loan status transition: ${fromStatus} -> ${toStatus}`,
      HTTP_STATUS.CONFLICT
    );
  }
}

/**
 * Applies one explicit transition, records it in the history and announces the
 * change. Keeping this in one place means every caller (admin API, simulator,
 * future jobs) follows the same state machine.
 */
async function transitionLoan(loan, newStatus, note) {
  const previousStatus = loan.status;
  assertTransitionAllowed(previousStatus, newStatus);

  const finalNote =
    (typeof note === 'string' && note.trim()) || DEFAULT_STATUS_NOTES[newStatus] || '';

  loan.status = newStatus;
  loan.statusHistory.push({
    status: newStatus,
    note: finalNote,
    changedAt: new Date(),
  });
  loan.rejectionReason = newStatus === LOAN_STATUS.REJECTED ? finalNote : null;

  await loan.save();

  loanEvents.emit(LOAN_EVENTS.STATUS_CHANGED, {
    loan,
    previousStatus,
    newStatus,
    note: finalNote,
  });

  return loan;
}

module.exports = {
  ALLOWED_TRANSITIONS,
  getAllowedTransitions,
  canTransition,
  assertTransitionAllowed,
  transitionLoan,
};
