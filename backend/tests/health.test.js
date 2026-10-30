const request = require('supertest');

const app = require('../src/app');

describe('GET /api/health', () => {
  it('returns 200 with the standard success shape', async () => {
    const res = await request(app).get('/api/health');

    expect(res.status).toBe(200);
    expect(res.body).toEqual(
      expect.objectContaining({
        success: true,
        message: expect.any(String),
        data: expect.objectContaining({
          status: 'ok',
          uptime: expect.any(Number),
          timestamp: expect.any(String),
        }),
      })
    );
  });
});

describe('Unknown routes', () => {
  it('returns 404 with the standard error shape', async () => {
    const res = await request(app).get('/api/does-not-exist');

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Route not found');
  });
});
