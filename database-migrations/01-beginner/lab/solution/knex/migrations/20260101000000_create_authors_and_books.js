/**
 * Bookstore lab — create authors then books; drop in reverse order.
 * @param {import('knex').Knex} knex
 */
exports.up = async function up(knex) {
  await knex.schema.createTable('authors', (table) => {
    table.increments('id').primary();
    table.string('name').notNullable();
    table.string('country');
    table.timestamp('created_at', { useTz: true }).notNullable().defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('books', (table) => {
    table.increments('id').primary();
    table.string('title').notNullable();
    table.string('isbn', 13).notNullable().unique();
    table.integer('price_cents').notNullable();
    table
      .integer('author_id')
      .unsigned()
      .notNullable()
      .references('id')
      .inTable('authors')
      .onDelete('RESTRICT');
    table.date('published_at');
    table.timestamp('created_at', { useTz: true }).notNullable().defaultTo(knex.fn.now());
  });

  await knex.raw(
    'ALTER TABLE books ADD CONSTRAINT books_price_cents_check CHECK (price_cents > 0)',
  );
};

/**
 * @param {import('knex').Knex} knex
 */
exports.down = async function down(knex) {
  await knex.schema.dropTableIfExists('books');
  await knex.schema.dropTableIfExists('authors');
};
