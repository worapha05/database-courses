# Database Migrations Bootcamp — Zero to Expert

bootcamp เรียนรู้ **Database Migrations & Schema Evolution** แบบครบวงจร เน้น **Prisma Migrate**,
**Knex.js**, และ **Liquibase** เพื่อจัดการ version ฐานข้อมูลอย่างปลอดภัยใน Production

---

## เป้าหมายของหลักสูตร

เมื่อจบหลักสูตรนี้ คุณจะสามารถ:

- อธิบาย **ทำไมต้องมี Database Version Control** และปัญหาของ SQL script มือ
- แยกแยะ **Declarative Migration** (Prisma) กับ **Imperative Migration** (Knex) ได้อย่างชัดเจน
- ใช้ CLI พื้นฐาน: `prisma migrate`, `knex migrate:*`, และตรวจสถานะประวัติ migration
- ออกแบบ schema change ที่ไม่พังแอป — nullable → backfill → NOT NULL, drop อย่างปลอดภัย
- แยก **Schema Migration** กับ **Data Migration** และเขียน script แปลงข้อมูลระหว่าง deploy
- แก้ **Migration Conflict / History Drift** ในทีม Git หลาย branch
- ใช้ **Expand and Contract Pattern** สำหรับ Zero-Downtime refactor
- ออกแบบ Liquibase changelog, changeset, precondition, rollback หลาย environment
- ผูก migration เข้า CI/CD พร้อม verification gate และกลยุทธ์ online schema change

---

## โครงสร้างหลักสูตร

| Level            | folder                                   | หัวข้อหลัก                                              | เวลาแนะนำ   |
| ---------------- | ---------------------------------------- | ------------------------------------------------------- | ----------- |
| 1 — Beginner     | [`01-beginner/`](./01-beginner/)         | Foundations, Declarative vs Imperative, Prisma/Knex CLI | 1–2 สัปดาห์ |
| 2 — Intermediate | [`02-intermediate/`](./02-intermediate/) | Breaking changes, Data migrations, Team conflicts       | 2–3 สัปดาห์ |
| 3 — Expert       | [`03-expert/`](./03-expert/)             | Expand/Contract, Liquibase, CI/CD, Zero-downtime        | 2–4 สัปดาห์ |

แต่ละระดับประกอบด้วย:

1. **`README.md`** — ทฤษฎีเชิงลึกภาษาไทย (Version Control, Declarative vs Imperative, Best
   Practices)
2. **`examples/`** — ไฟล์ schema / migration / changelog ที่ทดลองได้จริง
3. **`LAB.md`** — โจทย์ Schema Refactoring, Data Migration, Conflict พร้อมเฉลยใน `lab/solution/`

---

## ข้อกำหนดเบื้องต้น

- ความรู้ SQL พื้นฐาน (CREATE/ALTER/DROP, PRIMARY KEY, FOREIGN KEY)
- ความรู้ Git (branch, merge, conflict)
- Node.js 18+ (สำหรับ Prisma / Knex)
- Docker (แนะนำ สำหรับ PostgreSQL local + Liquibase)
- Java 17+ (สำหรับ Liquibase CLI ในระดับ Expert)

```bash
node --version
docker --version
git --version
# Expert:
java -version
```

---

## วิธีใช้ Bootcamp

1. อ่าน `README.md` ของระดับนั้นให้จบ — โฟกัสที่ **ปรัชญา** และ **trade-off**
2. เปิด `examples/` แล้วอ่าน/รัน migration ทีละชุด
3. ทำ Lab ใน `LAB.md` **ด้วยตัวเองก่อน** แล้วค่อยดูเฉลย
4. ไประดับถัดไปเมื่ออธิบายได้ว่าทำไม migration บางแบบ “ปลอดภัยกว่า” อีกแบบ

```bash
cd database/database-migrations

# สตาร์ท PostgreSQL สำหรับทดลอง
docker compose -f .infra/docker-compose.yml up -d
# DATABASE_URL=postgresql://postgres:postgres@localhost:5432/migrations_lab
```

---

## แผนที่เครื่องมือ

| เครื่องมือ         | สไตล์                      | Source of Truth        | เหมาะกับ                     |
| ------------------ | -------------------------- | ---------------------- | ---------------------------- |
| **Prisma Migrate** | Declarative เป็นหลัก       | `schema.prisma`        | TypeScript/Node apps, DX สูง |
| **Knex.js**        | Imperative                 | ไฟล์ `up` / `down`     | ควบคุม SQL/ลำดับละเอียด      |
| **Liquibase**      | Declarative/Imperative ผสม | Changelog XML/YAML/SQL | Enterprise, multi-DB, audit  |

---

## Learning Path แนะนำ

```
Beginner: State + History → Prisma vs Knex → CLI ท้องถิ่น
 ↓
Intermediate: Breaking changes → Data scripts → Git conflicts
 ↓
Expert: Expand/Contract → Liquibase → CI/CD + Online DDL
```

สำเร็จหลักสูตรเมื่อคุณออกแบบ migration plan สำหรับ production ได้โดยไม่ทำให้ระบบ downtime
โดยไม่จำเป็น
