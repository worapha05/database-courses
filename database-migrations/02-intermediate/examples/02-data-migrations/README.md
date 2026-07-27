# Example 02 — Data Migrations

แยก structural change กับ transformation ของข้อมูล

## ไฟล์

| ไฟล์                                     | Tool                       |
| ---------------------------------------- | -------------------------- |
| `knex_20260102090000_split_full_name.js` | Knex data+schema pair      |
| `prisma_backfill_display_name.ts`        | script หลัง Prisma migrate |
| `transform_status.sql`                   | Pure SQL mapping           |
