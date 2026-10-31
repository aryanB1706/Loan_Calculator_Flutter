const mongoose = require('mongoose');

const { CREDIT_SCORE } = require('../constants/creditScoreRules');

// One row per score movement so the current score can always be explained.
const creditScoreLogSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    loan: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Loan',
      default: null,
    },
    repayment: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Repayment',
      default: null,
    },
    change: {
      type: Number,
      required: true,
    },
    previousScore: {
      type: Number,
      required: true,
      min: CREDIT_SCORE.MIN,
      max: CREDIT_SCORE.MAX,
    },
    score: {
      type: Number,
      required: true,
      min: CREDIT_SCORE.MIN,
      max: CREDIT_SCORE.MAX,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
    },
  },
  { timestamps: true }
);

creditScoreLogSchema.index({ user: 1, createdAt: -1 });

creditScoreLogSchema.set('toJSON', {
  transform: (_doc, ret) => {
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('CreditScoreLog', creditScoreLogSchema);
