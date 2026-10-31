const mongoose = require('mongoose');

const {
  LOAN_AMOUNT,
  LOAN_TENURE_MONTHS,
  LOAN_STATUS,
  LOAN_STATUS_VALUES,
  ACTIVE_LOAN_STATUSES,
  LOAN_PURPOSE,
} = require('../constants/loanRules');

const statusHistorySchema = new mongoose.Schema(
  {
    status: {
      type: String,
      enum: LOAN_STATUS_VALUES,
      required: true,
    },
    note: {
      type: String,
      trim: true,
      default: '',
    },
    changedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const loanSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    applicationNumber: {
      type: String,
      required: true,
      unique: true,
      immutable: true,
    },
    amount: {
      type: Number,
      required: true,
      min: LOAN_AMOUNT.MIN,
      max: LOAN_AMOUNT.MAX,
    },
    tenureMonths: {
      type: Number,
      required: true,
      min: LOAN_TENURE_MONTHS.MIN,
      max: LOAN_TENURE_MONTHS.MAX,
    },
    interestRate: {
      type: Number,
      required: true,
      min: 0,
    },
    emi: {
      type: Number,
      required: true,
      min: 0,
    },
    totalPayable: {
      type: Number,
      required: true,
      min: 0,
    },
    purpose: {
      type: String,
      required: true,
      trim: true,
      minlength: LOAN_PURPOSE.MIN_LENGTH,
      maxlength: LOAN_PURPOSE.MAX_LENGTH,
    },
    status: {
      type: String,
      enum: LOAN_STATUS_VALUES,
      default: LOAN_STATUS.SUBMITTED,
      required: true,
    },
    statusHistory: {
      type: [statusHistorySchema],
      default: [],
    },
    rejectionReason: {
      type: String,
      trim: true,
      default: null,
    },
  },
  { timestamps: true }
);

// One user can have only one application in an active state. The service checks
// this first for a clean message; the unique index also protects against two
// requests racing past that check.
loanSchema.index(
  { user: 1 },
  {
    unique: true,
    partialFilterExpression: { status: { $in: [...ACTIVE_LOAN_STATUSES] } },
    name: 'unique_active_application_per_user',
  }
);

// Supports "my applications, newest first" without a full collection scan.
loanSchema.index({ user: 1, createdAt: -1 });

loanSchema.set('toJSON', {
  transform: (_doc, ret) => {
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Loan', loanSchema);
