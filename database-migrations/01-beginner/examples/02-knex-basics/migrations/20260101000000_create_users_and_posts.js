/**
 * @param {import('knex').Knex} knex
 */
exports.up = async function up(knex) {
  await knex.schema.createTable('users', (table) => {
    table.increments('id').primary();
    table.string('email', 255).notNullable().unique();
    table.string('name', 255);
    table
      .enum('role', ['MEMBER', 'ADMIN'], {
        useNative: true,
        enumName: 'user_role',
      })
      .notNullable()
      .defaultTo('MEMBER');
    table.timestamps(true, true);
  });

  await knex.schema.createTable('posts', (table) => {
    table.increments('id').primary();
    table.string('title', 255).notNullable();
    table.text('content');
    table.boolean('published').notNullable().defaultTo(false);
    table
      .integer('author_id')
      .unsigned()
      .notNullable()
      .references('id')
      .inTable('users')
      .onDelete('RESTRICT');
    table.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    table.index(['author_id']);
  });
};

/**
 * @param {import('knex').Knex} knex
 */
exports.down = async function down(knex) {
  await knex.schema.dropTableIfExists('posts');
  await knex.schema.dropTableIfExists('users');
  await knex.raw('DROP TYPE IF EXISTS user_role');
};
