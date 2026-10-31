const CreditScoreLog = require('../models/CreditScoreLog');
const { CREDIT_SCORE, CREDIT_SCORE_BANDS } = require('../constants/creditScoreRules');

function clampScore(score) {
  return Math.min(CREDIT_SCORE.MAX, Math.max(CREDIT_SCORE.MIN, score));
}

function getBand(score) {
  if (score < CREDIT_SCORE_BANDS.POOR_BELOW) return 'poor';
  if (score < CREDIT_SCORE_BANDS.FAIR_BELOW) return 'fair';
  if (score < CREDIT_SCORE_BANDS.GOOD_BELOW) return 'good';
  return 'excellent';
}

/**
 * Applies one movement, clamps it to the allowed range and stores an audit row.
 * The logged change is the amount actually applied after clamping, so summing
 * the log always matches the current score.
 */
async function applyScoreChange(user, { change, reason, loanId = null, repaymentId = null }) {
  const previousScore = Number.isFinite(user.creditScore) ? user.creditScore : CREDIT_SCORE.DEFAULT;
  const score = clampScore(previousScore + change);
  const appliedChange = score - previousScore;

  user.creditScore = score;
  await user.save();

  await CreditScoreLog.create({
    user: user._id,
    loan: loanId,
    repayment: repaymentId,
    change: appliedChange,
    previousScore,
    score,
    reason,
  });

  return { previousScore, score, change: appliedChange, band: getBand(score) };
}

async function getCreditScoreSummary(user) {
  const recentLogs = await CreditScoreLog.find({ user: user._id })
    .sort({ createdAt: -1, _id: -1 })
    .limit(CREDIT_SCORE.RECENT_CHANGES_LIMIT)
    .lean();

  return {
    score: user.creditScore,
    band: getBand(user.creditScore),
    recentChanges: recentLogs.map(({ change, previousScore, score, reason, createdAt }) => ({
      change,
      previousScore,
      score,
      reason,
      createdAt,
    })),
  };
}

module.exports = { clampScore, getBand, applyScoreChange, getCreditScoreSummary };
