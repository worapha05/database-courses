# Lab ระดับ Beginner — ระบบร้านหนังสือออนไลน์ (BookShop)

## เป้าหมาย

ออกแบบและสร้าง schema สำหรับร้านขายหนังสือออนไลน์ขนาดเล็ก ให้ผ่าน 3NF รองรับลูกค้า สินค้า (หนังสือ)
ผู้แต่ง หมวดหมู่ ออเดอร์ และสต็อก

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

เลือกทำบน **PostgreSQL หรือ MySQL** (เฉลยมีทั้งสอง)

---

## กรณีศึกษา

บริษัท **BookNest** เพิ่งย้ายจาก Excel มาใช้ RDBMS ไฟล์เดิมมีชีตเดียวประมาณนี้:

| order_id | customer | email       | book_title   | authors          | category | qty | price | stock |
| -------- | -------- | ----------- | ------------ | ---------------- | -------- | --- | ----- | ----- |
| 1        | Mira     | mira@ex.com | Learning SQL | Alice;Bob        | Database | 2   | 550   | 30    |
| 1        | Mira     | mira@ex.com | Clean Code   | Robert C. Martin | Software | 1   | 690   | 12    |

ปัญหาที่เจอ: แก้สต็อกผิดแถว, ผู้แต่งซ้ำสะกดไม่เหมือนกัน, หาออเดอร์ของลูกค้าช้าและผิดพลาด

---

## โจทย์

### ส่วนที่ 1 — ออกแบบ Schema (บนกระดาษ/Markdown ก่อนก็ได้)

ออกแบบอย่างน้อยตารางต่อไปนี้ (ชื่อ column ตั้งเองได้ แต่ต้องครบความหมาย):

1. **`customers`** — อีเมลไม่ซ้ำ
2. **`authors`** — ชื่อผู้แต่ง
3. **`categories`** — หมวดหมู่หนังสือ
4. **`books`** — ISBN unique, ราคา `NUMERIC`/`DECIMAL`, สต็อก ≥ 0
5. **`book_authors`** — M:M ระหว่างหนังสือกับผู้แต่ง (มีลำดับผู้แต่งได้จะดี)
6. **`orders`** + **`order_items`** — snapshot ราคาตอนสั่ง

กำหนด PK/FK/CHECK/UNIQUE ให้ครบ

### ส่วนที่ 2 — DDL + Seed

- สร้างตารางทั้งหมด
- seed ลูกค้า ≥ 3, หนังสือ ≥ 5, ออเดอร์ ≥ 3 ที่มีหลายรายการ

### ส่วนที่ 3 — DML ความปลอดภัย

เขียน SQL สำหรับ:

1. เพิ่มออเดอร์ใหม่ของลูกค้าคนหนึ่ง พร้อม 2 รายการหนังสือ
2. ลดสต็อกหนังสือตามจำนวนที่ขาย (UPDATE)
3. Soft-cancel ออเดอร์ (`status = 'cancelled'`) โดย**ไม่ลบ**แถว
4. รายการหนังสือที่สต็อกต่ำกว่า 10 พร้อมชื่อหมวดหมู่

### ส่วนที่ 4 — Integrity Challenge

พิสูจน์ว่า constraint ทำงาน:

- insert หนังสือราคาติดลบ → ต้อง fail
- insert `order_items` ที่ชี้ `book_id` ไม่มีอยู่ → ต้อง fail
- insert ผู้แต่งคนเดิมในหนังสือเล่มเดิมซ้ำใน `book_authors` → ต้อง fail

---

## เกณฑ์ผ่าน

- [ ] Schema อยู่ในรูป 3NF (ไม่มี authors เป็น CSV ใน column หนังสือ)
- [ ] มี FK ครบและตั้งชื่อ constraint อ่านรู้เรื่อง
- [ ] เงินใช้ `NUMERIC`/`DECIMAL` ไม่ใช่ FLOAT
- [ ] มี seed + query รายงานอย่างน้อย 1 ชุด
- [ ] อธิบายได้ว่าทำไมเก็บราคาใน `order_items` แยกจากราคาปัจจุบันของหนังสือ

---

## คำใบ้

```text
books (M) ──< book_authors >── (M) authors
customers (1) ──< orders (1) ──< order_items >── books
```

อย่าเก็บ `authors` เป็น `'Alice;Bob'` ในตาราง books

---

## เฉลย

ดู [`lab/solution/postgresql/`](./lab/solution/postgresql/) และ
[`lab/solution/mysql/`](./lab/solution/mysql/)
