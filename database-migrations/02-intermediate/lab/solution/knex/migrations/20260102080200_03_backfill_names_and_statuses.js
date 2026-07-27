/** @param {import('knex').Knex} knex */
exports.up = async function up(knex) {
  await knex.raw(`
    UPDATE users
    SET
      first_name = CASE
        WHEN full_name IS NULL OR btrim(full_name) = '' THEN 'Unknown'
        ELSE split_part(btrim(full_name), ' ', 1)
      END,
      last_name = CASE
        WHEN full_name IS NULL OR btrim(full_name) = '' THEN '-'
        WHEN position(' ' IN btrim(full_name)) = 0 THEN '-'
        ELSE btrim(substr(btrim(full_name), position(' ' IN btrim(full_name)) + 1))
      END
    WHERE first_name IS NULL OR last_name IS NULL
  `);

  await knex.raw(`
    UPDATE users u
    SET status_id = s.id
    FROM user_statuses s
    WHERE u.status_id IS NULL
    AND lower(btrim(u.status)) = s.code
  `);

  await knex.raw(`
    UPDATE users u
    SET status_id = s.id
    FROM user_statuses s
    WHERE u.status_id IS NULL
    AND s.code = 'disabled'
  `);
};

exports.down = async function down() {
  // Data transforms are not auto-reversed; restore from backup if needed.
};
