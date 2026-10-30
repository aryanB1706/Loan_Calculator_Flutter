const mongoose = require('mongoose');

const config = require('./index');

async function connectDB() {
  mongoose.connection.on('connected', () => {
    console.log(`[db] MongoDB connected: ${mongoose.connection.name}`);
  });

  mongoose.connection.on('error', (err) => {
    console.error(`[db] MongoDB connection error: ${err.message}`);
  });

  mongoose.connection.on('disconnected', () => {
    console.warn('[db] MongoDB disconnected');
  });

  await mongoose.connect(config.mongoUri, {
    serverSelectionTimeoutMS: 10000,
  });

  return mongoose.connection;
}

async function disconnectDB() {
  await mongoose.connection.close();
  console.log('[db] MongoDB connection closed');
}

module.exports = { connectDB, disconnectDB };
