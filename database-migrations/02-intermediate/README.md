# Level 2 — Intermediate: Advanced Schema Changes & Data Migrations

> เป้าหมาย: ทำ breaking changes อย่างปลอดภัย, แยก Schema กับ Data migration, และแก้ Migration
> Conflict / History Drift ในทีม Git

---

## 1. Breaking Changes Isolation

### Breaking change คืออะไร?

การเปลี่ยน schema ที่ทำให้ **version แอปเก่าหรือใหม่** ทำงานผิดพลาดได้ทันที เช่น:

- เพิ่ม column `NOT NULL` โดยไม่มี default บนตารางที่มีข้อมูล
- Drop column/ตารางที่แอปยังอ่านอยู่
- เปลี่ยนชนิดข้อมูลแบบเข้ากันไม่ได้ (`TEXT` → `INT`)
- เพิ่ม FK กับข้อมูล orphan ที่มีอยู่แล้ว
- Rename ที่ tool ตีความเป็น drop + add

### หลัก: ทำให้ schema ขยายก่อน แล้วค่อยบังคับกฎ

แทนที่จะทำทุกอย่างใน migration เดียว:

```
❌ ADD COLUMN email TEXT NOT NULL;  -- ล้มบนตารางที่มีแถว
✅ ADD COLUMN email TEXT NULL;
 → backfill ข้อมูล
 → ADD NOT NULL (เมื่อข้อมูลครบ)
```

### เพิ่ม column NOT NULL อย่างปลอดภัย

| ขั้น | Schema                                             | App behavior                      |
| ---- | -------------------------------------------------- | --------------------------------- |
| 1    | เพิ่ม column **nullable** (หรือมี DEFAULT)         | โค้ดใหม่เริ่มเขียนค่า             |
| 2    | Data migration backfill แถวเก่า                    | job / script / SQL UPDATE เป็นชุด |
| 3    | ตรวจว่าไม่มี NULL เหลือ                            | verification query                |
| 4    | `SET NOT NULL` / เอา DEFAULT ชั่วคราวออกถ้าต้องการ | enforce                           |

ตัวอย่าง: [`examples/01-breaking-changes/`](./examples/01-breaking-changes/)

### Drop ตาราง / column อย่างปลอดภัย

1. **หยุดเขียน** ไปยัง column นั้นในโค้ด (deploy แอปก่อน)
2. **หยุดอ่าน** (deploy อีกครั้งถ้าจำเป็น)
3. ค่อย `DROP COLUMN` / `DROP TABLE` ใน migration แยก
4. เก็บ backup หรือ feature flag ช่วง transition

> Drop ใน PR เดียวกับที่ลบโค้ดที่อ้างอิง = race ระหว่าง rolling deploy → error spike

### Foreign Key โดยไม่ล็อกแอป local flow

- สร้าง FK บน Postgres อาจ `SHARE ROW EXCLUSIVE` / ตรวจข้อมูลทั้งตาราง — ตารางใหญ่ควรมีแผน (ระดับ
  Expert: online strategies)
- ก่อนเพิ่ม FK: ล้าง orphan ด้วย data migration
- Local/dev: ใช้ transaction + ข้อมูลเล็กได้; Staging: วัดเวลา lock

```sql
-- หา orphan ก่อนใส่ FK
SELECT
  b.id
FROM
  books b
  LEFT JOIN authors a ON a.id = b.author_id
WHERE
  a.id IS NULL;
```

---

## 2. Data Migration vs Schema Migration

### แยกความรับผิดชอบ

| ประเภท               | เปลี่ยนอะไร            | ตัวอย่าง                                                  |
| -------------------- | ---------------------- | --------------------------------------------------------- |
| **Schema migration** | โครงสร้าง (DDL)        | ADD COLUMN, CREATE INDEX, ADD CONSTRAINT                  |
| **Data migration**   | ค่าในแถว (DML)         | แยก `full_name` → `first_name`/`last_name`, backfill UUID |
| **Seed**             | ข้อมูลเริ่มต้น/อ้างอิง | role list, country codes — ไม่ใช่ production transform    |

ทำไมต้องแยก?

1. **Review ง่าย** — DDL กับ DML มีความเสี่ยงคนละแบบ
2. **Retry** — data script อาจรันเป็น batch / idempotent คนละวิธีกับ DDL
3. **Rollback policy** ต่างกัน — schema อาจ forward-fix; data อาจต้องมี reverse script
4. **Performance** — UPDATE ล้านแถวไม่ควรอยู่ใน transaction เดียวกับ DDL บางชนิด

### รูปแบบการเขียน Data Migration

**แนวทาง A — ไฟล์ migration แยก (Knex / SQL)**

```js
exports.up = async function (knex) {
  // Idempotent-ish: only fill missing values
  await knex('users')
    .whereNull('display_name')
    .update({
      display_name: knex.raw("COALESCE(NULLIF(trim(name), ''), email)"),
    });
};
```

**แนวทาง B — Prisma: schema migration + script Node แยก**

1. `migrate` เพิ่ม column ใหม่
2. รัน `scripts/backfill-display-name.ts` ใน pipeline หลัง migrate ก่อนสลับ traffic
3. migrate ตามมาเพื่อ `NOT NULL`

**แนวทาง C — Expand/Contract ยาวหลาย release** (รายละเอียดใน Expert)

ตัวอย่าง: [`examples/02-data-migrations/`](./examples/02-data-migrations/)

### Best practices สำหรับ Data Migration

- เขียนแบบ **idempotent** ให้มากที่สุด (`WHERE col IS NULL`, `ON CONFLICT`)
- ประมวลผลเป็น **batch** (`LIMIT` / keyset pagination) บนตารางใหญ่
- เก็บ **metrics**: จำนวนแถวที่แปลง, เหลือ null กี่แถว
- มี **verification query** เป็น gate ก่อนขึ้นขั้นถัดไป
- อย่า `SELECT *` มาในแอปแล้ว update ทีละแถวโดยไม่มีเหตุผล — ใช้ SQL set-based เมื่อได้

---

## 3. Team Collaboration & Migration Conflicts

### สาเหตุที่พบบ่อย

```
main: ... → 001_init → 002_add_posts
branch-A: .............. → 003_add_comments (จาก 002)
branch-B: .............. → 003_add_tags  (จาก 002) ← ชื่อ/ลำดับชน
```

หลัง merge:

- folder migration ชนกัน / เรียง timestamp ผิด
- DB ของนักพัฒนาคนหนึ่ง apply ชุดหนึ่ง อีกคนอีกชุด
- Checksum ไม่ตรงเพราะมีคนแก้ไฟล์เก่า
- Prisma บอก _migration history diverged_ / failed migration

### ประเภทปัญหา

| อาการ                                            | ชื่อเรียก             | แนวทาง                                                     |
| ------------------------------------------------ | --------------------- | ---------------------------------------------------------- |
| สอง branch สร้าง migration คนละไฟล์บนฐานเดียวกัน | concurrent migrations | merge ให้มีทั้งสองไฟล์ เรียงตามเวลา แล้วรันที่ยังไม่ apply |
| แก้ SQL ใน migration ที่ apply แล้ว              | checksum drift        | **ห้ามแก้** — สร้าง migration ใหม่แก้ไข                    |
| Local DB กับ Git history คนละเรื่อง              | history drift         | baseline / reset local (ไม่ใช่ prod) หรือ resolve          |
| Migration fail กลางคัน                           | partial apply         | แก้ DB ด้วยมืออย่างระวัง + `migrate resolve`               |

### Git workflow ที่แนะนำ

1. Rebase/merge `main` บ่อยก่อนสร้าง migration ใหม่
2. ตั้งชื่อ migration ให้ unique และสื่อความหมาย
3. ใน PR ต้องรวม **ทั้ง schema และไฟล์ migration**
4. CI รัน `migrate deploy` / `migrate:latest` บน DB สะอาด + DB ที่มีข้อมูล
5. มีคนเดียว (หรือ automation) เป็นคนแก้ conflict ของ migration ordering ใน PR สุดท้าย

### แก้ Prisma diverged history (local)

```bash
# ดูสถานะ
npx prisma migrate status

# ถ้า migration ล้มและยังไม่เสร็จ — หลังแก้ DB แล้ว
npx prisma migrate resolve --applied "20260102120000_add_comments"
# หรือ
npx prisma migrate resolve --rolled-back "20260102120000_add_comments"
```

> `resolve` **ไม่รัน SQL** — แค่แก้ตารางประวัติ ให้ตรงความจริงหลังคุณจัดการ DB แล้ว

### แก้ Knex ที่ลำดับไฟล์ชน

- รวมไฟล์ทั้งสองเข้า repo
- ตรวจว่า timestamp ในชื่อไฟล์เรียงตามที่ต้องการ
- บนเครื่อง dev ที่เพี้ยน: `migrate:rollback` ตาม batch หรือสร้าง DB ใหม่จาก `migrate:latest`
- อย่าลบแถวใน `knex_migrations` โดยไม่เข้าใจว่าไฟล์ยังอยู่ใน repo หรือไม่

ตัวอย่างสถานการณ์และ script แก้:
[`examples/03-conflict-resolution/`](./examples/03-conflict-resolution/)

---

## 4. Declarative vs Imperative ในบริบท Intermediate

| สถานการณ์                  | Prisma (Declarative)           | Knex (Imperative)                   |
| -------------------------- | ------------------------------ | ----------------------------------- |
| เพิ่ม nullable column      | แก้ schema → migrate           | `table.string(...).nullable()`      |
| Backfill ข้อมูล            | script แยก / `$executeRaw`     | ใส่ใน `up` หรือไฟล์ migration ถัดไป |
| Concurrent team migrations | ระวัง shadow DB + merge folder | ระวังชื่อไฟล์ + batch               |
| เปลี่ยนข้อมูลซับซ้อน       | ควบคุมใน script ชัดกว่า        | เขียน JS/SQL ใน `up` คล่อง          |

ปรัชญาเดิมยังคง: **schema ต้องการความถูกต้องของโครงสร้าง; data ต้องการความถูกต้องของธุรกิจ** —
อย่าผสมจน review ไม่ได้

---

## 5. Best Practices (Intermediate)

1. **Expand ก่อน Contract** — เพิ่มของใหม่ก่อน ลบของเก่าทีหลังหลาย release ถ้าจำเป็น
2. **ทุก NOT NULL บนตารางมีข้อมูล = มีแผน backfill**
3. **อย่าแก้ migration ที่ขึ้น shared environment แล้ว**
4. **แยก PR: schema additive → data backfill → constraint tighten → code cleanup** เมื่อ change ใหญ่
5. **มี verification SQL ใน LAB/PR description**
6. **Document downtime expectations** — แม้ local จะเร็ว Staging อาจช้าเพราะข้อมูลจริง
7. **Lock communication** — แจ้งทีมเมื่อกำลังทำ migration ที่อาจล็อกตาราง

### Anti-patterns

- ใส่ `DROP TABLE users;` ใน migration เดียวกับ feature ship ใหญ่โดยไม่มี feature flag
- Backfill 10M แถวใน transaction เดียวบน peak hour
- Force-push แก้ migration กลางบน `main`
- ใช้ `migrate reset` บน staging ที่คนอื่นใช้อยู่

---

## 6. Checklist จบระดับ Intermediate

- [ ] วางแผนเพิ่ม NOT NULL เป็น 3–4 ขั้นได้
- [ ] แยก schema / data migration ในตัวอย่างจริงได้
- [ ] อธิบายและแก้ concurrent migration + checksum drift ได้
- [ ] ใช้ `prisma migrate resolve` หรือเทียบเท่า Knex อย่างเข้าใจ
- [ ] ทำ Lab ใน [`LAB.md`](./LAB.md) จบ

ไปต่อที่ [`../03-expert/`](../03-expert/) เมื่อพร้อม
