# Level 1 — Beginner: Migration Foundations & Local Schemas

> เป้าหมาย: เข้าใจว่าทำไมต้องมี Database Version Control, แยก Declarative กับ Imperative ได้ชัด,
> และใช้ Prisma / Knex CLI บนเครื่องตัวเองได้อย่างมั่นใจ

---

## 1. ทำไมต้องมี Database Migration?

### ปัญหาของ Manual SQL Scripts

ในทีมที่ยังไม่มี migration tool มักเจอสถานการณ์แบบนี้:

1. Dev A รัน `ALTER TABLE users ADD COLUMN phone VARCHAR(20);` บนเครื่องตัวเอง
2. Dev B ไม่รู้ — แอปพังเพราะโค้ดอ้าง `phone` แต่ DB ของ B ยังไม่มี column
3. Staging ได้ script คนละชุดกับ Production
4. ไม่มีใครตอบได้ว่า “ตอนนี้ฐานข้อมูล version อะไร” หรือ “ใครเปลี่ยนอะไรเมื่อไหร่”
5. Rollback = เดา SQL ย้อนกลับด้วยมือ เสี่ยงพลาดและเสียข้อมูล

**สรุปปัญหาหลัก**

| ปัญหา                  | ผลกระทบ                         |
| ---------------------- | ------------------------------- |
| ไม่มีประวัติ (history) | ไล่บั๊ก schema ไม่ได้           |
| ไม่ reproducible       | Dev / Staging / Prod เพี้ยนกัน  |
| ไม่มีลำดับ (ordering)  | script รันผิดลำดับ = พัง        |
| ไม่มี rollback มาตรฐาน | Hotfix กลางดึกเสี่ยงสูง         |
| Knowledge silo         | ความรู้ schema อยู่ในหัวคนเดียว |

### Database State คืออะไร?

คิดว่าฐานข้อมูลเป็น **state machine**:

```
empty DB --[migration 001]--> schema v1
  --[migration 002]--> schema v2
  --[migration 003]--> schema v3
```

- **Desired state** = โครงสร้างที่แอปต้องการตอนนี้
- **Actual state** = โครงสร้างจริงในฐานข้อมูล
- **Migration** = ขั้นตอนที่พา Actual → Desired อย่างมีลำดับและตรวจสอบได้

Migration tool เก็บ “เราเคยรันอะไรไปแล้ว” ใน **history tracking table** เพื่อไม่ให้รันซ้ำ
และรู้ว่ายังขาดอะไร

### History Tracking Tables

| Tool      | ตารางประวัติ                                    | เก็บอะไร                                                |
| --------- | ----------------------------------------------- | ------------------------------------------------------- |
| Prisma    | `_prisma_migrations`                            | migration name, checksum, applied_at, finished_at, logs |
| Knex      | `knex_migrations` (+ `knex_migrations_lock`)    | name, batch, migration_time                             |
| Liquibase | `DATABASECHANGELOG` (+ `DATABASECHANGELOGLOCK`) | id, author, filename, md5sum, dateexecuted              |

**หลักสำคัญ:** อย่าแก้แถวในตารางเหล่านี้ด้วยมือโดยไม่เข้าใจผลกระทบ — checksum/history drift
มักเกิดจากตรงนี้

ดูตัวอย่างโครงสร้างตารางได้ที่ [`examples/03-history-tables/`](./examples/03-history-tables/)

---

## 2. ปรัชญา Database Version Control

Database Version Control ยืมแนวคิดจาก Git แต่มีข้อจำกัดพิเศษ:

1. **Schema คือโค้ด** — ต้อง review ใน PR เหมือน application code
2. **ลำดับสำคัญ** — migration มักเป็น append-only timeline
3. **ข้อมูลมีชีวิต** — เปลี่ยน schema ต้องคิดถึงแถวที่มีอยู่แล้ว
4. **Forward เป็นหลัก** — production มัก prefer migrate ต่อไปข้างหน้า มากกว่า rollback ใหญ่
5. **Idempotent ที่ระดับ tool** — tool รู้ว่า applied แล้ว ไม่รันซ้ำ (แต่ SQL ใน migration
   เองควรออกแบบให้ปลอดภัย)

### กฎทองสำหรับมือใหม่

- **อย่าแก้ migration ที่ merge แล้วและถูก apply บน shared DB** — สร้าง migration ใหม่แทน
- **หนึ่ง PR หนึ่งชุด schema change ที่เกี่ยวข้องกัน** — อย่ายัดทุกอย่างในไฟล์เดียว
- **ทดสอบบน DB ที่มีข้อมูลตัวอย่าง** ไม่ใช่แค่ empty database
- **อ่าน SQL ที่ tool generate** ก่อน apply จริง

---

## 3. Declarative vs Imperative Migration

นี่คือหัวใจของระดับ Beginner — เข้าใจความต่างแล้วเลือก tool ได้ถูก

### Declarative (ประกาศ “อยากได้โครงสร้างแบบนี้”)

**Source of truth = โมเดลปัจจุบัน** เช่น `schema.prisma`

คุณเขียน:

```prisma
model User {
 id Int @id @default(autoincrement())
 email String @unique
 name String?
}
```

แล้ว tool **คำนวณ diff** ระหว่าง schema กับฐานข้อมูลจริง แล้วสร้าง SQL migration ให้

| ข้อดี                               | ข้อเสีย                                                    |
| ----------------------------------- | ---------------------------------------------------------- |
| DX สูง อ่านง่าย เป็นเอกสารโครงสร้าง | ควบคุม SQL ละเอียดยากกว่า                                  |
| ลด human error ตอนเขียน DDL         | Diff บางเคสไม่ตรง intent (เช่น rename ถูกมองเป็น drop+add) |
| Type-safe client มาคู่กัน (Prisma)  | ต้องเข้าใจว่า tool “คิดอะไร”                               |

**Prisma = Declarative เป็นหลัก** — คุณแก้ `schema.prisma` แล้ว `prisma migrate dev` สร้างไฟล์ SQL

### Imperative (บอกทีละขั้น “ทำอะไร”)

**Source of truth = ลำดับคำสั่ง** ใน function `up` / `down`

คุณเขียน:

```js
exports.up = async function (knex) {
  await knex.schema.createTable('users', t => {
    t.increments('id').primary();
    t.string('email').unique().notNullable();
    t.string('name');
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('users');
};
```

| ข้อดี                           | ข้อเสีย                                |
| ------------------------------- | -------------------------------------- |
| ควบคุมลำดับและ SQL ได้เต็มที่   | ต้องดูแล `down` เอง (ถ้าใช้)           |
| เหมาะกับ data transform ซับซ้อน | โครงสร้างปัจจุบันกระจายในหลายไฟล์      |
| ชัดเจนว่า “ขั้นตอนนี้ทำอะไร”    | เขียนเยอะกว่า ผิดพลาดง่ายถ้าไม่ review |

**Knex = Imperative** — คุณเขียนขั้นตอนเองทุกครั้ง

### ตารางเปรียบเทียบสั้น ๆ

| มิติ            | Prisma (Declarative)                     | Knex (Imperative)             |
| --------------- | ---------------------------------------- | ----------------------------- |
| Source of truth | `schema.prisma`                          | ไฟล์ migration `up/down`      |
| สร้าง DDL       | Diff อัตโนมัติ                           | เขียนเอง                      |
| Rename column   | ต้องระวัง (อาจ drop+create)              | เขียน `renameColumn` ชัด ๆ    |
| Data migration  | แยก script / raw SQL                     | ใส่ใน `up` ได้ตรง ๆ           |
| Rollback        | `migrate resolve` / สร้าง migration ใหม่ | `migrate:rollback` ใช้ `down` |
| Learning curve  | เริ่มเร็ว                                | ควบคุมลึก ต้องมีวินัย         |

> **แนวคิดที่ถูกต้อง:** ไม่มีอันไหน “ดีกว่า” ทุกกรณี — Declarative ดีเมื่อ schema เป็นศูนย์กลางแอป
> TypeScript; Imperative ดีเมื่อต้องการควบคุมขั้นตอนและ data move ละเอียด

ตัวอย่างโค้ด:

- [`examples/01-prisma-basics/`](./examples/01-prisma-basics/)
- [`examples/02-knex-basics/`](./examples/02-knex-basics/)

---

## 4. Basic CLI Workflows

### Prisma Migrate (local)

```bash
# ติดตั้งใน project Node
npm install prisma @prisma/client
npx prisma init

# แก้ schema.prisma แล้วสร้าง + apply migration บน Dev DB
npx prisma migrate dev --name init_users

# ดูสถานะ
npx prisma migrate status

# ดู SQL ที่จะรัน (deploy โหมด CI/Prod — ไม่สร้างไฟล์ใหม่)
npx prisma migrate deploy

# สร้าง client
npx prisma generate
```

**ความต่างสำคัญ**

| คำสั่ง           | ใช้เมื่อ             | พฤติกรรม                                                    |
| ---------------- | -------------------- | ----------------------------------------------------------- |
| `migrate dev`    | local development    | สร้าง migration จาก diff, apply, regenerate client          |
| `migrate deploy` | CI / Staging / Prod  | รัน migration ที่มีอยู่แล้วเท่านั้น ไม่สร้างใหม่            |
| `migrate status` | ทุกที่               | บอกว่า applied / pending อะไรบ้าง                           |
| `db push`        | prototyping เท่านั้น | ดัน schema โดยไม่สร้าง history มาตรฐาน — **อย่าใช้ใน prod** |

### Knex Migrate (local)

```bash
npm install knex pg
npx knex init

# สร้างไฟล์ migration ว่าง
npx knex migrate:make create_users

# รันทุก migration ที่ยังไม่ apply
npx knex migrate:latest

# ดูสถานะ
npx knex migrate:list
# หรือ
npx knex migrate:status

# ย้อน batch ล่าสุด
npx knex migrate:rollback

# ย้อนทั้งหมด
npx knex migrate:rollback --all
```

### Workflow ที่แนะนำสำหรับมือใหม่

```
1. สร้าง branch
2. แก้ schema (Prisma) หรือสร้าง migration file (Knex)
3. รันบน local DB ที่มี seed ข้อมูลตัวอย่าง
4. ตรวจ SQL / ผลลัพธ์ด้วยมือ
5. Commit ทั้งไฟล์ migration + schema
6. PR review → merge → CI รัน migrate deploy / migrate:latest
```

---

## 5. Best Practices (Beginner)

1. **ใช้ PostgreSQL (หรือ DB เดียวกับ prod) ใน local** — อย่าพัฒนาบน SQLite แล้วขึ้น Postgres
   โดยไม่ทดสอบ
2. **ตั้งชื่อ migration ให้สื่อความหมาย** — `add_users_email_unique` ดีกว่า `update1`
3. **อย่ารวม seed ข้อมูล demo กับ schema migration ในไฟล์เดียว** ถ้ายังไม่จำเป็น (ระดับ Intermediate
   จะแยกชัด)
4. **Commit migration files เข้า Git เสมอ** — DB ไม่ใช่ source of truth ของประวัติ
5. **อ่าน checksum / failed migration** — ถ้า Prisma migration fail กลางคัน ต้อง `migrate resolve`
   อย่างเข้าใจก่อนไปต่อ
6. **เขียน `down` ใน Knex ให้สมมาตรกับ `up`** แม้ production จะไม่ rollback บ่อย — เพื่อ local/test
7. **อย่าใช้ `migrate reset` บน shared database** — ลบข้อมูลทั้งหมด

### Anti-patterns ที่พบบ่อย

- แก้ไฟล์ migration เก่าที่คนอื่น apply แล้ว → checksum mismatch
- ใช้ `db push` ใน staging แล้วค่อยมาสร้าง migration ทีหลัง → history เพี้ยน
- Drop column ใน migration เดียวกับที่แอปยังอ่าน column นั้นอยู่ → downtime / error spike
- ใส่ `DELETE FROM ...` ใน schema migration โดยไม่ backup / ไม่มี where ที่ชัด

---

## 6. Checklist จบระดับ Beginner

- [ ] อธิบายปัญหา manual SQL และบทบาท history table ได้
- [ ] เปรียบเทียบ Declarative vs Imperative ด้วยตัวอย่างตัวเองได้
- [ ] รัน `prisma migrate dev` และ `knex migrate:latest` สำเร็จ
- [ ] อ่าน `_prisma_migrations` / `knex_migrations` เข้าใจความหมายแต่ละ column
- [ ] ทำ Lab ใน [`LAB.md`](./LAB.md) จบ

ไปต่อที่ [`../02-intermediate/`](../02-intermediate/) เมื่อพร้อม
