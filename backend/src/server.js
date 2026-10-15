const app = require('./app');
const env = require('./config/env');
const { testConnection } = require('./config/database');

async function start() {
  try {
    await testConnection();
    app.listen(env.port, () => {
      console.log(`Hospital management API listening on port ${env.port}`);
    });
  } catch (error) {
    console.error('Unable to connect to MySQL:', error.message);
    process.exitCode = 1;
  }
}

start();
