/** @param {import('knex').Knex} knex */
exports.up = async function up(knex) {
  const [{ missing }] = await knex('users')
    .whereNull('first_name')
    .orWhereNull('last_name')
    .orWhereNull('status_id')
    .count({ missing: '*' });

  if (Number(missing) > 0) {
    throw new Error(`Backfill incomplete: ${missing} rows still invalid`);
  }

  await knex.schema.alterTable('users', (t) => {
    t.string('first_name').notNullable().alter();
    t.string('last_name').notNullable().alter();
    t.integer('status_id').unsigned().notNullable().alter();
    t.foreign('status_id').references('user_statuses.id').onDelete('RESTRICT');
  });
};

/** @param {import('knex').Knex} knex */
exports.down = async function down(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.dropForeign(['status_id']);
  });
  await knex.raw(`
    ALTER TABLE users
    ALTER COLUMN first_name DROP NOT NULL,
    ALTER COLUMN last_name DROP NOT NULL,
    ALTER COLUMN status_id DROP NOT NULL
  `);
};
