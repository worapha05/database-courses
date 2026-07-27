# Lab Solution — Intermediate Nimbus CRM Refactor

## ลำดับขั้นที่ใช้ในเฉลย

1. สร้าง `user_statuses` + seed
2. เพิ่ม `first_name`, `last_name`, `status_id` แบบ nullable
3. Backfill ชื่อ + map status (SQL)
4. NOT NULL + FK
5. Drop `full_name`, `status`
6. Concurrent additive: `avatar_url`, `last_login_at`

## รันทดลอง

```bash
# seed ข้อมูลเก่า
psql "$DATABASE_URL" -f scripts/seed_sample_users.sql

# Prisma path
cd prisma && npx prisma migrate deploy
psql "$DATABASE_URL" -f ../scripts/verify.sql

# หรือ Knex path
cd ../knex && npx knex migrate:latest
```

อ่าน [`scripts/resolve_conflict.md`](./scripts/resolve_conflict.md) สำหรับส่วน C
