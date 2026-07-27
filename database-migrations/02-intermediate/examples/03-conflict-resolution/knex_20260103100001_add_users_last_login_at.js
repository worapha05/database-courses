/**
 * @param {import('knex').Knex} knex
 */
exports.up = async function up(knex) {
  await knex.schema.alterTable('users', table => {
    table.timestamp('last_login_at', { useTz: true }).nullable();
  });
};

exports.down = async function down(knex) {
  await knex.schema.alterTable('users', table => {
    table.dropColumn('last_login_at');
  });
};
