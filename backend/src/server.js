const app = require('./app');
const config = require('./config');
const { connectDB, disconnectDB } = require('./config/db');

let server;

async function startServer() {
  await connectDB();

  server = app.listen(config.port, () => {
    console.log(`[server] Listening on http://localhost:${config.port} (${config.env})`);
  });
}

async function shutdown(signal) {
  console.log(`[server] Received ${signal}, shutting down...`);

  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }

  await disconnectDB();
  process.exit(0);
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

process.on('unhandledRejection', (reason) => {
  console.error('[server] Unhandled rejection:', reason);
  process.exit(1);
});

process.on('uncaughtException', (err) => {
  console.error('[server] Uncaught exception:', err);
  process.exit(1);
});

startServer().catch((err) => {
  console.error('[server] Failed to start:', err);
  process.exit(1);
});
