const REPAYMENT_STATUS = Object.freeze({
  PENDING: 'pending',
  PAID: 'paid',
  LATE: 'late',
});

const REPAYMENT_STATUS_VALUES = Object.freeze(Object.values(REPAYMENT_STATUS));

module.exports = { REPAYMENT_STATUS, REPAYMENT_STATUS_VALUES };
