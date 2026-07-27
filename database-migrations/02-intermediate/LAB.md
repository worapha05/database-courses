# Lab — Intermediate: Refactor Users + แก้ Migration Conflict

## บริบท

ทีม **Nimbus CRM** มีตาราง `users` แบบเก่า:

```text
users(id, full_name, email, phone, status, created_at)
status: free text เช่น 'active', 'Active', 'disabled', 'banned'
```

ต้องการไปโครงสร้างใหม่โดยไม่ทำลายข้อมูล และระหว่างนั้นมี merge conflict จากสอง feature branch

---

## ส่วน A — Schema Refactoring (Breaking Changes Isolation)

เป้าหมายสุดท้าย:

```text
users(
 id,
 first_name NOT NULL,
 last_name NOT NULL,
 email UNIQUE NOT NULL,
 phone NULL,
 status_id NOT NULL → user_statuses(id),
 created_at
)
user_statuses(id, code UNIQUE, label)
```

### ข้อกำหนด

1. **ห้าม** เพิ่ม `first_name`/`last_name` เป็น NOT NULL ใน migration เดียวบนตารางที่มีข้อมูล
2. ต้องมีตาราง `user_statuses` และ map ค่า status เดิม → id
3. ต้องรองรับค่า status ที่สะกดไม่สม่ำเสมอ (`active`/`Active` → code `active`)
4. column `full_name` และ `status` (text) จะถูกลบได้ **หลัง** แอปไม่ใช้แล้ว — ใน lab ให้ทำเป็น
   migration แยกขั้นท้าย

ส่งมอบเป็นลำดับ migration (Prisma หรือ Knex — เลือกอย่างน้อยหนึ่ง และแนะนำทำทั้งสองถ้ามีเวลา)

---

## ส่วน B — Data Migration

เขียน script/ขั้นตอนที่:

1. แยก `full_name` → `first_name`, `last_name`

- ถ้ามีคำเดียว: `first_name = คำนั้น`, `last_name = '-'`
- ถ้าหลายคำ: คำแรก = first, ที่เหลือ join เป็น last

2. Normalize และ map status → `status_id`
3. Verification:

```sql
SELECT
  COUNT(*) AS missing_names
FROM
  users
WHERE
  first_name IS NULL
  OR last_name IS NULL;

SELECT
  COUNT(*) AS unmapped_status
FROM
  users
WHERE
  status_id IS NULL;
```

ทั้งสองต้องเป็น 0 ก่อนขั้น SET NOT NULL / DROP ของเก่า

---

## ส่วน C — Migration Conflict

จำลอง:

- Branch A สร้าง migration `add_users_avatar_url` (เพิ่ม `avatar_url TEXT NULL`)
- Branch B สร้าง migration `add_users_last_login_at` (เพิ่ม `last_login_at TIMESTAMPTZ NULL`)
- ทั้งคู่แตกจาก commit เดียวกัน แล้ว merge เข้า `main`

### ให้ทำ

1. อธิบายว่าทำไม Prisma/Knex ถึง “conflict” หรือลำดับเพี้ยนได้อย่างไร
2. รวมให้ทั้งสอง change อยู่ในประวัติอย่างถูกต้อง
3. เขียนขั้นตอนแก้สำหรับ:

- นักพัฒนาที่ local เคย apply แค่ฝั่ง A
- DB ที่ยังไม่เคย apply อะไรจากสองอันนี้

---

## เกณฑ์ผ่าน

- รันบน DB ที่มี users ≥ 100 แถวตัวอย่างผ่านทุกขั้น
- ไม่มี truncation ข้อมูลชื่อโดยไม่ตั้งใจ
- Conflict resolve ได้โดยไม่แก้ checksum ของ migration ที่ apply แล้วบน shared DB
- มี verification queries ในเอกสารส่งมอบ

---

## เฉลย — วิธีคิด

### แผนหลายขั้น (Expand → Transform → Constrain → Contract)

```text
M1: CREATE user_statuses + seed codes
M2: ADD first_name, last_name, status_id (nullable)
M3: DATA — split names + map statuses
M4: SET NOT NULL บน first_name, last_name, status_id + FK
M5: (ทางเลือกหลัง deploy แอปใหม่) DROP full_name, DROP status
--+ concurrent: ADD avatar_url, ADD last_login_at เป็น additive แยกไฟล์
```

### ทำไมไม่ทำ NOT NULL ทันที

แถวเก่าไม่มีค่า → `ALTER ... SET NOT NULL` จะ fail หรือต้องมี DEFAULT ที่ไม่ต้องการระยะยาว

### Conflict

Additive migrations สองอัน **รวมกันได้** — ไม่ต้องเลือกอันใดอันหนึ่งทิ้ง ปัญหาคือ ordering/timestamp
และการที่ local history ไม่เหมือนกัน แก้ด้วยการมีทั้งสองไฟล์บน `main` แล้วให้เครื่องที่ขาด migrate
รันเฉพาะที่ยังไม่ apply

อย่า rewrite ไฟล์ที่คนอื่น apply แล้วเพียงเพื่อ “รวมเป็นไฟล์เดียว”

---

## โครงสร้างไฟล์เฉลย

```
02-intermediate/lab/solution/
├── README.md
├── prisma/
│ ├── schema.prisma  # สถานะสุดท้ายหลังครบขั้น
│ └── migrations/
│ ├── ..._01_create_user_statuses/
│ ├── ..._02_add_name_and_status_id/
│ ├── ..._03_backfill_names_and_statuses/ # SQL data
│ ├── ..._04_enforce_not_null_and_fk/
│ ├── ..._05_drop_legacy_columns/
│ ├── ..._add_users_avatar_url/
│ └── ..._add_users_last_login_at/
├── knex/
│ └── migrations/  # equivalent steps
└── scripts/
 ├── seed_sample_users.sql
 ├── verify.sql
 └── resolve_conflict.md
```

รายละเอียดโค้ด: [`lab/solution/`](./lab/solution/)
