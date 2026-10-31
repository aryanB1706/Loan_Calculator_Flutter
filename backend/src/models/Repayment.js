const mongoose = require('mongoose');

const { REPAYMENT_STATUS, REPAYMENT_STATUS_VALUES } = require('../constants/repaymentRules');

const repaymentSchema = new mongoose.Schema(
  {
    loan: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Loan',
      required: true,
      index: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    installmentNumber: {
      type: Number,
      required: true,
      min: 1,
    },
    dueDate: {
      type: Date,
      required: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    status: {
      type: String,
      enum: REPAYMENT_STATUS_VALUES,
      default: REPAYMENT_STATUS.PENDING,
      required: true,
    },
    paidAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

// A loan can have exactly one row for each installment.
repaymentSchema.index({ loan: 1, installmentNumber: 1 }, { unique: true });
repaymentSchema.index({ user: 1, dueDate: 1 });

repaymentSchema.set('toJSON', {
  transform: (_doc, ret) => {
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Repayment', repaymentSchema);
