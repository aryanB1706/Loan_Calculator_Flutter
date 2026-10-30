const mongoose = require('mongoose');

const config = require('../src/config');
const { connectDB, disconnectDB } = require('../src/config/db');
const Loan = require('../src/models/Loan');
const loanWorkflowService = require('../src/services/loanWorkflow.service');
const { LOAN_STATUS } = require('../src/constants/loanRules');

// Demo path only. Real decisions come from the admin API / auto-decision.
const NEXT_STEPS = Object.freeze({
  [LOAN_STATUS.SUBMITTED]: [LOAN_STATUS.UNDER_REVIEW, LOAN_STATUS.APPROVED, LOAN_STATUS.DISBURSED],
  [LOAN_STATUS.UNDER_REVIEW]: [LOAN_STATUS.APPROVED, LOAN_STATUS.DISBURSED],
  [LOAN_STATUS.APPROVED]: [LOAN_STATUS.DISBURSED],
  [LOAN_STATUS.REJECTED]: [],
  [LOAN_STATUS.DISBURSED]: [],
});

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function simulate(loanId) {
  await connectDB();

  try {
    const loan = await Loan.findById(loanId);

    if (!loan) {
      throw new Error(`Loan application not found: ${loanId}`);
    }

    const steps = NEXT_STEPS[loan.status] || [];
    const delayMs = Number.parseInt(process.env.SIMULATION_DELAY_MS || '2000', 10);

    if (steps.length === 0) {
      console.log(`[simulate] ${loan.applicationNumber} is already ${loan.status}. Nothing to do.`);
      return;
    }

    console.log(
      `[simulate] ${loan.applicationNumber} starts at "${loan.status}". Waiting ${delayMs}ms per step.`
    );

    for (const nextStatus of steps) {
      await sleep(delayMs);
      await loanWorkflowService.transitionLoan(loan, nextStatus);
      console.log(`[simulate] ${loan.applicationNumber} -> ${loan.status}`);
    }

    console.log('[simulate] Done. Open the tracking screen to see the updates.');
  } finally {
    await disconnectDB();
  }
}

async function main() {
  if (config.isProduction) {
    throw new Error('simulate:loan is disabled when NODE_ENV=production');
  }

  const loanId = process.argv[2];

  if (!loanId) {
    console.error('Usage: npm run simulate:loan -- <loanId>');
    process.exitCode = 1;
    return;
  }

  if (!mongoose.Types.ObjectId.isValid(loanId)) {
    console.error(`Invalid loan id: ${loanId}`);
    process.exitCode = 1;
    return;
  }

  await simulate(loanId);
}

main().catch((error) => {
  console.error(`[simulate] Failed: ${error.message}`);
  process.exitCode = 1;
});
