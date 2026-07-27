# Lab Solution — Beginner Bookstore

เฉลยเต็มสำหรับโจทย์ใน [`../../LAB.md`](../../LAB.md)

## วิธีคิดสั้น ๆ

1. สร้าง `authors` ก่อน `books`
2. Prisma: โมเดลใน `schema.prisma` คือ source of truth → SQL อยู่ใน `migrations/`
3. Knex: `up` สร้างตามลำดับ, `down` ลบย้อนลำดับ
4. ตรวจ FK ด้วย insert ที่ต้อง fail

## คำตอบทฤษฎี

1. **`db push` ไม่เหมาะ Staging/Prod** เพราะไม่สร้าง migration history มาตรฐานเหมือน `migrate` —
   ทีมไล่ version/ review SQL ใน PR ไม่ได้ และ environment จะ drift ง่าย
2. **Rename ถูกมองเป็น drop+add** → ข้อมูลใน column เก่าหาย (หรือต้อง backfill เอง) — ต้องใช้
   `migrate dev` แล้วปรับ SQL เป็น `RENAME` หรือทำ Expand/Contract
3. **Source of truth** — Declarative = โมเดลปัจจุบัน (`schema.prisma`); Imperative =
   ลำดับขั้นตอนในไฟล์ `up/down`

## รันเฉลย

```bash
# Prisma
cd prisma && cp ../../examples/01-prisma-basics/.env.example .env
npm install && npx prisma migrate deploy

# Knex (ใช้ DB คนละ schema/database ถ้าต้องการไม่ชนกับ Prisma)
cd ../knex && cp .env.example .env
npm install && npx knex migrate:latest
```
