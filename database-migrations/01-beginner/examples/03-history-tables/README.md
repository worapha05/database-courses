# Example 03 — History Tracking Tables

SQL อ้างอิงโครงสร้างตารางประวัติของ Prisma / Knex / Liquibase ใช้ศึกษา — ไม่จำเป็นต้องสร้างเอง (tool
สร้างให้อัตโนมัติ)

## Prisma — `_prisma_migrations`

ดู [`prisma_migrations.sql`](./prisma_migrations.sql)

column สำคัญ:

- `migration_name` — ชื่อ folder migration
- `checksum` — hash ของไฟล์ SQL (แก้ไฟล์เก่า = mismatch)
- `finished_at` — NULL ถ้า fail กลางคัน
- `rolled_back_at` — ถูก mark ว่า rollback แล้ว

## Knex — `knex_migrations` + lock

ดู [`knex_migrations.sql`](./knex_migrations.sql)

- `batch` — กลุ่มที่รันพร้อมกันในคำสั่ง `migrate:latest` ครั้งเดียว
- rollback จะย้อนทั้ง batch ล่าสุด

## Liquibase — `DATABASECHANGELOG`

ดู [`liquibase_changelog.sql`](./liquibase_changelog.sql) (จะใช้จริงในระดับ Expert)

- `md5sum` — คล้าย checksum ของ Prisma
- `orderexecuted` — ลำดับที่รันจริง
