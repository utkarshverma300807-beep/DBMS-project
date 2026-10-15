// Compatibility export for modules that import config/database.
// The active database implementation is Neon PostgreSQL + Drizzle.
module.exports = require('../db');
