const mongoose = require('mongoose');
const env = require('./env');

let isConnected = false;

async function connectDb() {
  if (isConnected) return mongoose.connection;
  const conn = await mongoose.connect(env.mongodbUri);
  isConnected = true;
  return conn;
}

module.exports = { connectDb };
