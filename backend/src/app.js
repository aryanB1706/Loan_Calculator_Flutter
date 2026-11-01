const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const config = require('./config');
const { apiLimiter } = require('./middlewares/rateLimiter');
const { notFoundHandler, errorHandler } = require('./middlewares/error.middleware');
const routes = require('./routes');

const app = express();

app.disable('x-powered-by');

// Without this, every request behind a hosting proxy looks like it comes from
// the proxy's IP and all users would share one rate-limit budget.
if (config.trustProxy > 0) {
  app.set('trust proxy', config.trustProxy);
}

app.use(helmet());
app.use(cors({ origin: config.corsOrigin }));
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

if (!config.isTest) {
  app.use(morgan(config.isProduction ? 'combined' : 'dev'));
}

app.use('/api', apiLimiter, routes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
