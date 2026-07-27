require('dotenv').config();

/**
 * Knex configuration — Imperative migrations live under ./migrations
 */
module.exports = {
  development: {
    client: 'pg',
    connection: process.env.DATABASE_URL || {
      host: '127.0.0.1',
      user: 'postgres',
      password: 'postgres',
      database: 'migrations_lab',
    },
    migrations: {
      directory: './migrations',
      tableName: 'knex_migrations',
      extension: 'js',
    },
    pool: { min: 0, max: 5 },
  },
};
