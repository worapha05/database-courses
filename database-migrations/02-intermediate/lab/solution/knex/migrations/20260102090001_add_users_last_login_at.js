/** @param {import('knex').Knex} knex */
exports.up = async function up(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.timestamp('last_login_at', { useTz: true });
  });
};

/** @param {import('knex').Knex} knex */
exports.down = async function down(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.dropColumn('last_login_at');
  });
};
