/** @param {import('knex').Knex} knex */
exports.up = async function up(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.text('avatar_url');
  });
};

/** @param {import('knex').Knex} knex */
exports.down = async function down(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.dropColumn('avatar_url');
  });
};
