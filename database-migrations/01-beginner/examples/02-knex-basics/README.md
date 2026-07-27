# Example 02 — Knex Basics

ตัวอย่าง Imperative migration ด้วย `up` / `down`

## รันเร็ว ๆ

```bash
cd examples/02-knex-basics
cp .env.example .env
npm install
npx knex migrate:latest
npx knex migrate:list
npx knex migrate:rollback
npx knex migrate:latest
```

## สิ่งที่ควรสังเกต

- `knex_migrations` บันทึกชื่อไฟล์ + batch
- `knex_migrations_lock` กันไม่ให้สอง process migrate พร้อมกัน
- `down` ต้องย้อน dependency ให้ถูกลำดับ
