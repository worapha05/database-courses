# Lab ระดับ Intermediate — Real-time Commerce Dashboard (ShopPulse)

## เป้าหมาย

สร้างชั้นข้อมูลสำหรับแดชบอร์ดร้านค้าที่ต้อง:

1. สรุปยอดขายด้วย **Aggregation Pipeline**
2. จัดอันดับสินค้าขายดีด้วย **Redis Sorted Set**
3. Cache รายงานด้วย **Cache-Aside**
4. ออกแบบ schema แบบ **embed + reference** ให้ถูกที่

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

บริษัท **ShopPulse** มีหน้า admin dashboard ที่ผู้บริหารเปิดดูทุกเช้า:

- รายได้รวมต่อหมวดหมู่สินค้า (เดือนปัจจุบัน)
- Top 10 สินค้าขายดี (หน่วย)
- Wishlist overlap ระหว่างลูกค้า VIP สองคน (แคมเปญของขวัญ)
- หน้า dashboard ถูกเปิดซ้ำ ๆ — ต้องมี cache แต่ข้อมูลออเดอร์ใหม่ต้องไม่ค้างเกิน 2 นาที

ข้อมูลหลักอยู่ใน MongoDB; Redis ใช้สำหรับ ranking + cache รายงาน

---

## โจทย์

### ส่วนที่ 1 — Schema

สร้าง collections:

1. **`categories`** — `{ name, slug }` (referenced โดย products)
2. **`products`** — `{ sku, name, price, categoryId, active }`
3. **`orders`** — embed `items: [{ sku, name, qty, unitPrice, categoryName }]` + `status`,
   `createdAt`

Seed:

- หมวด ≥ 2, สินค้า ≥ 6, ออเดอร์ที่ `status: "paid"` ≥ 5 (กระจายหลาย SKU)

### ส่วนที่ 2 — Aggregation Report

เขียน pipeline ได้ผลลัพธ์:

```js
[
  { category: "apparel", revenue: ...., units: .... },
  { category: "home", revenue: ...., units: .... }
]
```

เงื่อนไข: นับเฉพาะ `paid` และใช้ `$lookup` จาก `items.sku` → `products` → `categories` **(หรือ)**
ใช้ `categoryName` ที่ embed มาแล้ว — แต่ต้องอธิบายใน README ว่าทำไมเลือกทางนั้น

เพิ่ม pipeline Top SKUs (units DESC, limit 10)

### ส่วนที่ 3 — Redis Leaderboard & Sets

1. หลัง seed/ประมวลผลออเดอร์ — `ZADD shoppulse:top:units <units> <sku>` สำหรับทุก SKU
2. แสดง Top 5 ด้วย `ZREVRANGE WITHSCORES`
3. สร้าง wishlist สองใบด้วย `SADD` แล้วหา `SINTER`

### ส่วนที่ 4 — Cache-Aside สำหรับรายงาน

function `getRevenueReport()`:

1. อ่าน `cache:shoppulse:revenue` (TTL 120 วินาที)
2. miss → รัน aggregation → `SET` cache
3. function `recordOrder(order)` → insert MongoDB → update ZSET → `DEL` cache รายงาน

---

## เกณฑ์ผ่าน

- [ ] แยก category เป็น reference; order items เป็น embed snapshot
- [ ] Aggregation ใช้ `$match` ก่อน `$unwind`
- [ ] Leaderboard มาจาก Sorted Set ไม่ใช่ `SORT` ในแอปบน array ใหญ่
- [ ] รายงานมี Cache-Aside + invalidate ตอนมีออเดอร์ใหม่
- [ ] อธิบาย trade-off ของการใช้ `categoryName` embed ใน order items ได้

---

## คำใบ้

```js
{
  $match: {
    status: 'paid';
  }
} // ต้องมาก่อน unwind
await redis.set(key, JSON.stringify(report), 'EX', 120);
await redis.del(key); // หลัง recordOrder
```

เฉลยเต็มอยู่ที่ [`lab/solution/`](./lab/solution/)
