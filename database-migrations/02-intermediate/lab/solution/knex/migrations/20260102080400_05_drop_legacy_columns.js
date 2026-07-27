/** @param {import('knex').Knex} knex */
exports.up = async function up(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.dropColumn('full_name');
    t.dropColumn('status');
  });
};

/** @param {import('knex').Knex} knex */
exports.down = async function down(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.text('full_name');
    t.text('status');
  });
  await knex.raw(`
    UPDATE users
    SET
      full_name = btrim(first_name || ' ' || NULLIF(last_name, '-')),
      status = (SELECT code FROM user_statuses WHERE id = users.status_id)
  `);
  await knex.raw(`
    ALTER TABLE users
    ALTER COLUMN full_name SET NOT NULL,
    ALTER COLUMN status SET NOT NULL
  `);
};
