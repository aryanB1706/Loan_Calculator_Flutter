const {
  checkEligibility,
  calculateMaxEligibleAmount,
} = require('../src/services/eligibility.service');
const { ELIGIBILITY_RULES, LOAN_AMOUNT } = require('../src/constants/loanRules');

function yearsAgo(years) {
  const date = new Date();
  date.setUTCFullYear(date.getUTCFullYear() - years);
  return date;
}

function buildUser(overrides = {}) {
  return {
    dob: yearsAgo(30),
    pan: 'ABCDE1234F',
    monthlyIncome: 50000,
    creditScore: 700,
    profileCompleted: true,
    ...overrides,
  };
}

const validRequest = { amount: 100000, tenureMonths: 12 };

function reasonText(result) {
  return result.reasons.join(' ');
}

describe('eligibility.service', () => {
  describe('eligible profiles', () => {
    it('returns eligible with no reasons when every rule passes', () => {
      const result = checkEligibility(buildUser(), validRequest);

      expect(result).toEqual({
        eligible: true,
        maxEligibleAmount: 500000,
        reasons: [],
      });
    });

    it('accepts an age of exactly 21', () => {
      const result = checkEligibility(buildUser({ dob: yearsAgo(21) }), validRequest);

      expect(result.eligible).toBe(true);
    });

    it('accepts an age of exactly 60', () => {
      const result = checkEligibility(buildUser({ dob: yearsAgo(60) }), validRequest);

      expect(result.eligible).toBe(true);
    });

    it('accepts income of exactly the minimum', () => {
      const result = checkEligibility(
        buildUser({ monthlyIncome: ELIGIBILITY_RULES.MIN_MONTHLY_INCOME }),
        { amount: 10000, tenureMonths: 60 }
      );

      expect(result.eligible).toBe(true);
    });

    it('accepts a credit score of exactly the minimum', () => {
      const result = checkEligibility(
        buildUser({ creditScore: ELIGIBILITY_RULES.MIN_CREDIT_SCORE }),
        validRequest
      );

      expect(result.eligible).toBe(true);
    });

    it('accepts a lowercase PAN', () => {
      const result = checkEligibility(buildUser({ pan: 'abcde1234f' }), validRequest);

      expect(result.eligible).toBe(true);
    });
  });

  describe('age rule', () => {
    it('rejects an age below 21', () => {
      const result = checkEligibility(buildUser({ dob: yearsAgo(20) }), validRequest);

      expect(result.eligible).toBe(false);
      expect(reasonText(result)).toContain('at least 21 years old');
    });

    it('rejects an age above 60', () => {
      const result = checkEligibility(buildUser({ dob: yearsAgo(61) }), validRequest);

      expect(result.eligible).toBe(false);
      expect(reasonText(result)).toContain('60 years old or younger');
    });

    it('rejects a missing date of birth', () => {
      const result = checkEligibility(buildUser({ dob: null }), validRequest);

      expect(result.eligible).toBe(false);
      expect(reasonText(result)).toContain('date of birth is missing');
    });
  });

  describe('income rule', () => {
    it('rejects income below the minimum', () => {
      const result = checkEligibility(buildUser({ monthlyIncome: 14999 }), {
        amount: 10000,
        tenureMonths: 60,
      });

      expect(result.eligible).toBe(false);
      expect(reasonText(result)).toContain('at least ₹15,000');
    });

    it('rejects missing income and returns a zero maximum amount', () => {
      const result = checkEligibility(buildUser({ monthlyIncome: null }), validRequest);

      expect(result.eligible).toBe(false);
      expect(result.maxEligibleAmount).toBe(0);
      expect(reasonText(result)).toContain('monthly income is missing');
    });
  });

  describe('credit score rule', () => {
    it('rejects a score below 600 and shows the current score', () => {
      const result = checkEligibility(buildUser({ creditScore: 599 }), validRequest);

      expect(result.eligible).toBe(false);
      expect(reasonText(result)).toContain('at least 600');
      expect(reasonText(result)).toContain('599');
    });

    it('rejects a missing score', () => {
      const result = checkEligibility(buildUser({ creditScore: null }), validRequest);

      expect(result.eligible).toBe(false);
      expect(reasonText(result)).toContain('credit score is unavailable');
    });
  });

  describe('FOIR rule', () => {
    it('rejects an EMI above 50% of monthly income', () => {
      const result = checkEligibility(buildUser({ monthlyIncome: 20000 }), {
        amount: 200000,
        tenureMonths: 12,
      });

      expect(result.eligible).toBe(false);
      expect(reasonText(result)).toContain('more than 50% of your monthly income');
    });

    it('accepts an EMI at or below 50% of monthly income', () => {
      const result = checkEligibility(buildUser({ monthlyIncome: 20000 }), {
        amount: 100000,
        tenureMonths: 12,
      });

      expect(result.eligible).toBe(true);
    });
  });

  describe('maximum eligible amount', () => {
    it('is 10x monthly income when below the global cap', () => {
      expect(calculateMaxEligibleAmount(30000)).toBe(300000);
    });

    it('is capped at the global maximum loan amount', () => {
      expect(calculateMaxEligibleAmount(100000)).toBe(LOAN_AMOUNT.MAX);
    });

    it('rejects a request above the maximum eligible amount', () => {
      const result = checkEligibility(buildUser({ monthlyIncome: 40000 }), {
        amount: 450000,
        tenureMonths: 60,
      });

      expect(result.eligible).toBe(false);
      expect(result.maxEligibleAmount).toBe(400000);
      expect(reasonText(result)).toContain('maximum loan amount you are eligible for is ₹4,00,000');
    });

    it('accepts a request at the maximum eligible amount', () => {
      const result = checkEligibility(buildUser({ monthlyIncome: 40000 }), {
        amount: 400000,
        tenureMonths: 60,
      });

      expect(result.eligible).toBe(true);
    });
  });

  describe('profile and PAN rules', () => {
    it('rejects an incomplete profile', () => {
      const result = checkEligibility(buildUser({ profileCompleted: false }), validRequest);

      expect(result.eligible).toBe(false);
      expect(reasonText(result)).toContain('profile is incomplete');
    });

    it('rejects a missing or invalid PAN', () => {
      const missingPan = checkEligibility(buildUser({ pan: null }), validRequest);
      const invalidPan = checkEligibility(buildUser({ pan: 'ABCDE123' }), validRequest);

      expect(missingPan.eligible).toBe(false);
      expect(invalidPan.eligible).toBe(false);
      expect(reasonText(missingPan)).toContain('valid PAN is required');
      expect(reasonText(invalidPan)).toContain('valid PAN is required');
    });
  });

  describe('multiple failures', () => {
    it('returns a plain-language reason for every failed rule', () => {
      const result = checkEligibility(
        buildUser({
          profileCompleted: false,
          pan: null,
          dob: yearsAgo(20),
          monthlyIncome: 10000,
          creditScore: 550,
        }),
        { amount: 100000, tenureMonths: 12 }
      );

      expect(result.eligible).toBe(false);
      expect(result.reasons).toHaveLength(6);
      expect(result.reasons.every((reason) => typeof reason === 'string')).toBe(true);
      expect(reasonText(result)).toContain('profile is incomplete');
      expect(reasonText(result)).toContain('valid PAN is required');
      expect(reasonText(result)).toContain('at least 21 years old');
      expect(reasonText(result)).toContain('at least ₹15,000');
      expect(reasonText(result)).toContain('at least 600');
      expect(reasonText(result)).toContain('more than 50% of your monthly income');
    });
  });
});
