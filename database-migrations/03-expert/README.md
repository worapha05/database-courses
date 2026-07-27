# Level 3 — Expert: Zero-Downtime, Liquibase & Production Operations

> เป้าหมาย: ออกแบบ Expand/Contract สำหรับ Blue-Green, ใช้ Liquibase ระดับองค์กร, และผูก migration
> เข้า CI/CD อย่างปลอดภัยพร้อม verification gates

---

## 1. Zero-Downtime Database Refactoring

### ทำไม “migrate แล้ว deploy” แบบตรง ๆ ถึงพังใน Production

ใน Blue-Green / Rolling deploy จะมีช่วงที่:

- App **version เก่า** และ **version ใหม่** ยิงฐานข้อมูล**ชุดเดียวกัน** พร้อมกัน
- ถ้า schema เปลี่ยนแบบ breaking ในก้าวเดียว → ฝั่งใดฝั่งหนึ่งพังทันที

ดังนั้น schema evolution ต้องเป็น **compatibility window** ไม่ใช่ big-bang

### Expand and Contract Pattern (Parallel Run)

แนวคิด classic จาก evolutionary database design:

```text
1) EXPAND เพิ่มโครงสร้างใหม่โดยไม่ทำลายของเก่า
2) MIGRATE เขียน/อ่านคู่ขนาน หรือ backfill ข้อมูล
3) CONTRACT ลบของเก่าเมื่อไม่มี traffic ใช้แล้ว
```

#### ตัวอย่าง: Rename `users.name` → `users.display_name`

| Release        | Database                                             | Old App                                 | New App                                            |
| -------------- | ---------------------------------------------------- | --------------------------------------- | -------------------------------------------------- |
| R1 Expand      | เพิ่ม `display_name` nullable                        | อ่าน/เขียน `name`                       | —                                                  |
| R2 Dual-write  | trigger หรือแอป dual-write ทั้งสอง column + backfill | เขียนทั้งคู่ (ถ้าทำในแอป) / อ่าน `name` | เขียนทั้งคู่ / อ่าน `display_name` fallback `name` |
| R3 Switch read | ข้อมูลครบ                                            | อ่าน `name`                             | อ่านแค่ `display_name`                             |
| R4 Contract    | drop `name`                                          | ต้องออกจาก production แล้ว              | ใช้ `display_name` อย่างเดียว                      |

#### ตัวอย่าง: แยกตาราง `customers` → `customers` + `customer_profiles`

1. สร้าง `customer_profiles` + FK
2. Backfill / dual-write
3. แอปใหม่อ่านจากตารางใหม่
4. Drop column ที่ย้ายออกจาก `customers`

ตัวอย่างโค้ด: [`examples/01-expand-contract/`](./examples/01-expand-contract/)

### กฎสำหรับ Blue-Green

1. **ทุก DB change ที่ deploy ระหว่าง overlapping versions ต้องเป็น additive หรือ dual-compatible**
2. Contract (drop/rename ทำลายของเก่า) ทำได้หลัง green เสถียรและ blue ถูกปิด
3. Feature flags ช่วยแยก “โค้ดพร้อม” กับ “ตัดของเก่า”
4. มี rollback plan ของ **แอป** แยกจาก rollback ของ **schema** — มัก forward-fix schema แล้ว
   rollback แอป

---

## 2. Advanced Enterprise Tooling — Liquibase

### ทำไมองค์กรใช้ Liquibase

| ความต้องการ                        | Liquibase ช่วยอย่างไร                       |
| ---------------------------------- | ------------------------------------------- |
| Multi-database (Oracle, PG, MSSQL) | Abstract changeset / SQL dialect            |
| Audit / compliance                 | `DATABASECHANGELOG` มี author, id, checksum |
| Preconditions                      | รันเมื่อเงื่อนไขจริงเท่านั้น                |
| Contexts / Labels                  | แยก dev/staging/prod หรือ tenant            |
| Rollback metadata                  | กำหนด rollback ใน changeset                 |
| Lock                               | `DATABASECHANGELOGLOCK` กันคู่ขนาน          |

### Changelog anatomy

```yaml
databaseChangeLog:
 - changeSet:
 id: 001-create-accounts
 author: dba.team
 preConditions:
 - onFail: MARK_RAN
 - not:
  tableExists:
  tableName: accounts
 changes:
 - createTable:
  tableName: accounts
  columns:
  - column:
   name: id
   type: BIGINT
   autoIncrement: true
   constraints:
   primaryKey: true
 rollback:
 - dropTable:
  tableName: accounts
```

**หลัก:**

- `id` + `author` + `filename` = เอกลักษณ์ของ changeset
- อย่าแก้ changeset ที่รันใน shared env แล้ว (checksum จะไม่ตรง) — สร้าง changeset ใหม่
- ใช้ `include` / `includeAll` จัด master changelog ตาม module

### Preconditions ที่ใช้บ่อย

- `tableExists` / `columnExists` / `sqlCheck`
- `onFail: HALT | CONTINUE | MARK_RAN | WARN`
- ใช้ `MARK_RAN` เมื่อ hotfix ด้วยมือไปแล้วและต้องการ sync ประวัติอย่างระมัดระวัง

### Contexts & Environments

```bash
liquibase update --contexts=dev
liquibase update --contexts=staging,prod
```

ตัวอย่าง: [`examples/02-liquibase/`](./examples/02-liquibase/)

### Liquibase เทียบ Prisma / Knex

| มิติ                      | Prisma            | Knex           | Liquibase                 |
| ------------------------- | ----------------- | -------------- | ------------------------- |
| Audience                  | App team TS/Node  | App team Node  | DBA + platform + polyglot |
| Source of truth           | schema.prisma     | up/down files  | changelogs                |
| Multi-DB                  | จำกัดตาม provider | ต่อ client     | แข็งแรง                   |
| Enterprise rollback story | จำกัด             | down functions | rollback blocks + tags    |
| App ORM coupling          | สูง               | กลาง           | ต่ำ                       |

หลายองค์กร: **Liquibase เป็น gate ของ schema ใน pipeline**, ORM ใช้แค่ query — หรือใช้ Prisma/Knex
ในบริการเล็ก และ Liquibase ใน data platform

---

## 3. Production Operations & CI/CD

### ตำแหน่งของ Migration ใน Pipeline

ลำดับที่ปลอดภัยโดยทั่วไป:

```text
build → test → migrate (job แยก) → verify gates → deploy app → smoke → (optional) contract later
```

หลักการ:

1. **Migration รันก่อนสลับ traffic ไปแอปใหม่** (หรือก่อนเริ่ม dual-running ถ้าเป็น expand)
2. ใช้ identity ที่มีสิทธิ์ DDL แยกจาก runtime app user (least privilege)
3. Secrets ผ่าน vault / OIDC — ไม่ commit connection string
4. Migration job **ไม่ parallel** ข้าม environment โดยไม่ตั้งใจ (lock + single replica)

ตัวอย่าง workflow: [`examples/03-cicd-pipelines/`](./examples/03-cicd-pipelines/)

### Post-deployment verification gates

ตรวจอย่างน้อย:

```sql
-- structure
SELECT
  1
FROM
  information_schema.columns
WHERE
  table_name = 'users'
  AND column_name = 'display_name';

-- data completeness
SELECT
  COUNT(*) AS pending
FROM
  users
WHERE
  display_name IS NULL;

-- history
SELECT
  COUNT(*)
FROM
  databasechangelog
WHERE
  id = '010-expand-display-name';
```

Fail gate → **ห้าม** promote traffic / ห้ามเริ่ม contract

### Large table locks & Online Schema Change

ปัญหา: `ALTER TABLE` บนตารางใหญ่อาจล็อกนาน → timeout / latency spike

กลยุทธ์:

| กลยุทธ์                                        | เมื่อไหร่             |
| ---------------------------------------------- | --------------------- |
| Additive nullable columns (PG เร็วกว่าหลายเคส) | Expand ทั่วไป         |
| สร้าง index แบบ `CONCURRENTLY` (Postgres)      | index ใหญ่            |
| pt-online-schema-change / gh-ost (MySQL)       | rewrite ตารางใหญ่     |
| สร้างตารางใหม่ + shadow write + cutover        | เปลี่ยน PK / แตกตาราง |
| ทำนอก peak + monitoring locks                  | ทุก disruptive DDL    |

ตัวอย่างแนวทาง: [`examples/04-online-schema-change/`](./examples/04-online-schema-change/)

### Migration ล้มกลางคัน

1. **หยุด deploy ต่อ** — อย่าซ่อน failure
2. ประเมินว่า DDL/DML ไปถึงไหน (transactional DDL ของ DB? Postgres หลายคำสั่งใน transaction ได้ —
   MySQL ไม่เหมือนกันทุกเคส)
3. เลือก: repair ไปข้างหน้า (forward fix) หรือ rollback ตาม runbook
4. Sync history table (`migrate resolve` / Liquibase `clearCheckSums` เฉพาะเมื่อเข้าใจจริง)
5. Postmortem: ทำไมไม่มี precondition / ไม่มี dry-run บน staging ขนาดใกล้เคียง

### Rollback ในโลก Production

- **Prefer forward fix** สำหรับ schema ที่ apply ไปแล้วบางส่วน
- Liquibase `rollback` ใช้ได้เมื่อมี rollback block และไม่มี data loss ที่ยอมรับไม่ได้
- Blue-Green: rollback แอปไป blue ได้เร็วถ้า schema ยัง compatible (ดังนั้นอย่า contract เร็วเกินไป)
- Backup / PITR เป็นตาข่ายสุดท้าย ไม่ใช่แผนหลักทุกครั้ง

---

## 4. Best Practices (Expert)

1. ออกแบบ migration เป็น **compatibility matrix** ระหว่าง N และ N+1 ของแอป
2. แยก **expand / backfill / switch / contract** เป็น release คนละชุดเมื่อ risk สูง
3. ใช้ Liquibase contexts + labels สำหรับ multi-env อย่างมีวินัย
4. CI ต้องมี **dry-run / updateSQL** และ migrate บน staging ที่ข้อมูลสมจริง
5. Runtime DB user ไม่มีสิทธิ์ `DROP TABLE` ถ้าทำได้
6. Alert บน long-running DDL, lock waits, replication lag
7. เอกสาร runbook: ใคร approve, ใคร execute, เกณฑ์ abort

### Anti-patterns ระดับผู้เชี่ยวชาญ

- Contract ใน release เดียวกับ Expand บนระบบ Blue-Green
- รัน migrate จาก laptop ของคนเดียวตรงเข้า prod
- ปิด lock ของ Liquibase/Knex ด้วยมือแล้วรันซ้ำโดยไม่ตรวจ
- Backfill แบบ full-table update ตอน traffic สูงโดยไม่มี throttle
- เชื่อว่า `down` migration = production rollback strategy เสมอ

---

## 5. เชื่อมทฤษฎี Declarative / Imperative ในระดับ Expert

ในองค์กรจริงมัก **ผสม**:

- **Declarative intent** ใน changelog/schema (“อยากได้ column นี้”)
- **Imperative steps** สำหรับ data backfill, dual-write trigger, cutover scripts
- **Operational declarative gates** ใน CI (“verify query ต้องผ่าน”)

ปรัชญา Version Control ยังเหมือนเดิม: **ประวัติต้อง audit ได้, reproducible, และเข้ากับ deployment
topology**

---

## 6. Checklist จบระดับ Expert

- [ ] วาด Expand/Contract plan สำหรับ rename หรือ table split ได้
- [ ] เขียน Liquibase changelog พร้อม precondition + rollback
- [ ] ออกแบบ GitHub Actions/Jenkins job แยก migrate กับ deploy
- [ ] อธิบายกลยุทธ์ online DDL / lock mitigation ได้
- [ ] ทำ Lab ใน [`LAB.md`](./LAB.md) จบ

ยินดีด้วย — คุณพร้อมออกแบบ schema evolution ใน production อย่างมีวินัย
