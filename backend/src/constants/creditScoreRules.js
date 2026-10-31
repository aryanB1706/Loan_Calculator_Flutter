const CREDIT_SCORE = Object.freeze({
  MIN: 300,
  MAX: 900,
  DEFAULT: 650,
  RECENT_CHANGES_LIMIT: 10,
});

// Every credit score movement lives here so the rules are easy to audit.
const CREDIT_SCORE_CHANGES = Object.freeze({
  ON_TIME_REPAYMENT: 10,
  LATE_REPAYMENT: -20,
  ALL_INSTALLMENTS_PAID_BONUS: 30,
});

const CREDIT_SCORE_BANDS = Object.freeze({
  POOR_BELOW: 600,
  FAIR_BELOW: 700,
  GOOD_BELOW: 800,
});

module.exports = {
  CREDIT_SCORE,
  CREDIT_SCORE_CHANGES,
  CREDIT_SCORE_BANDS,
};
