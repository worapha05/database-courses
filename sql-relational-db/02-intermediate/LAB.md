# Lab ระดับ Intermediate — platform คอร์สออนไลน์ (LearnHub)

## เป้าหมาย

สร้าง schema + ชุดรายงานสำหรับ platform คอร์สออนไลน์ โดยใช้ JOIN, aggregation, CTE และ migration
แบบมี version

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

**LearnHub** มีผู้เรียน คอร์ส หมวดหมู่ย่อย (hierarchy) การลงทะเบียน และการชำระเงิน
ทีมต้องการแดชบอร์ด:

1. คอร์สขายดี (จำนวน enrollment + รายได้)
2. ผู้เรียนที่ยังไม่ลงทะเบียนคอร์สใดเลย
3. ต้นไม้หมวดหมู่จาก root → leaf
4. เพิ่ม column `courses.level` ผ่าน migration โดยไม่ทำลายของเดิม

---

## โจทย์

### ส่วนที่ 1 — Schema + Seed

สร้างอย่างน้อย:

- `categories` (self-FK `parent_id`)
- `students`
- `courses` (FK category, ราคา)
- `enrollments` (student ↔ course, unique คู่, มี `amount_paid`, `enrolled_at`)

Seed ให้มีหมวดหมู่ซ้อนอย่างน้อย 2 ชั้น, นักเรียน ≥ 5, คอร์ส ≥ 4, enrollment ≥ 8

จัดเป็น migration:

```text
V001__init_learnhub.sql
V002__seed_learnhub.sql
V003__add_courses_level.sql
```

### ส่วนที่ 2 — รายงานด้วย JOIN / Aggregate

เขียน SQL:

1. Top 3 คอร์สตามจำนวน enrollment (INNER JOIN + GROUP BY)
2. รายได้รวมต่อหมวดหมู่ระดับบนสุด (ใช้ JOIN ไป category — จะใช้ CTE ก็ได้)
3. นักเรียนที่ไม่มี enrollment (LEFT JOIN … WHERE … IS NULL)

### ส่วนที่ 3 — CTE

1. CTE หาราคาเฉลี่ยของคอร์ส แล้วลิสต์คอร์สที่แพงกว่าค่าเฉลี่ย พร้อมส่วนต่างราคา
2. Recursive CTE แสดง path หมวดหมู่

### ส่วนที่ 4 — Migration Expand

- `V003` เพิ่ม `courses.level` เป็น `VARCHAR(20)` nullable พร้อม CHECK
  (`beginner`/`intermediate`/`advanced`) หรือ NULL
- update ข้อมูลเดิมบางส่วน
- บันทึกลง `schema_migrations`

---

## เกณฑ์ผ่าน

- [ ] รัน migration ตามลำดับซ้ำได้โดยไม่พัง (หรือ track version ชัด)
- [ ] รายงาน 3 ข้อในส่วนที่ 2 ถูกต้องตาม seed
- [ ] มี recursive category path
- [ ] อธิบายได้ว่าทำไม filter ฝั่งขวาของ LEFT JOIN บางทีต้องอยู่ใน `ON`

---

## คำใบ้

```sql
-- นักเรียนที่ยังไม่ลงทะเบียน
SELECT
  s.*
FROM
  students s
  LEFT JOIN enrollments e ON e.student_id = s.id
WHERE
  e.id IS NULL;
```

---

## เฉลย

[`lab/solution/postgresql/`](./lab/solution/postgresql/) ·
[`lab/solution/mysql/`](./lab/solution/mysql/)
