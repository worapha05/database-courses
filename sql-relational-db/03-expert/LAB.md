# Lab ระดับ Expert — ระบบคลังสินค้าและจองสต็อก (StockGuard)

## เป้าหมาย

สร้างระบบจองสต็อกที่กัน oversell ด้วย transaction + row lock พร้อมรายงาน analytics (window
functions), index ตาม workload, และ trigger audit

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

**StockGuard** เป็นคลังของร้านอีคอมเมิร์ซที่เคยเจอปัญหา:

- สต็อกเหลือ 1 แต่ขายได้ 2 เพราะสอง request อ่านค่าพร้อมกัน
- รายงาน top SKU ช้าเมื่อข้อมูลโต
- ไม่มีประวัติว่าใครเปลี่ยนสถานะการจองเมื่อไหร่

---

## โจทย์

### ส่วนที่ 1 — Schema

สร้าง:

- `products(id, sku UNIQUE, name)`
- `inventory(product_id PK/FK, stock_qty ≥ 0)`
- `reservations(id, product_id, qty > 0, status, created_at)`
- status: `reserved` | `committed` | `released` | `cancelled`
- `reservation_audit(id, reservation_id, old_status, new_status, changed_at)`

Seed สินค้า ≥ 3 และสต็อกเริ่มต้น

### ส่วนที่ 2 — จองสต็อกแบบ Atomic

เขียน procedure/function หรือ SQL script ชื่อแนว `reserve_stock(product_id, qty)` ที่:

1. เปิด transaction
2. `SELECT … FOR UPDATE` แถว inventory
3. ถ้าสต็อกไม่พอ → rollback / ส่ง error
4. ถ้าพอ → ลดสต็อก + insert reservation `reserved`
5. commit

พิสูจน์ด้วยการจองเกินสต็อกว่าต้อง fail

### ส่วนที่ 3 — Window Analytics

จากตาราง `stock_movements` (สร้างและ seed เอง: product_id, moved_at, qty_delta):

1. running stock ต่อสินค้าด้วย `SUM(qty_delta) OVER (…) `
2. Top movement ต่อวันด้วย `ROW_NUMBER()`

### ส่วนที่ 4 — Index + EXPLAIN

1. สร้าง index ที่รองรับ query: reservations ตาม `product_id + created_at DESC` ที่
   `status = 'reserved'`

- PG: partial index ได้
- MySQL: composite ที่เหมาะสม

2. รัน `EXPLAIN` แล้วแปะผล (หรือบันทึกใน comment) ว่าใช้ index

### ส่วนที่ 5 — Trigger Audit

เมื่อ `reservations.status` เปลี่ยน ให้บันทึกลง `reservation_audit` อัตโนมัติ

---

## เกณฑ์ผ่าน

- [ ] จองพร้อมกันสอง session ไม่ oversell
- [ ] จองเกินสต็อกแล้วข้อมูลไม่เปลี่ยน (atomic)
- [ ] มี window query อย่างน้อย 2 ชุด
- [ ] มี EXPLAIN หลังใส่ index
- [ ] audit ทำงานเมื่อเปลี่ยน status

---

## คำใบ้

```sql
UPDATE inventory
SET stock_qty = stock_qty - :qty
WHERE product_id = :id AND stock_qty >= :qty;
-- ตรวจ rowcount = 1 ก่อนถือว่าสำเร็จ
```

---

## เฉลย

[`lab/solution/postgresql/`](./lab/solution/postgresql/) ·
[`lab/solution/mysql/`](./lab/solution/mysql/)
