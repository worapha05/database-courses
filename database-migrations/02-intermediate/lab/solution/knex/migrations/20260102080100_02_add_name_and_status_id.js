/** @param {import('knex').Knex} knex */
exports.up = async function up(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.string('first_name');
    t.string('last_name');
    t.integer('status_id').unsigned();
  });
};

/** @param {import('knex').Knex} knex */
exports.down = async function down(knex) {
  await knex.schema.alterTable('users', (t) => {
    t.dropColumn('first_name');
    t.dropColumn('last_name');
    t.dropColumn('status_id');
  });
};
