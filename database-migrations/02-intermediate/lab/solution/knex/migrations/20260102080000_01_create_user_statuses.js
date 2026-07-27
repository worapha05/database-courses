/** @param {import('knex').Knex} knex */
exports.up = async function up(knex) {
  const hasUsers = await knex.schema.hasTable('users');
  if (!hasUsers) {
    await knex.schema.createTable('users', (t) => {
      t.increments('id').primary();
      t.text('full_name').notNullable();
      t.text('email').notNullable().unique();
      t.text('phone');
      t.text('status').notNullable();
      t.timestamp('created_at', { useTz: true }).notNullable().defaultTo(knex.fn.now());
    });
  }

  await knex.schema.createTable('user_statuses', (t) => {
    t.increments('id').primary();
    t.string('code', 32).notNullable().unique();
    t.text('label').notNullable();
  });

  await knex('user_statuses').insert([
    { code: 'active', label: 'Active' },
    { code: 'disabled', label: 'Disabled' },
    { code: 'banned', label: 'Banned' },
  ]);
};

/** @param {import('knex').Knex} knex */
exports.down = async function down(knex) {
  await knex.schema.dropTableIfExists('user_statuses');
};
