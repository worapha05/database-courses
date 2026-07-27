/**
 * Schema + data in separate clear sections.
 * Prefer splitting into two migration files in real teams.
 * @param {import('knex').Knex} knex
 */
exports.up = async function up(knex) {
  // --- Schema (Expand) ---
  await knex.schema.alterTable('users', table => {
    table.string('first_name', 120).nullable();
    table.string('last_name', 120).nullable();
  });

  // --- Data (Transform), batched ---
  const batchSize = 500;
  for (;;) {
    const rows = await knex('users')
      .select('id', 'full_name')
      .whereNull('first_name')
      .orderBy('id')
      .limit(batchSize);

    if (rows.length === 0) break;

    for (const row of rows) {
      const parts = String(row.full_name || '')
        .trim()
        .split(/\s+/)
        .filter(Boolean);
      const firstName = parts[0] || 'Unknown';
      const lastName = parts.length > 1 ? parts.slice(1).join(' ') : '-';
      await knex('users').where({ id: row.id }).update({
        first_name: firstName,
        last_name: lastName,
      });
    }
  }
};

/**
 * @param {import('knex').Knex} knex
 */
exports.down = async function down(knex) {
  await knex.schema.alterTable('users', table => {
    table.dropColumn('first_name');
    table.dropColumn('last_name');
  });
};
