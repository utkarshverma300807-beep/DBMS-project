const dotenv = require('dotenv');
const { defineConfig } = require('drizzle-kit');

dotenv.config({ path: process.env.ENV_FILE || '../.env' });

module.exports = defineConfig({
  schema: './src/db/schema.js',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    // Use the direct Neon endpoint for schema pushes and migrations.
    url: process.env.DATABASE_URL_UNPOOLED || process.env.DATABASE_URL
  },
  strict: true,
  verbose: true
});
