# Lab ระดับ Expert — FlashMart Scale (Resilient Catalog + Live Ops Board)

## เป้าหมาย

ยกระบบ FlashMart จาก Beginner ให้ทนต่อ production traffic:

1. ป้องกัน **Avalanche / Stampede / Penetration**
2. สร้าง index และพิสูจน์ด้วย **`explain("executionStats")`**
3. ส่งอีเวนต์ออเดอร์แบบ real-time ด้วย **Redis Streams** (+ Pub/Sub optional)
4. เขียนบันทึกออกแบบ HA สั้น ๆ (Replica Set / Sentinel / Cluster)

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

FlashMart เปิดแคมเปญ Flash Sale เวลา 00:00 คืนแรกของแคมเปญเจออาการดังนี้:

| อาการ                                                 | สาเหตุที่สงสัย                      |
| ----------------------------------------------------- | ----------------------------------- |
| CPU Mongo พุ่งหลัง TTL ชุดใหญ่หมดอายุพร้อมกัน         | Avalanche                           |
| สินค้าชิ้นฮิตทำให้ DB ถูกยิงซ้ำร้อยครั้งในวินาทีเดียว | Stampede                            |
| บอทสุ่ม SKU ที่ไม่มี ทำให้ cache ไร้ประโยชน์          | Penetration                         |
| หน้า admin "ออเดอร์ล่าสุด" ช้าและไม่สด                | ขาด event pipeline + index ไม่เหมาะ |

คุณได้รับมอบหมายให้ harden ชั้นข้อมูลก่อนแคมเปญรอบหน้า

---

## โจทย์

### ส่วนที่ 1 — Resilient `getProduct(sku)`

Implement function เดียวที่รวม:

1. Cache-Aside + **TTL jitter** (เช่น base 60 + random 0–30)
2. **Singleflight lock** (`SET NX`) เมื่อ miss
3. **Negative caching** เมื่อไม่พบสินค้า (`NULL` TTL สั้น)

พิสูจน์ด้วยการยิง `getProduct` พร้อมกันหลายครั้ง (เช่น 20 concurrent) สำหรับ SKU เดียวกัน — DB load
ควรใกล้ 1

### ส่วนที่ 2 — Indexing & Explain

Seed ออเดอร์อย่างน้อย 2,000 รายการ แล้ว:

1. วัด query `{ status: "paid", createdAt: { $gte } }` + sort `createdAt:-1` **ก่อน**มี index
2. สร้าง compound index ที่เหมาะสม (ESR)
3. วัดอีกรอบ — `totalDocsExamined` ควรดีขึ้นชัดเจน
4. สร้าง text index บนฟิลด์หมายเหตุ/ชื่อ และ geo index ถ้ามีพิกัดร้านรับของ

พิมพ์สรุป stage / examined / returned ออกมาให้เห็น

### ส่วนที่ 3 — Live Ops Event Pipeline

เมื่อมีออเดอร์ใหม่ (`insert`):

1. `XADD orders:live * ...` เข้า Redis Stream
2. (optional) `PUBLISH orders:events ...`
3. Worker อ่านด้วย `XREADGROUP` แล้ว update Sorted Set `flashmart:live:top` (ZINCRBY ตาม qty)

จำลอง producer + consumer ใน script เดียวได้

### ส่วนที่ 4 — HA Design Note

ในไฟล์ `HA.md` (หรือ comment ท้าย script) ตอบสั้น ๆ:

- ทำไม MongoDB บน production ต้องเป็น Replica Set
- เมื่อใดเลือก Redis Sentinel กับ Redis Cluster
- HA ต่างจาก Backup อย่างไร

---

## เกณฑ์ผ่าน

- [ ] Concurrent getProduct ไม่ทำให้ DB ถูกยิงเท่าจำนวน request
- [ ] มี negative cache สำหรับ SKU ปลอม
- [ ] อธิบายผล `explain` ก่อน/หลัง index ได้
- [ ] ออเดอร์ใหม่ไหลเข้า Stream และ update leaderboard
- [ ] มีบันทึก HA ที่ตอบ 3 ข้อด้านบน

---

## คำใบ้

```js
await redis.set(lockKey, '1', 'EX', 5, 'NX');
await redis.set(cacheKey, 'NULL', 'EX', 30);
const stats = await cursor.explain('executionStats');
await redis.xadd('orders:live', '*', 'orderNo', orderNo, 'sku', sku, 'qty', String(qty));
```

เฉลยเต็มอยู่ที่ [`lab/solution/`](./lab/solution/)
