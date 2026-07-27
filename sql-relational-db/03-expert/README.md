# Level 3 — Expert: Enterprise Scale, Optimization & Operations

ระดับนี้เตรียมคุณสำหรับงาน production: **analytics ด้วย window functions**,
**concurrency/transactions**, **อ่าน EXPLAIN**, **ออกแบบ index เชิงกลยุทธ์** และ **server-side
logic** (functions / procedures / triggers) ทั้ง PostgreSQL และ MySQL

---

## สิ่งที่คุณจะได้หลังจบระดับนี้

- เขียน ranking, running total, lag/lead analysis ด้วย window functions
- เลือก isolation level และใช้ `SELECT … FOR UPDATE` กัน race condition
- อ่านแผน query และเลือก index (B-Tree, composite, partial, covering, FTS)
- ออกแบบ function/trigger อย่างมีขอบเขต ไม่ยัด business logic เกินจำเป็น

---

## โครงสร้างไฟล์

| folder                                                                             | เนื้อหา                                   |
| ---------------------------------------------------------------------------------- | ----------------------------------------- |
| [`examples/01-window-functions/`](./examples/01-window-functions/)                 | ROW_NUMBER, RANK, LEAD, LAG               |
| [`examples/02-transactions-concurrency/`](./examples/02-transactions-concurrency/) | ACID, isolation, FOR UPDATE               |
| [`examples/03-explain-tuning/`](./examples/03-explain-tuning/)                     | EXPLAIN ANALYZE / EXPLAIN                 |
| [`examples/04-indexing/`](./examples/04-indexing/)                                 | B-Tree, composite, partial, covering, FTS |
| [`examples/05-functions-triggers/`](./examples/05-functions-triggers/)             | PL/pgSQL & MySQL routines                 |
| [`LAB.md`](./LAB.md)                                                               | Lab: ระบบคลังสินค้า + จองสต็อก            |

---

## 1. Advanced Analytics — Window Functions

Window function คำนวณข้ามชุดแถวที่เกี่ยวข้อง โดย**ไม่ยุบแถว**เหมือน `GROUP BY`

```sql
FUNCTION_NAME(...) OVER (
 PARTITION BY ...
 ORDER BY ...
 ROWS BETWEEN ... AND ...
)
```

| function                  | ใช้ทำอะไร                                    |
| ------------------------- | -------------------------------------------- |
| `ROW_NUMBER()`            | ลำดับไม่ซ้ำในพาร์ทิชัน (pagination / dedupe) |
| `RANK()` / `DENSE_RANK()` | อันดับ (RANK มีช่องว่างเมื่อเสมอ)            |
| `LAG()` / `LEAD()`        | ค่าแถวก่อน/หลัง (MoM growth)                 |
| `SUM() OVER()`            | running total                                |
| `NTILE(n)`                | แบ่งกลุ่มเท่า ๆ กัน (quartile)               |

**เมื่อใช้ window แทน GROUP BY:** ต้องการทั้งรายละเอียดแถวและค่าสรุปในผลลัพธ์เดียวกัน

---

## 2. Concurrency & Transactions

### 2.1 ACID

| คุณสมบัติ       | ความหมาย                                            |
| --------------- | --------------------------------------------------- |
| **A**tomicity   | สำเร็จทั้งก้อนหรือไม่ทำเลย                          |
| **C**onsistency | ไม่ทำลาย constraint / invariant                     |
| **I**solation   | transaction คู่ขนานไม่แทรกอย่างผิดกติกา             |
| **D**urability  | commit แล้วไม่หายเมื่อไฟดับ (ตาม config durability) |

### 2.2 Isolation Levels

| Level            | Dirty Read | Non-repeatable | Phantom             | หมายเหตุ                           |
| ---------------- | ---------- | -------------- | ------------------- | ---------------------------------- |
| READ UNCOMMITTED | ได้        | ได้            | ได้                 | เลี่ยงในงานจริง                    |
| READ COMMITTED   | ไม่        | ได้            | ได้                 | default ของ PostgreSQL             |
| REPEATABLE READ  | ไม่        | ไม่            | (ต่างกันตาม engine) | default ของ MySQL InnoDB           |
| SERIALIZABLE     | ไม่        | ไม่            | ไม่                 | แพงสุด / อาจ serialization failure |

PostgreSQL ใช้ MVCC — writer ไม่บล็อก reader ในระดับปกติ MySQL InnoDB ก็มี MVCC แต่รายละเอียด gap
lock ใน REPEATABLE READ สำคัญเมื่อมี range scan

### 2.3 Row-Level Locking

```sql
BEGIN;

SELECT
  stock_qty
FROM
  inventory
WHERE
  product_id = 10 FOR
UPDATE;

-- คำนวณและ update
UPDATE inventory
SET
  stock_qty = stock_qty - 1
WHERE
  product_id = 10;

COMMIT;
```

`FOR UPDATE` ล็อกแถวที่อ่านเพื่อกันคนอื่นจองพร้อมกัน (lost update / oversell)

**Best Practices**

1. Transaction สั้นที่สุดเท่าที่ธุรกิจยอมได้
2. ลำดับการล็อกตารางให้สม่ำเสมอ กัน deadlock
3. อย่าถือ lock แล้วยิง HTTP ภายนอก / sleep นาน
4. ใช้ idempotency key สำหรับงานเงิน/สต็อกเมื่อมี retry

---

## 3. Query Performance Tuning

### 3.1 วัดก่อนเดา

```sql
-- PostgreSQL
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;

-- MySQL
EXPLAIN ANALYZE SELECT ...; -- 8.0.18+
EXPLAIN SELECT ...;
```

สิ่งที่ต้องมอง:

| สัญญาณ                          | ความหมายโดยคร่าว                          |
| ------------------------------- | ----------------------------------------- |
| Seq Scan / ALL บนตารางใหญ่      | อาจขาด index หรือ selectivity ต่ำ         |
| Index Scan / ref / range        | ใช้ index ได้                             |
| Nested Loop + แถวขวาเยอะ        | อาจแพง — ดู join order/filter             |
| Sort หนัก / external sort       | ขาด index ตาม ORDER BY หรือ work_mem เล็ก |
| แถวประมาณ (rows) คลาดเคลื่อนมาก | สถิติล้าสมัย → `ANALYZE`                  |

### 3.2 วงจรจูน

```text
1) นิยาม SLI (เช่น p95 < 100ms)
2) จับ slow query
3) EXPLAIN
4) แก้ (rewrite / index / stats / schema)
5) วัดซ้ำ + ดูผลเขียน (insert/update ช้าลงไหม)
```

---

## 4. Strategic Indexing

| ชนิด      | PostgreSQL                 | MySQL                               | ใช้เมื่อ                                |
| --------- | -------------------------- | ----------------------------------- | --------------------------------------- |
| B-Tree    | default                    | default (InnoDB)                    | equality / range / sort                 |
| Composite | `(status, created_at)`     | เช่นกัน                             | filter ซ้ายสุดของ column ใน index สำคัญ |
| Partial   | `WHERE deleted_at IS NULL` | ไม่มีตรง ๆ                          | soft-delete hot set                     |
| Covering  | `INCLUDE` / index-only     | covering ผ่าน secondary index มี PK | ลด heap/table lookup                    |
| Full-Text | `tsvector` / GIN           | `FULLTEXT` index                    | ค้นหาข้อความ                            |

**กฎทอง**

1. Index มีราคาตอนเขียน — อย่าสร้างเผื่อ
2. เรียง column composite จาก equality → range
3. วัดด้วย EXPLAIN หลังสร้าง
4. ลบ index ที่ไม่มีใครใช้ (monitor `pg_stat_user_indexes` / `sys.schema_unused_indexes`)

---

## 5. Server-Side Logic

### 5.1 เมื่อไหร่ใส่ใน DB

| เหมาะกับ DB                             | เหมาะกับแอป                  |
| --------------------------------------- | ---------------------------- |
| invariant ที่ต้องจริงทุก client         | orchestration / UX flow      |
| derived column อัตโนมัติ (`updated_at`) | integration ภายนอก           |
| audit trail ใกล้ข้อมูล                  | business rule เปลี่ยนบ่อยมาก |

### 5.2 เครื่องมือ

|            | PostgreSQL                     | MySQL                           |
| ---------- | ------------------------------ | ------------------------------- |
| Procedural | PL/pgSQL functions/procedures  | Stored programs                 |
| Trigger    | `BEFORE`/`AFTER` ROW/STATEMENT | เช่นกัน                         |
| Returning  | `RETURNING`                    | `LAST_INSERT_ID()` / select ซ้ำ |

**Best Practices**

1. Trigger ต้องเล็ก อ่านง่าย มีเอกสาร — debug ยาก
2. หลีกเลี่ยง trigger ซ้อน trigger ที่ซ่อน side effect ลึก
3. ตั้งชื่อชัด: `trg_orders_set_updated_at`
4. ทดสอบ concurrent path เสมอเมื่อแตะสต็อก/เงิน

---

## Best Practices สรุประดับ Expert

1. Measure → Explain → Change → Measure
2. Lock เท่าที่จำเป็น ช่วงสั้น
3. Index ตาม workload จริง ไม่ตามความรู้สึก
4. Window function สำหรับ analytics ใน SQL แทนดึงข้อมูลมาวนในแอปเมื่อเป็นไปได้
5. Server-side logic มีขอบเขต — ไม่กลายเป็น monolith ใน DB โดยไม่ตั้งใจ

---

## ลำดับการเรียนที่แนะนำ

```
01-window-functions → 02-transactions-concurrency → 03-explain-tuning
 → 04-indexing → 05-functions-triggers → LAB
```
