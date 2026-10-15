# Database files

The active MVP backend uses Neon PostgreSQL with Drizzle ORM. Its schema and seed code are here:

```text
backend/src/db/schema.js
backend/src/db/seed.js
backend/drizzle.config.js
```

The older `schema.sql` and `seed.sql` files are MySQL reference files from the original design and should not be run for the Drizzle MVP.
