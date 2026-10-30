const { calculateLoan, calculateEmi } = require('../src/services/loanCalculator.service');
const AppError = require('../src/utils/AppError');
const {
  LOAN_AMOUNT,
  LOAN_TENURE_MONTHS,
  ANNUAL_INTEREST_RATE_PERCENT,
} = require('../src/constants/loanRules');

function captureError(fn) {
  try {
    fn();
  } catch (error) {
    return error;
  }
  throw new Error('Expected the call to throw');
}

describe('loanCalculator.service', () => {
  describe('calculateLoan', () => {
    it('returns EMI, total payable, total interest and the interest rate', () => {
      const result = calculateLoan({ amount: 100000, tenureMonths: 12 });

      expect(result).toEqual({
        emi: 8884.88,
        totalPayable: 106618.56,
        totalInterest: 6618.56,
        interestRate: ANNUAL_INTEREST_RATE_PERCENT,
      });
    });

    it('uses the reducing-balance EMI formula', () => {
      // 100000 at 12% p.a. for 12 months.
      expect(calculateEmi(100000, 12)).toBeCloseTo(8884.8789, 3);
    });

    it('keeps totalPayable and totalInterest consistent with the rounded EMI', () => {
      const result = calculateLoan({ amount: 250000, tenureMonths: 24 });

      expect(result.totalPayable).toBeCloseTo(result.emi * 24, 2);
      expect(result.totalInterest).toBeCloseTo(result.totalPayable - 250000, 2);
    });

    it('accepts the minimum amount and tenure', () => {
      const result = calculateLoan({
        amount: LOAN_AMOUNT.MIN,
        tenureMonths: LOAN_TENURE_MONTHS.MIN,
      });

      expect(result.emi).toBeGreaterThan(0);
      expect(result.totalPayable).toBeGreaterThan(LOAN_AMOUNT.MIN);
    });

    it('accepts the maximum amount and tenure', () => {
      const result = calculateLoan({
        amount: LOAN_AMOUNT.MAX,
        tenureMonths: LOAN_TENURE_MONTHS.MAX,
      });

      expect(result.emi).toBeGreaterThan(0);
      expect(result.totalInterest).toBeGreaterThan(0);
    });
  });

  describe('loan limits', () => {
    const cases = [
      ['amount below the minimum', { amount: 9999, tenureMonths: 12 }, 'amount'],
      ['amount above the maximum', { amount: 500001, tenureMonths: 12 }, 'amount'],
      ['a fractional amount', { amount: 10000.5, tenureMonths: 12 }, 'amount'],
      ['tenure below the minimum', { amount: 100000, tenureMonths: 2 }, 'tenureMonths'],
      ['tenure above the maximum', { amount: 100000, tenureMonths: 61 }, 'tenureMonths'],
      ['a fractional tenure', { amount: 100000, tenureMonths: 12.5 }, 'tenureMonths'],
    ];

    it.each(cases)('rejects %s', (_label, body, field) => {
      const error = captureError(() => calculateLoan(body));

      expect(error).toBeInstanceOf(AppError);
      expect(error.statusCode).toBe(422);
      expect(error.errors).toEqual(expect.arrayContaining([expect.objectContaining({ field })]));
    });

    it('reports every invalid field at once', () => {
      const error = captureError(() => calculateLoan({ amount: 5000, tenureMonths: 100 }));

      expect(error.errors).toEqual([
        expect.objectContaining({ field: 'amount' }),
        expect.objectContaining({ field: 'tenureMonths' }),
      ]);
    });
  });
});
