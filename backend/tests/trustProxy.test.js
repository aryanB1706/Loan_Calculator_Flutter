// The config is read once when it is first required, so each case loads a fresh
// copy of the app with its own environment.
function loadApp(trustProxy) {
  let app;

  jest.isolateModules(() => {
    if (trustProxy === undefined) {
      delete process.env.TRUST_PROXY;
    } else {
      process.env.TRUST_PROXY = trustProxy;
    }
    app = require('../src/app');
  });

  return app;
}

afterEach(() => {
  delete process.env.TRUST_PROXY;
});

describe('TRUST_PROXY', () => {
  it('is off by default, so a client cannot fake its IP', () => {
    expect(loadApp(undefined).get('trust proxy')).toBeFalsy();
  });

  it('trusts one proxy hop when set to 1 (Render)', () => {
    expect(loadApp('1').get('trust proxy')).toBe(1);
  });
});
