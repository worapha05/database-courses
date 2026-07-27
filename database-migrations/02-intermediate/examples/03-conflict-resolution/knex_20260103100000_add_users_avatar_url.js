/**
 * @param {import('knex').Knex} knex
 */
exports.up = async function up(knex) {
  await knex.schema.alterTable('users', table => {
    table.text('avatar_url').nullable();
  });
};

exports.down = async function down(knex) {
  await knex.schema.alterTable('users', table => {
    table.dropColumn('avatar_url');
  });
};
