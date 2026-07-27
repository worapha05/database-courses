# Example 01 — Prisma Basics

ตัวอย่าง schema + migration แรกแบบ Declarative

## รันเร็ว ๆ

```bash
cd examples/01-prisma-basics
cp .env.example .env # แก้ DATABASE_URL
npm install
npx prisma migrate dev --name init_users
npx prisma migrate status
```

## ไฟล์สำคัญ

| ไฟล์                                  | บทบาท                                |
| ------------------------------------- | ------------------------------------ |
| `prisma/schema.prisma`                | Source of truth (Declarative)        |
| `prisma/migrations/.../migration.sql` | SQL ที่ Prisma generate / คุณ review |
| `.env`                                | connection string                    |

## สิ่งที่ควรสังเกต

- หลัง migrate จะมีตาราง `_prisma_migrations`
- แก้โมเดลแล้วรัน `migrate dev` อีกครั้ง = ไฟล์ migration ใหม่ ไม่แก้ของเก่า
