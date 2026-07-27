# Relational Database Bootcamp — Zero to Expert

bootcamp เรียนรู้ **Relational Databases** แบบครบวงจร เน้น **PostgreSQL และ MySQL**
จากพื้นฐานโมเดลเชิงสัมพันธ์ → Query ขั้นสูง / Migrations → Performance Tuning / Transactions /
Server-Side Logic

---

## เป้าหมายของหลักสูตร

เมื่อจบหลักสูตรนี้ คุณจะสามารถ:

- อธิบาย **Relational Model** (Table / Row / Column / PK / FK) และออกแบบ schema ตาม Normalization
  (1NF–3NF)
- เลือก **Data Types & Constraints** ที่ถูกต้อง และเขียน **CRUD SQL** ที่ปลอดภัยและชัดเจน
- ใช้ **JOIN, Aggregation, Subquery, CTE** แก้โจทย์รายงานและธุรกิจจริง
- จัดการ **Schema Migrations** เป็น version เหมือนโค้ดแอป
- วิเคราะห์และปรับประสิทธิภาพด้วย **EXPLAIN / Indexing / Window Functions**
- ออกแบบ **Transactions, Isolation Levels, Locking** และ **Functions / Triggers** ระดับ production

---

## โครงสร้างหลักสูตร

| Level            | folder                                   | หัวข้อหลัก                                                             | เวลาแนะนำ   |
| ---------------- | ---------------------------------------- | ---------------------------------------------------------------------- | ----------- |
| 1 — Beginner     | [`01-beginner/`](./01-beginner/)         | Relational Model, Types/Constraints, CRUD, Normalization               | 1–2 สัปดาห์ |
| 2 — Intermediate | [`02-intermediate/`](./02-intermediate/) | Joins, Aggregations, Subqueries/CTE, Migrations                        | 2–3 สัปดาห์ |
| 3 — Expert       | [`03-expert/`](./03-expert/)             | Window Functions, Transactions, EXPLAIN, Indexing, Procedures/Triggers | 2–4 สัปดาห์ |

แต่ละระดับประกอบด้วย:

1. **`README.md`** — ทฤษฎีเชิงลึกภาษาไทย เน้นสถาปัตยกรรมและ Best Practices การออกแบบ
2. **`examples/`** — ชุด SQL (DDL/DML) แยก PostgreSQL / MySQL ที่รันได้จริง
3. **`LAB.md`** — โจทย์กรณีศึกษาจริงพร้อมเฉลยเต็มใน `lab/solution/`

---

## ข้อกำหนดเบื้องต้น

- ความเข้าใจพื้นฐานเรื่องตารางและข้อมูล (ไม่จำเป็นต้องเคยเขียน SQL)
- ติดตั้ง [Docker](https://www.docker.com/) (แนะนำ) หรือติดตั้ง PostgreSQL 16+ / MySQL 8+ โดยตรง
- Client: `psql`, `mysql` CLI, หรือ [DBeaver](https://dbeaver.io/) /
  [pgAdmin](https://www.pgadmin.org/)

```bash
docker --version
psql --version  # ถ้าติดตั้ง PostgreSQL client
mysql --version # ถ้าติดตั้ง MySQL client
```

---

## วิธีใช้ Bootcamp

1. เปิด DBMS ด้วย Docker Compose จาก root ของ bootcamp
2. อ่าน `README.md` ของระดับนั้นให้จบ — โฟกัสที่ **ทำไมออกแบบ schema แบบนี้**
3. รัน SQL ใน `examples/` ตามลำดับ (อ่าน comment ในไฟล์ด้วย)
4. ทำ Lab ใน `LAB.md` **ด้วยตัวเองก่อน** แล้วค่อยดูเฉลย
5. ไประดับถัดไปเมื่ออธิบาย trade-off ของการออกแบบได้

```bash
# สตาร์ท PostgreSQL + MySQL
cd database/sql-relational-db
docker compose -f .infra/docker-compose.yml up -d

# PostgreSQL — ตัวอย่าง Beginner
psql "postgresql://bootcamp:bootcamp@localhost:5432/bootcamp" \
  -f 01-beginner/examples/01-relational-model/postgresql/01_schema.sql

# MySQL — ตัวอย่าง Beginner
mysql -h 127.0.0.1 -P 3306 -u bootcamp -pbootcamp bootcamp \
  < 01-beginner/examples/01-relational-model/mysql/01_schema.sql
```

| บริการ        | Host Port | User / Password         | Database   |
| ------------- | --------- | ----------------------- | ---------- |
| PostgreSQL 16 | `5432`    | `bootcamp` / `bootcamp` | `bootcamp` |
| MySQL 8       | `3306`    | `bootcamp` / `bootcamp` | `bootcamp` |

---

## Learning Path ที่แนะนำ

```
Beginner: Model + Types/Constraints + CRUD + Normalization
 ↓
Intermediate: Joins + Aggregations + CTE + Migrations
 ↓
Expert: Window Functions + ACID/Locking + EXPLAIN + Indexes + Procedures
 ↓
ออกแบบ schema จริงของ project คุณเอง (PostgreSQL หรือ MySQL)
```

---

## หลักการสำคัญที่หลักสูตรย้ำตลอด

| หลักการ                    | ความหมายใน RDBMS                                                            |
| -------------------------- | --------------------------------------------------------------------------- |
| Data integrity มาก่อน      | PK/FK/CHECK/UNIQUE คือเกราะป้องกันข้อมูลเสีย — อย่าพึ่ง validation แค่ในแอป |
| Normalize ก่อน denormalize | เริ่มจาก 3NF แล้ว denormalize เมื่อมีหลักฐาน performance จริง               |
| Query ต้องอ่านได้          | CTE ดีกว่า subquery ซ้อนลึกเมื่อ logic ซับซ้อน                              |
| Measure ก่อน tune          | ใช้ EXPLAIN ก่อนสร้าง index เพิ่ม                                           |
| Transaction = หน่วยธุรกิจ  | หนึ่งธุรกรรมธุรกิจ = หนึ่ง transaction (หรือออกแบบชัดเจนว่าทำไมไม่ใช่)      |
| Dialect awareness          | PostgreSQL และ MySQL ใกล้กันแต่ไม่เหมือน — ทดสอบทั้งสองเมื่อเป็นไปได้       |

---

## Tech Stack มาตรฐานของหลักสูตร

| ชั้น             | เทคโนโลยี                                             |
| ---------------- | ----------------------------------------------------- |
| RDBMS            | PostgreSQL 16+, MySQL 8.0+                            |
| Client           | psql / mysql CLI / DBeaver                            |
| Runtime (แนะนำ)  | Docker Compose                                        |
| Migration แนวคิด | Versioned SQL (`V001__...sql`) สไตล์ Flyway/Liquibase |

---

## ความต่าง PostgreSQL vs MySQL (สรุปสั้น)

| หัวข้อ          | PostgreSQL       | MySQL 8                                   |
| --------------- | ---------------- | ----------------------------------------- |
| Full Outer Join | รองรับ           | ต้องจำลองด้วย UNION                       |
| Partial Index   | รองรับ (`WHERE`) | ไม่มีตรง ๆ                                |
| CTE recursive   | แข็งแรง          | รองรับตั้งแต่ 8.0                         |
| Stored language | PL/pgSQL         | Stored Programs (SQL)                     |
| Boolean type    | `BOOLEAN` จริง   | มักใช้ `TINYINT(1)`                       |
| `RETURNING`     | มี               | ไม่มี (ใช้ session vars / last_insert_id) |

หลักสูตรนี้ให้ไฟล์แยก `postgresql/` และ `mysql/` ในทุกตัวอย่างที่ dialect ต่างกัน
