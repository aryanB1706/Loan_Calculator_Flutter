const { calculateEmi } = require('./loanCalculator.service');
const { calculateAge } = require('../utils/date');
const { PAN_REGEX } = require('../utils/pan');
const { LOAN_AMOUNT, ELIGIBILITY_RULES } = require('../constants/loanRules');

const {
  MIN_AGE,
  MAX_AGE,
  MIN_MONTHLY_INCOME,
  MIN_CREDIT_SCORE,
  MAX_FOIR_PERCENT,
  MAX_AMOUNT_MULTIPLIER,
} = ELIGIBILITY_RULES;

function formatAmount(amount) {
  return `₹${Number(amount).toLocaleString('en-IN')}`;
}

/** Returns null when the value is missing, so callers can show a clear reason. */
function toFiniteNumber(value) {
  if (value === undefined || value === null || value === '') return null;

  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function getAge(dob) {
  if (!dob) return null;

  const date = dob instanceof Date ? dob : new Date(dob);
  if (Number.isNaN(date.getTime())) return null;

  return calculateAge(date);
}

function hasValidPan(pan) {
  return typeof pan === 'string' && PAN_REGEX.test(pan.trim().toUpperCase());
}

function checkProfile(user, reasons) {
  if (user.profileCompleted !== true) {
    reasons.push('Your profile is incomplete. Complete all profile details before applying.');
  }

  if (!hasValidPan(user.pan)) {
    reasons.push('A valid PAN is required. Add a PAN in the format ABCDE1234F to your profile.');
  }
}

function checkAge(dob, reasons) {
  const age = getAge(dob);

  if (age === null) {
    reasons.push('Your date of birth is missing or invalid. Please complete your profile.');
    return;
  }

  if (age < MIN_AGE) {
    reasons.push(`You must be at least ${MIN_AGE} years old to apply for a loan.`);
    return;
  }

  if (age > MAX_AGE) {
    reasons.push(`You must be ${MAX_AGE} years old or younger to apply for a loan.`);
  }
}

function checkIncome(income, reasons) {
  if (income === null) {
    reasons.push('Your monthly income is missing. Add it to your profile before applying.');
    return;
  }

  if (income < MIN_MONTHLY_INCOME) {
    reasons.push(
      `Your monthly income must be at least ${formatAmount(MIN_MONTHLY_INCOME)} to apply.`
    );
  }
}

function checkCreditScore(user, reasons) {
  const score = toFiniteNumber(user.creditScore);

  if (score === null) {
    reasons.push('Your credit score is unavailable. Please try again later.');
    return;
  }

  if (score < MIN_CREDIT_SCORE) {
    reasons.push(
      `A credit score of at least ${MIN_CREDIT_SCORE} is required. Your current score is ${score}.`
    );
  }
}

function checkFoir({ income, amount, tenureMonths }, reasons) {
  // Without a usable income or valid terms the other rules already explain the
  // failure, so the FOIR ratio cannot be meaningfully calculated.
  if (income === null || income <= 0) return;
  if (!Number.isFinite(amount) || !Number.isInteger(tenureMonths)) return;

  const emi = calculateEmi(amount, tenureMonths);
  const maxAffordableEmi = (income * MAX_FOIR_PERCENT) / 100;

  if (emi > maxAffordableEmi) {
    reasons.push(
      `The estimated EMI of ${formatAmount(Math.round(emi))} is more than ${MAX_FOIR_PERCENT}% of your monthly income (${formatAmount(maxAffordableEmi)}). Try a smaller amount or a longer tenure.`
    );
  }
}

function calculateMaxEligibleAmount(income) {
  if (income === null || income <= 0) return 0;

  return Math.min(Math.round(income * MAX_AMOUNT_MULTIPLIER), LOAN_AMOUNT.MAX);
}

function checkRequestedAmount({ amount, income, maxEligibleAmount }, reasons) {
  if (income === null || income <= 0) return;
  if (!Number.isFinite(amount)) return;

  if (amount > maxEligibleAmount) {
    reasons.push(
      `The maximum loan amount you are eligible for is ${formatAmount(maxEligibleAmount)}, but you requested ${formatAmount(amount)}.`
    );
  }
}

/**
 * Runs every rule against the stored profile and the requested loan terms.
 * All failures are collected so the app can show every reason at once.
 */
function checkEligibility(user, { amount, tenureMonths }) {
  const income = toFiniteNumber(user.monthlyIncome);
  const reasons = [];

  checkProfile(user, reasons);
  checkAge(user.dob, reasons);
  checkIncome(income, reasons);
  checkCreditScore(user, reasons);

  checkFoir({ income, amount, tenureMonths }, reasons);

  const maxEligibleAmount = calculateMaxEligibleAmount(income);
  checkRequestedAmount({ amount, income, maxEligibleAmount }, reasons);

  return {
    eligible: reasons.length === 0,
    maxEligibleAmount,
    reasons,
  };
}

module.exports = { checkEligibility, calculateMaxEligibleAmount };
