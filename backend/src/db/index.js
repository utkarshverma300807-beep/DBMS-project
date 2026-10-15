const { Pool } = require('pg');
const { drizzle } = require('drizzle-orm/node-postgres');
const env = require('../config/env');
const schema = require('./schema');

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is required for the Neon/Drizzle backend.');
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

const db = drizzle(pool, { schema });

async function testConnection() {
  await pool.query('SELECT 1');
}

async function closeDatabase() {
  await pool.end();
}

module.exports = { db, pool, testConnection, closeDatabase };
