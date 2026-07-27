# Level 2 — Intermediate: Advanced Querying & Performance Foundations

ระดับนี้โฟกัสการ **ดึงข้อมูลข้ามตาราง**, สรุปด้วย **aggregation**, จัดโครงสร้าง query ด้วย
**subquery/CTE** และควบคุมการเปลี่ยนแปลง schema ด้วย **migrations** แบบมี version

---

## สิ่งที่คุณจะได้หลังจบระดับนี้

- เลือก JOIN type ได้ถูกกับคำถามธุรกิจ
- เขียน `GROUP BY` / `HAVING` กับ aggregate อย่างถูกต้อง
- แยก logic ซับซ้อนด้วย subquery และ CTE (รวม recursive พื้นฐาน)
- จัดไฟล์ migration แบบ versioned และปลอดภัยกับ production

---

## โครงสร้างไฟล์

| folder                                                         | เนื้อหา                                 |
| -------------------------------------------------------------- | --------------------------------------- |
| [`examples/01-joins/`](./examples/01-joins/)                   | INNER / LEFT / RIGHT / FULL / SELF JOIN |
| [`examples/02-aggregations/`](./examples/02-aggregations/)     | GROUP BY, HAVING, SUM/AVG/COUNT         |
| [`examples/03-subqueries-cte/`](./examples/03-subqueries-cte/) | Subquery, Nested, CTE                   |
| [`examples/04-migrations/`](./examples/04-migrations/)         | Versioned schema migrations             |
| [`LAB.md`](./LAB.md)                                           | Lab: platform คอร์สออนไลน์              |

---

## 1. Multi-Table Joins

### 1.1 ภาพรวม

JOIN รวมแถวจากหลายตารางตามเงื่อนไข (มักเป็น FK = PK)

| JOIN               | ผลลัพธ์                   | ใช้เมื่อ                                    |
| ------------------ | ------------------------- | ------------------------------------------- |
| `INNER JOIN`       | แถวที่ match ทั้งสองฝั่ง  | ต้องการเฉพาะความสัมพันธ์ที่มีจริง           |
| `LEFT OUTER JOIN`  | ทุกแถวฝั่งซ้าย + ขวาถ้ามี | หา “ที่ยังไม่มี …” (ลูกค้าที่ยังไม่ออเดอร์) |
| `RIGHT OUTER JOIN` | สลับกับ LEFT              | ใช้น้อย — มักเขียนใหม่เป็น LEFT             |
| `FULL OUTER JOIN`  | ทุกแถวจากทั้งสอง (PG)     | reconcile สองชุดข้อมูล                      |
| `SELF JOIN`        | ตาราง join กับตัวเอง      | hierarchy พนักงาน, กราฟเพื่อน               |

```sql
-- ลูกค้าที่ยังไม่เคยสั่งซื้อ
SELECT
  c.id,
  c.full_name
FROM
  customers c
  LEFT JOIN orders o ON o.customer_id = c.id
WHERE
  o.id IS NULL;
```

### 1.2 FULL OUTER JOIN ใน MySQL

MySQL ไม่มี `FULL OUTER JOIN` โดยตรง — จำลองด้วย:

```sql
SELECT ... FROM a LEFT JOIN b ON ...
UNION
SELECT ... FROM a RIGHT JOIN b ON ... WHERE a.id IS NULL;
```

### 1.3 Best Practices เรื่อง JOIN

1. **เงื่อนไข JOIN อยู่ใน `ON`**, เงื่อนไขกรองผลลัพธ์อยู่ใน `WHERE` (ยกเว้น filter ฝั่งขวาของ LEFT
   JOIN ที่ต้องระวัง — ใส่ใน `ON` ถ้าอยากคงแถวซ้าย)
2. ตั้ง alias สั้นอ่านง่าย (`c`, `o`, `oi`)
3. JOIN ทีละความสัมพันธ์ที่จำเป็น — อย่า join ตารางเกินความต้องการของ SELECT
4. ตรวจ cardinality: JOIN ที่พองแถว (fan-out) ทำให้ `SUM` ผิดได้

---

## 2. Aggregations & Grouping

### 2.1 ลำดับการประมวลผล SQL (สำคัญมาก)

```text
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

ดังนั้น:

- `WHERE` กรอง**ก่อน**รวมกลุ่ม (กรองแถวดิบ)
- `HAVING` กรอง**หลัง**รวมกลุ่ม (กรองผล aggregate)

```sql
SELECT
  customer_id,
  COUNT(*) AS order_count,
  SUM(total) AS revenue
FROM
  orders
WHERE
  status = 'paid' -- ก่อน group
GROUP BY
  customer_id
HAVING
  COUNT(*) >= 3 -- หลัง group
ORDER BY
  revenue DESC;
```

### 2.2 Aggregate ที่ใช้บ่อย

| function              | ความหมาย          | หมายเหตุ                |
| --------------------- | ----------------- | ----------------------- |
| `COUNT(*)`            | นับแถว            | นับแม้ column เป็น NULL |
| `COUNT(col)`          | นับค่า non-NULL   |                         |
| `COUNT(DISTINCT col)` | นับค่าไม่ซ้ำ      | ระวัง performance       |
| `SUM` / `AVG`         | ผลรวม / ค่าเฉลี่ย | `AVG` ข้าม NULL         |
| `MIN` / `MAX`         | ค่าต่ำสุด/สูงสุด  | ใช้กับวันที่ได้         |

### 2.3 กฎ GROUP BY

- column ใน `SELECT` ที่ไม่ใช่ aggregate ต้องอยู่ใน `GROUP BY` (SQL standard)
- MySQL โหมดเก่าอาจผ่อนปรน — **อย่าพึ่ง** ตั้ง `ONLY_FULL_GROUP_BY`

---

## 3. Subqueries & CTEs

### 3.1 ชนิดของ Subquery

| ชนิด            | ตัวอย่างการใช้                             |
| --------------- | ------------------------------------------ |
| Scalar subquery | `WHERE price > (SELECT AVG(price) FROM …)` |
| IN / EXISTS     | สมาชิกที่มีออเดอร์, การมีอยู่ของแถว        |
| Derived table   | subquery ใน `FROM`                         |

`EXISTS` มักดีกว่า `IN` เมื่อเซ็ตใหญ่และต้องการแค่ “มีหรือไม่”

### 3.2 CTE (`WITH`)

CTE ทำให้ query อ่านเป็นขั้นตอน:

```sql
WITH
  paid_orders AS (
    SELECT
      *
    FROM
      orders
    WHERE
      status = 'paid'
  ),
  totals AS (
    SELECT
      customer_id,
      SUM(total_amount) AS revenue
    FROM
      paid_orders
    GROUP BY
      customer_id
  )
SELECT
  c.full_name,
  t.revenue
FROM
  totals t
  JOIN customers c ON c.id = t.customer_id
ORDER BY
  t.revenue DESC;
```

**ข้อดี:** อ่านง่าย, reuse ได้ใน query เดียวกัน, debug เป็นชั้น **ข้อควรรู้:** ในบาง version CTE อาจ
materialize — วัดด้วย EXPLAIN เมื่อช้า

### 3.3 Recursive CTE (พื้นฐาน)

ใช้กับ hierarchy (หมวดหมู่ย่อย, org chart):

```sql
WITH RECURSIVE
  tree AS (
    SELECT
      id,
      parent_id,
      name,
      1 AS depth
    FROM
      categories
    WHERE
      parent_id IS NULL
    UNION ALL
    SELECT
      c.id,
      c.parent_id,
      c.name,
      t.depth + 1
    FROM
      categories c
      JOIN tree t ON c.parent_id = t.id
  )
SELECT
  *
FROM
  tree
ORDER BY
  depth,
  id;
```

---

## 4. Schema Version Control (Migrations)

### 4.1 ทำไมต้อง migration

Schema คือโค้ด — ต้อง:

- ย้อนประวัติได้
- ใช้ซ้ำได้ทุก environment (local / staging / prod)
- review ได้ใน Pull Request
- รันซ้ำอย่างปลอดภัย (ideally idempotent หรือ track ว่าไฟล์ไหนรันแล้ว)

### 4.2 แนวทางที่แนะนำ (Flyway-style)

```text
migrations/
 V001__create_customers.sql
 V002__create_orders.sql
 V003__add_orders_status_index.sql
 V004__add_customers_phone.sql
```

กฎชื่อไฟล์: `V{version}__{description}.sql` (version เพิ่มขึ้นเสมอ)

### 4.3 Best Practices Production

| หลักการ                             | รายละเอียด                                                          |
| ----------------------------------- | ------------------------------------------------------------------- |
| Expand/Contract                     | เพิ่ม column ใหม่ก่อน → deploy แอป → ค่อยลบของเก่า                  |
| เลี่ยง rewrite หนักใน peak          | `ALTER` ใหญ่บนตารางร้อนต้องมีแผน lock/online DDL                    |
| ห้ามแก้ไฟล์ migration ที่ ship แล้ว | สร้าง V00N ใหม่                                                     |
| Backup / forward-only               | rollback จริงมักเป็น migration ชุดใหม่ ไม่ใช่ reverse อัตโนมัติเสมอ |
| แยก data migration                  | ข้อมูลจำนวนมากอย่าผสมกับ DDL ใน transaction ยาวเกินจำเป็น           |

### 4.4 ความต่าง DDL

| งาน                   | PostgreSQL                  | MySQL                           |
| --------------------- | --------------------------- | ------------------------------- |
| เพิ่ม column nullable | เร็วใน version ใหม่หลายกรณี | ระวัง algorithm / lock          |
| Rename column         | `RENAME COLUMN`             | `CHANGE` / `RENAME COLUMN` (8+) |
| Concurrent index      | `CREATE INDEX CONCURRENTLY` | Online DDL ใน 8+ บางกรณี        |

---

## Best Practices สรุประดับ Intermediate

1. เริ่มจากคำถามธุรกิจ → เลือก INNER vs LEFT ให้ถูก
2. ระวัง fan-out ตอน aggregate หลัง JOIN
3. ใช้ CTE เมื่อ logic > 1 ชั้น
4. Migration เป็นไฟล์เล็ก จุดประสงค์เดียว
5. ทดสอบ migration บนสำเนาข้อมูลใกล้ prod

---

## ลำดับการเรียนที่แนะนำ

```
01-joins → 02-aggregations → 03-subqueries-cte → 04-migrations → LAB
```

เมื่อผ่าน Lab ให้ไป [`03-expert/`](../03-expert/)
