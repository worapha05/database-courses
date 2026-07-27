# Lab — Beginner: ตั้งระบบ Version Control ให้ Bookstore DB

## บริบท

คุณเข้าร่วมทีม **Pageflow Bookstore** ที่เคยรัน SQL ด้วยมือบนเครื่องแต่ละคน ตอนนี้ schema
ของทุกคนไม่ตรงกัน และไม่มีใครรู้ว่า production มี column อะไรบ้าง

ภารกิจ: สร้าง migration ชุดแรกสำหรับระบบร้านหนังสือ ด้วย **ทั้ง Prisma และ Knex** (เรียนรู้สองสไตล์)
แล้วพิสูจน์ว่า history table ทำงาน

---

## โจทย์

### ส่วน A — Schema เป้าหมาย

สร้างตารางต่อไปนี้ (PostgreSQL):

**`authors`**

| Column     | Type                       | Constraints             |
| ---------- | -------------------------- | ----------------------- |
| id         | SERIAL / Int autoincrement | PK                      |
| name       | TEXT / VARCHAR             | NOT NULL                |
| country    | TEXT / VARCHAR             | NULL                    |
| created_at | TIMESTAMPTZ                | NOT NULL, default now() |

**`books`**

| Column       | Type                       | Constraints                          |
| ------------ | -------------------------- | ------------------------------------ |
| id           | SERIAL / Int autoincrement | PK                                   |
| title        | TEXT / VARCHAR             | NOT NULL                             |
| isbn         | VARCHAR(13)                | UNIQUE, NOT NULL                     |
| price_cents  | INT                        | NOT NULL, check > 0                  |
| author_id    | INT                        | FK → authors(id), ON DELETE RESTRICT |
| published_at | DATE                       | NULL                                 |
| created_at   | TIMESTAMPTZ                | NOT NULL, default now()              |

### ส่วน B — Prisma Path

1. เขียน `schema.prisma` ให้สะท้อนตารางด้านบน
2. สร้าง migration ชื่อ `init_bookstore`
3. Apply แล้วตรวจ `npx prisma migrate status`
4. Query ตาราง `_prisma_migrations` แล้วอธิบายว่ามีกี่แถว / checksum คืออะไร

### ส่วน C — Knex Path

1. เขียน `knexfile.js` ชี้ไป PostgreSQL
2. สร้าง migration `create_authors_and_books` พร้อม `up` และ `down`
3. รัน `knex migrate:latest` แล้ว `migrate:rollback` หนึ่งครั้ง แล้ว latest อีกครั้ง
4. อธิบายว่า `batch` ใน `knex_migrations` เปลี่ยนอย่างไร

### ส่วน D — คำถามทฤษฎี (ตอบสั้น ๆ)

1. ทำไม `db push` ไม่เหมาะกับทีมที่มี Staging/Prod?
2. ถ้า Prisma มองการเปลี่ยนชื่อ column เป็น drop+add จะเกิดอะไรกับข้อมูล?
3. Declarative กับ Imperative ต่างกันที่ “source of truth” อย่างไร?

---

## เกณฑ์ผ่าน

- มี migration history ทั้งสอง tool
- FK จาก books → authors ทำงาน (insert book ที่ author ไม่มีต้อง fail)
- `down` ของ Knex ลบตารางได้โดยไม่ error เมื่อไม่มีข้อมูลค้างที่ผิดลำดับ
- ตอบคำถามทฤษฎีได้สอดคล้องกับ README

---

## เฉลย — วิธีคิด

### ลำดับการสร้างตาราง

สร้าง `authors` ก่อน `books` เพราะมี FK ใน `down` ของ Knex ต้อง **drop `books` ก่อน `authors`**
(ย้อนลำดับ dependency)

### ทำไมแยก Prisma กับ Knex ใน lab นี้

ไม่ใช่ให้ใช้ทั้งสองใน project จริงพร้อมกัน แต่เพื่อให้สัมผัส:

- Prisma: แก้โมเดล → tool สร้าง SQL
- Knex: คุณเขียนขั้นตอน → tool แค่วิ่งและบันทึกประวัติ

### Checklist แก้ปัญหาที่พบบ่อย

| อาการ                      | สาเหตุที่เป็นไปได้       | แก้                                   |
| -------------------------- | ------------------------ | ------------------------------------- |
| FK fail ตอน migrate        | สร้าง books ก่อน authors | สลับลำดับ                             |
| Prisma shadow DB error     | user ไม่มีสิทธิ์สร้าง DB | ให้สิทธิ์หรือตั้ง `shadowDatabaseUrl` |
| Knex rollback พัง          | drop authors ก่อน books  | แก้ `down`                            |
| migrate status บอก pending | ไฟล์มีแต่ยังไม่ apply    | รัน latest / deploy                   |

---

## โครงสร้างไฟล์เฉลย

```
01-beginner/lab/solution/
├── README.md
├── prisma/
│ ├── schema.prisma
│ ├── package.json
│ └── migrations/
│ └── 20260101000000_init_bookstore/
│  └── migration.sql
└── knex/
 ├── package.json
 ├── knexfile.js
 └── migrations/
 └── 20260101000000_create_authors_and_books.js
```

ดูโค้ดเต็มใน [`lab/solution/`](./lab/solution/)

---

## script ตรวจสอบหลัง apply

```sql
-- ต้องมี authors, books
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
 AND table_name IN ('authors', 'books');

-- FK ต้องมี
SELECT conname, contype
FROM pg_constraint
WHERE conrelid = 'books'::regclass;

-- Prisma history
SELECT migration_name, finished_at, rolled_back_at
FROM _prisma_migrations
ORDER BY started_at;

-- Knex history
SELECT id, name, batch, migration_time
FROM knex_migrations
ORDER BY id;
```

```bash
# ทดสอบ FK (ต้อง error)
psql "$DATABASE_URL" -c \
  "INSERT INTO books (title, isbn, price_cents, author_id)
 VALUES ('Orphan', '9780000000001', 100, 9999);"
```
