# Level 1 — Beginner: Database Foundations & SQL Core

ระดับนี้สร้างรากฐานที่แข็งแรง: เข้าใจว่า **ข้อมูลถูกจัดเป็นตารางอย่างไร**, ทำไมต้องมี **PK/FK**,
เลือก **type/constraint** อย่างไร และเขียน **CRUD** ที่ถูกต้อง พร้อมหลัก **Normalization**
ที่ใช้ในงานจริง

---

## สิ่งที่คุณจะได้หลังจบระดับนี้

- อธิบาย Relational Model และความสัมพันธ์ 1:1 / 1:M / M:M ได้
- ออกแบบตารางด้วย PK, FK, UNIQUE, CHECK, NOT NULL, DEFAULT
- เขียน INSERT / SELECT / UPDATE / DELETE ที่ปลอดภัยและอ่านง่าย
- แยก schema จาก 0NF → 1NF → 2NF → 3NF พร้อมเหตุผล

---

## โครงสร้างไฟล์

| folder                                                                         | เนื้อหา                      |
| ------------------------------------------------------------------------------ | ---------------------------- |
| [`examples/01-relational-model/`](./examples/01-relational-model/)             | Tables, PK, FK, ความสัมพันธ์ |
| [`examples/02-data-types-constraints/`](./examples/02-data-types-constraints/) | Types + Constraints          |
| [`examples/03-crud-operations/`](./examples/03-crud-operations/)               | INSERT/SELECT/UPDATE/DELETE  |
| [`examples/04-normalization/`](./examples/04-normalization/)                   | 1NF → 2NF → 3NF + M:M        |
| [`LAB.md`](./LAB.md)                                                           | Lab: ระบบร้านหนังสือออนไลน์  |

ทุกตัวอย่างมี `postgresql/` และ `mysql/`

---

## 1. Relational Database Model

### 1.1 แนวคิดหลัก

ฐานข้อมูลเชิงสัมพันธ์จัดข้อมูลเป็น **relation (ตาราง)** ที่ประกอบด้วย:

| คำศัพท์            | ความหมาย                                | ตัวอย่าง                      |
| ------------------ | --------------------------------------- | ----------------------------- |
| Table (Relation)   | ชุดของแถวที่มีโครงสร้าง column เดียวกัน | `customers`                   |
| Row (Tuple)        | หนึ่งเรคอร์ด                            | ลูกค้าคนหนึ่ง                 |
| Column (Attribute) | คุณสมบัติของข้อมูล                      | `email`, `created_at`         |
| Domain             | ชุดค่าที่ column รับได้                 | อีเมลที่ถูกต้อง, จำนวนเต็มบวก |
| Primary Key (PK)   | ตัวระบุแถวที่ไม่ซ้ำและไม่เป็น NULL      | `customers.id`                |
| Foreign Key (FK)   | column ที่อ้างถึง PK ของตารางอื่น       | `orders.customer_id`          |

**กฎสำคัญของ Relational Model (Codd):**

1. ทุกค่าใน cell เป็น **atomic** (ค่าเดียว ไม่ใช่ list ใน cell)
2. ไม่มีแถวซ้ำกัน (ในทางปฏิบัติบังคับด้วย PK)
3. ลำดับแถวและลำดับ column ไม่มีความหมายทางตรรกะ
4. ความสัมพันธ์ระหว่างตารางทำผ่าน **ค่าที่ตรงกัน** (value-based) ไม่ใช่ pointer ทางกายภาพ

### 1.2 Primary Key — เลือกอย่างไร

| แบบ                                                   | ข้อดี                              | ข้อควรระวัง                        |
| ----------------------------------------------------- | ---------------------------------- | ---------------------------------- |
| Surrogate key (`BIGSERIAL` / `BIGINT AUTO_INCREMENT`) | เสถียร, ไม่ผูกกับธุรกิจ, join เร็ว | ไม่มีความหมายทางธุรกิจ             |
| Natural key (`email`, `isbn`)                         | อ่านง่าย, ไม่ต้อง lookup           | ธุรกิจเปลี่ยนค่าได้ → cascade ยุ่ง |
| Composite PK                                          | เหมาะกับตารางเชื่อม M:M            | FK จากตารางอื่นจะยาวและซับซ้อน     |

**Best Practice:** ใช้ surrogate PK เป็นค่าเริ่มต้น และใส่ `UNIQUE` บน natural key
ที่ธุรกิจต้องไม่ซ้ำ (เช่น `email`, `sku`)

### 1.3 Foreign Key และ Referential Integrity

FK รับประกันว่าค่าที่อ้างถึง **มีอยู่จริง** ในตารางแม่

```text
customers (1) ──────< orders (M)
 id PK   customer_id FK → customers.id
```

ตัวเลือกเมื่อลบ/update แถวแม่:

| Action                   | ความหมาย            | ใช้เมื่อ                                                      |
| ------------------------ | ------------------- | ------------------------------------------------------------- |
| `RESTRICT` / `NO ACTION` | ห้ามลบถ้ายังมีลูก   | ค่าเริ่มต้นที่ปลอดภัย                                         |
| `CASCADE`                | ลบลูกตาม            | ความสัมพันธ์ที่เป็นส่วนประกอบแท้ (เช่น order_items ของ order) |
| `SET NULL`               | ตั้ง FK เป็น NULL   | ความสัมพันธ์ optional                                         |
| `SET DEFAULT`            | ตั้งเป็นค่า default | ใช้น้อย ต้องออกแบบ default ให้ดี                              |

**อย่าใช้ CASCADE มั่ว** — โดยเฉพาะตารางที่ลบแล้วกระทบ audit / การเงิน

### 1.4 ความสัมพันธ์ (Cardinality)

```text
1:1 users ── user_profiles  (FK มักอยู่ฝั่ง profile, UNIQUE)
1:M customers ──< orders  (FK อยู่ฝั่ง "หลาย")
M:M products >──< categories (ต้องมีตารางกลาง product_categories)
```

ตารางกลาง (junction / associative) สำหรับ M:M ควรมี:

- PK ของตัวเอง **หรือ** composite PK จากสอง FK
- `UNIQUE (product_id, category_id)` กันซ้ำ
- column เพิ่มได้ เช่น `assigned_at`, `is_primary`

---

## 2. Data Types & Constraints

### 2.1 เลือก Type ให้ถูก — ไม่ใช่เลือกที่ “กว้างที่สุด”

| ความต้องการ           | PostgreSQL                           | MySQL                               | เหตุผล                           |
| --------------------- | ------------------------------------ | ----------------------------------- | -------------------------------- |
| ID ภายใน              | `BIGINT GENERATED ...` / `BIGSERIAL` | `BIGINT AUTO_INCREMENT`             | รองรับโตในอนาคต                  |
| เงิน                  | `NUMERIC(12,2)`                      | `DECIMAL(12,2)`                     | ห้ามใช้ `FLOAT` กับเงิน          |
| ข้อความสั้น fixed-ish | `VARCHAR(n)`                         | `VARCHAR(n)`                        | ใส่ความยาวตามธุรกิจจริง          |
| ข้อความยาว            | `TEXT`                               | `TEXT`                              | ไม่ต้อง index ทั้ง column โดยตรง |
| วันเวลา               | `TIMESTAMPTZ`                        | `DATETIME` + เก็บ UTC ในแอป         | PG แนะนำ timestamptz เสมอ        |
| Boolean               | `BOOLEAN`                            | `TINYINT(1)` หรือ `BOOLEAN` (alias) | ตั้งชื่อ column `is_...`         |
| JSON กึ่งโครงสร้าง    | `JSONB`                              | `JSON`                              | ใช้เมื่อ schema ยืดหยุ่นจริง ๆ   |

**กฎทอง:** เงินและปริมาณที่ต้องบวกลบแม่นยำ → `NUMERIC`/`DECIMAL` เท่านั้น

### 2.2 Constraints คือชั้น integrity ของฐานข้อมูล

| Constraint    | หน้าที่                                   |
| ------------- | ----------------------------------------- |
| `NOT NULL`    | บังคับมีค่า                               |
| `UNIQUE`      | ไม่ซ้ำ (NULL ใน PG ซ้ำได้หลายแถว — ระวัง) |
| `CHECK`       | เงื่อนไขบนแถว เช่น `price >= 0`           |
| `DEFAULT`     | ค่าเริ่มต้นเมื่อไม่ระบุ                   |
| `PRIMARY KEY` | = UNIQUE + NOT NULL                       |
| `FOREIGN KEY` | อ้างอิงตารางอื่น                          |

**Best Practices การออกแบบ Constraint**

1. ใส่ชื่อ constraint ชัดเจน: `ck_products_price_nonneg`, `uq_customers_email`
2. กฎธุรกิจที่ “ต้องจริงเสมอ” → ใส่ใน DB ไม่พึ่งแอปอย่างเดียว
3. กฎที่เปลี่ยนบ่อย/ซับซ้อนข้ามตาราง → อาจใช้ trigger หรือ application layer + ทดสอบดี
4. `DEFAULT now()` สำหรับ `created_at` — แต่ `updated_at` มัก update ด้วย trigger หรือแอป

---

## 3. Core SQL CRUD

### 3.1 INSERT

```sql
-- ระบุ column ชัดเจนเสมอ (อย่าพึ่งลำดับในตาราง)
INSERT INTO
  customers (email, full_name)
VALUES
  ('ann@example.com', 'Ann');
```

- ใช้ multi-row insert เมื่อ seed ข้อมูล
- ระวัง SQL injection ในแอป — ใช้ parameterized query เสมอ
- PostgreSQL: `RETURNING id` ได้ค่าที่เพิ่ง insert

### 3.2 SELECT

```sql
SELECT
  id,
  email,
  full_name
FROM
  customers
WHERE
  is_active = TRUE
ORDER BY
  created_at DESC
LIMIT
  20;
```

- เลือกเฉพาะ column ที่ต้องการ (เลี่ยง `SELECT *` ใน production query)
- `WHERE` กรองแถว, `ORDER BY` เรียง, `LIMIT`/`OFFSET` แบ่งหน้า (offset ใหญ่ช้า — ระดับ Expert
  จะพูดถึง keyset pagination)

### 3.3 UPDATE / DELETE

```sql
UPDATE customers
SET
  full_name = 'Ann Updated',
  updated_at = CURRENT_TIMESTAMP
WHERE
  id = 1;

DELETE FROM customers
WHERE
  id = 1
  AND is_active = FALSE;
```

**กฎความปลอดภัย**

1. `UPDATE`/`DELETE` **ต้องมี WHERE** เสมอ (ยกเว้นตั้งใจ truncate ทั้งตาราง)
2. ทดสอบด้วย `SELECT` ชุดเงื่อนไขเดียวกันก่อนรัน UPDATE/DELETE
3. Soft delete (`deleted_at`) เหมาะกับข้อมูลที่ต้องเก็บประวัติ; hard delete
   เหมาะกับข้อมูลชั่วคราว/GDPR erase

---

## 4. Normalization Principles

Normalization ลดความซ้ำซ้อนและ anomaly ตอน insert/update/delete

### 4.1 1NF — First Normal Form

- แต่ละ cell มีค่า atomic
- ไม่มี repeating group (เช่น `phone1, phone2` หรือ `tags` เป็น CSV ใน column เดียว)

**ผิด:** `orders.product_ids = '1,5,9'` **ถูก:** ตาราง `order_items` แยกแถวละสินค้า

### 4.2 2NF — Second Normal Form

- อยู่ใน 1NF แล้ว
- ทุก non-key attribute พึ่ง **PK ทั้งก้อน** ไม่ใช่แค่ส่วนหนึ่งของ composite key

ตัวอย่างผิด: ตาราง `(order_id, product_id, product_name, qty)` — `product_name` พึ่งแค่ `product_id`

### 4.3 3NF — Third Normal Form

- อยู่ใน 2NF แล้ว
- ไม่มี transitive dependency: non-key ต้องไม่พึ่ง non-key อื่น

ตัวอย่างผิด: `employees(id, dept_id, dept_name)` — `dept_name` พึ่ง `dept_id` ไม่ใช่ `id` **ถูก:**
แยก `departments(id, name)` และเก็บแค่ `dept_id` ใน employees

### 4.4 เมื่อไหร่ควร Denormalize

| สถานการณ์                            | แนวทาง                              |
| ------------------------------------ | ----------------------------------- |
| Report ที่อ่านบ่อยมาก คำนวณแพง       | materialize / summary table / cache |
| ค่าที่แทบไม่เปลี่ยนและอ่านอย่างเดียว | เก็บสำเนาพร้อมเหตุผลชัดเจน          |
| ยังไม่มีหลักฐานช้า                   | **อย่า** denormalize ล่วงหน้า       |

---

## Best Practices สรุประดับ Beginner

1. ทุกตารางมี PK ชัดเจน
2. FK + ชื่อ constraint อ่านรู้เรื่อง
3. เงินใช้ `NUMERIC`/`DECIMAL`
4. เขียนชื่อตาราง/column เป็น `snake_case`, ตารางเป็นพหูพจน์ (`orders`)
5. เก็บ `created_at` / `updated_at` เป็นมาตรฐาน
6. Normalize ถึง 3NF ก่อนคิดเรื่อง performance
7. ทดสอบ DDL/DML ทั้ง PostgreSQL และ MySQL ถ้าทีมรองรับทั้งสอง

---

## ลำดับการเรียนที่แนะนำ

```
01-relational-model → 02-data-types-constraints → 03-crud-operations → 04-normalization → LAB
```

เมื่อทำ Lab ผ่านและอธิบายได้ว่าทำไมแยกตารางแบบนั้น ให้ไป [`02-intermediate/`](../02-intermediate/)
