const path = require('path');
const dotenv = require('dotenv');

dotenv.config({
  path: process.env.ENV_FILE || path.resolve(__dirname, '../../../.env')
});

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 4000),
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET || 'development-only-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '8h',
  corsOrigin: process.env.CORS_ORIGIN || 'http://localhost:5173'
};

if (env.nodeEnv === 'production' && env.jwtSecret === 'development-only-secret') {
  throw new Error('JWT_SECRET must be configured in production.');
}

module.exports = env;
