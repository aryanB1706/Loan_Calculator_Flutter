const mongoose = require('mongoose');

const config = require('../src/config');
const User = require('../src/models/User');
const CreditScoreLog = require('../src/models/CreditScoreLog');
const creditScoreService = require('../src/services/creditScore.service');
const { CREDIT_SCORE, CREDIT_SCORE_CHANGES } = require('../src/constants/creditScoreRules');

const PHONE = '9876500100';

let user;

beforeAll(async () => {
  await mongoose.connect(config.mongoUri);
  await Promise.all([User.init(), CreditScoreLog.init()]);
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

beforeEach(async () => {
  await Promise.all([CreditScoreLog.deleteMany({}), User.deleteMany({})]);
  user = await User.create({ phone: PHONE });
});

describe('creditScore.service', () => {
  it('starts users at the default score', () => {
    expect(user.creditScore).toBe(CREDIT_SCORE.DEFAULT);
    expect(user.creditScore).toBe(650);
  });

  it('adds 10 points for an on-time repayment and logs the change', async () => {
    const result = await creditScoreService.applyScoreChange(user, {
      change: CREDIT_SCORE_CHANGES.ON_TIME_REPAYMENT,
      reason: 'On-time repayment',
    });

    expect(result).toEqual({
      previousScore: 650,
      score: 660,
      change: 10,
      band: 'fair',
    });
    expect(user.creditScore).toBe(660);

    const log = await CreditScoreLog.findOne({ user: user._id });
    expect(log).toEqual(
      expect.objectContaining({
        change: 10,
        previousScore: 650,
        score: 660,
        reason: 'On-time repayment',
      })
    );
  });

  it('subtracts 20 points for a late repayment', async () => {
    const result = await creditScoreService.applyScoreChange(user, {
      change: CREDIT_SCORE_CHANGES.LATE_REPAYMENT,
      reason: 'Late repayment',
    });

    expect(result.score).toBe(630);
    expect(result.change).toBe(-20);
    expect(await CreditScoreLog.countDocuments({ user: user._id })).toBe(1);
  });

  it('adds the 30 point all-installments-paid bonus', async () => {
    const result = await creditScoreService.applyScoreChange(user, {
      change: CREDIT_SCORE_CHANGES.ALL_INSTALLMENTS_PAID_BONUS,
      reason: 'All installments paid',
    });

    expect(result.score).toBe(680);
    expect(result.change).toBe(30);
  });

  it('clamps the score at 900 and logs the applied change', async () => {
    user.creditScore = 895;
    await user.save();

    const result = await creditScoreService.applyScoreChange(user, {
      change: CREDIT_SCORE_CHANGES.ON_TIME_REPAYMENT,
      reason: 'On-time repayment',
    });

    expect(result.score).toBe(900);
    expect(result.change).toBe(5);

    const log = await CreditScoreLog.findOne({ user: user._id });
    expect(log.change).toBe(5);
    expect(log.score).toBe(900);
  });

  it('clamps the score at 300 and logs the applied change', async () => {
    user.creditScore = 310;
    await user.save();

    const result = await creditScoreService.applyScoreChange(user, {
      change: CREDIT_SCORE_CHANGES.LATE_REPAYMENT,
      reason: 'Late repayment',
    });

    expect(result.score).toBe(300);
    expect(result.change).toBe(-10);
  });

  it.each([
    [300, 'poor'],
    [599, 'poor'],
    [600, 'fair'],
    [699, 'fair'],
    [700, 'good'],
    [799, 'good'],
    [800, 'excellent'],
    [900, 'excellent'],
  ])('maps score %i to the %s band', (score, band) => {
    expect(creditScoreService.getBand(score)).toBe(band);
  });

  it('returns the score, band and recent changes newest first', async () => {
    await creditScoreService.applyScoreChange(user, {
      change: CREDIT_SCORE_CHANGES.ON_TIME_REPAYMENT,
      reason: 'First repayment',
    });
    await creditScoreService.applyScoreChange(user, {
      change: CREDIT_SCORE_CHANGES.LATE_REPAYMENT,
      reason: 'Second repayment',
    });

    const summary = await creditScoreService.getCreditScoreSummary(user);

    expect(summary.score).toBe(640);
    expect(summary.band).toBe('fair');
    expect(summary.recentChanges).toHaveLength(2);
    expect(summary.recentChanges[0]).toEqual(
      expect.objectContaining({
        change: -20,
        previousScore: 660,
        score: 640,
        reason: 'Second repayment',
        createdAt: expect.any(Date),
      })
    );
    expect(summary.recentChanges[1].reason).toBe('First repayment');
  });
});
