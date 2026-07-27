# Level 2 — Intermediate: Advanced Querying & Caching Strategies

เป้าหมายระดับนี้: ใช้ MongoDB / Redis แก้โจทย์ธุรกิจจริง — รายงาน, leaderboard, และชั้น cache
ที่ออกแบบได้ ไม่ใช่แค่ CRUD — เพื่อเลือก **pipeline / data structure / caching pattern / embed vs
ref** อย่างมีเหตุผล

---

## สารบัญ

1. [MongoDB Aggregation Framework](#1-mongodb-aggregation-framework)
2. [Redis Lists, Sets, Sorted Sets](#2-redis-lists-sets-sorted-sets)
3. [Caching Patterns — Cache-Aside & Write-Through](#3-caching-patterns--cache-aside--write-through)
4. [Cache Eviction Policies](#4-cache-eviction-policies)
5. [Data Modeling — Embedded vs References](#5-data-modeling--embedded-vs-references)
6. [Best Practices สรุป](#6-best-practices-สรุป)

---

## 1. MongoDB Aggregation Framework

Aggregation คือ **pipeline** ของ stages ที่แปลงเอกสารทีละขั้น คล้ายสายพานโรงงาน

```
$match → $unwind → $group → $project → $sort → $limit
```

### Stages สำคัญ

| Stage              | หน้าที่                  | เทียบ SQL โดยคร่าว   |
| ------------------ | ------------------------ | -------------------- |
| `$match`           | กรองเอกสาร               | `WHERE`              |
| `$project`         | เลือก/คำนวณฟิลด์         | `SELECT`             |
| `$group`           | รวมกลุ่ม + accumulator   | `GROUP BY`           |
| `$unwind`          | แตก array เป็นหลายเอกสาร | —                    |
| `$lookup`          | join ข้าม collection     | `LEFT JOIN`          |
| `$sort` / `$limit` | เรียงและจำกัด            | `ORDER BY` / `LIMIT` |

### ตัวอย่างรายงานยอดขายตามหมวด

```js
db.orders.aggregate([
  { $match: { status: 'paid', createdAt: { $gte: startOfMonth } } },
  { $unwind: '$items' },
  {
    $lookup: {
      from: 'products',
      localField: 'items.sku',
      foreignField: 'sku',
      as: 'product',
    },
  },
  { $unwind: '$product' },
  {
    $group: {
      _id: '$product.category',
      revenue: { $sum: { $multiply: ['$items.qty', '$items.unitPrice'] } },
      units: { $sum: '$items.qty' },
    },
  },
  { $project: { _id: 0, category: '$_id', revenue: 1, units: 1 } },
  { $sort: { revenue: -1 } },
]);
```

### แนวคิดออกแบบ Aggregation

1. **`$match` ให้อยู่ต้น pipeline** เพื่อลดปริมาณเอกสารเร็วที่สุด (และใช้ index ได้)
2. **อย่า `$lookup` ใหญ่โดยไม่จำเป็น** — ถ้าอ่านด้วยกันเสมอ อาจ embed ตั้งแต่ต้นดีกว่า
3. **Accumulator ที่ใช้บ่อย:** `$sum`, `$avg`, `$min`, `$max`, `$push`, `$addToSet`
4. **ระวัง `$unwind` บน array ใหญ่** — คูณจำนวนเอกสาร

ดูโค้ด: [`examples/01-mongodb-aggregation/`](./examples/01-mongodb-aggregation/)

---

## 2. Redis Lists, Sets, Sorted Sets

### Lists — คิว / feed ล่าสุด

```redis
LPUSH events:orders '{"orderNo":"ORD-1"}' # ใส่หัว
RPOP events:orders    # ดึงท้าย (queue FIFO ถ้า LPUSH+RPOP)
LRANGE feed:user:42 0 19   # อ่าน 20 รายการล่าสุด
LTRIM feed:user:42 0 99   # เก็บแค่ 100 อันล่าสุด
```

ใช้เมื่อ: activity feed, simple job queue, recent N items

### Sets — สมาชิกไม่ซ้ำ / ความสัมพันธ์

```redis
SADD product:TSHIRT-01:likers user:1 user:2
SISMEMBER product:TSHIRT-01:likers user:1
SMEMBERS product:TSHIRT-01:likers
SINTER user:1:wishlist user:2:wishlist # intersection
```

ใช้เมื่อ: tags, unique visitors ต่อวัน, wishlist, ACL ชุดเล็ก

### Sorted Sets — ranking / leaderboard

```redis
ZADD leaderboard:weekly 1500 player:mira 1200 player:bob
ZINCRBY leaderboard:weekly 50 player:mira
ZREVRANGE leaderboard:weekly 0 9 WITHSCORES # top 10
ZRANK leaderboard:weekly player:bob  # อันดับจากต่ำ→สูง
ZREVRANK leaderboard:weekly player:mira # อันดับจากสูง→ต่ำ
```

ใช้เมื่อ: leaderboard, priority queue, time-series score, rate-limit sliding window

ดูโค้ด: [`examples/02-redis-advanced-structures/`](./examples/02-redis-advanced-structures/)

---

## 3. Caching Patterns — Cache-Aside & Write-Through

### Cache-Aside (Lazy Loading) — ใช้บ่อยที่สุด

```
App → อ่าน Redis
 ├─ HIT → ใช้ค่าจาก cache
 └─ MISS → อ่าน MongoDB → เขียน Redis (พร้อม TTL) → คืนค่า
```

**ข้อดี:** ง่าย, cache เฉพาะของที่ถูกอ่านจริง **ข้อเสีย:** miss ครั้งแรกช้า; ต้องจัดการ invalidate
เองตอนเขียน

```js
async function getProduct(sku) {
  const key = `cache:product:${sku}`;
  const hit = await redis.get(key);
  if (hit) return JSON.parse(hit);

  const doc = await products.findOne({ sku });
  if (doc) await redis.set(key, JSON.stringify(doc), 'EX', 60);
  return doc;
}

async function updateStock(sku, delta) {
  await products.updateOne({ sku }, { $inc: { stock: delta } });
  await redis.del(`cache:product:${sku}`); // invalidate
}
```

### Write-Through

```
App → เขียน Redis และ MongoDB พร้อมกัน (หรือผ่าน cache layer ที่ sync)
```

**ข้อดี:** อ่านแล้วเจอของใหม่เสมอใน cache **ข้อเสีย:** ทุก write ช้าลง; เขียนของที่ไม่ถูกอ่านก็ขึ้น
cache

### เปรียบเทียบสั้น ๆ

| Pattern       | อ่าน          | เขียน                             | เหมาะกับ                             |
| ------------- | ------------- | --------------------------------- | ------------------------------------ |
| Cache-Aside   | miss แล้วโหลด | invalidate หรือ update cache      | อ่านเยอะ เขียนน้อย–ปานกลาง           |
| Write-Through | ตรง cache     | เขียนคู่ DB                       | ต้องการ consistency อ่านหลังเขียนสูง |
| Write-Behind  | ตรง cache     | เขียน cache ก่อน แล้ว async ลง DB | throughput สูงมาก (ซับซ้อนกู้ข้อมูล) |

> ระดับ Intermediate แนะนำเชี่ยวชาญ **Cache-Aside + TTL + explicit invalidation** ให้ชัวร์ก่อน

ดูโค้ด: [`examples/03-caching-patterns/`](./examples/03-caching-patterns/)

---

## 4. Cache Eviction Policies

เมื่อ Redis ถึง `maxmemory` มันจะไล่ key ตามนโยบาย:

| Policy         | พฤติกรรม                     | ใช้เมื่อ                                 |
| -------------- | ---------------------------- | ---------------------------------------- |
| `noeviction`   | เขียนใหม่แล้ว error          | ข้อมูลสำคัญที่ห้ามหาย                    |
| `allkeys-lru`  | ลบ key ที่ใช้นานแล้วทั้งระบบ | cache ทั่วไป (ค่าเริ่มต้นที่แนะนำใน lab) |
| `volatile-lru` | LRU เฉพาะ key ที่มี TTL      | ผสม persistent keys + cache              |
| `allkeys-lfu`  | ลบของที่ใช้น้อยครั้ง         | traffic ที่มี hot keys ชัด               |
| `volatile-ttl` | ลบ key ที่ใกล้หมดอายุก่อน    | —                                        |

ตั้งใน `redis.conf` หรือ Docker command (ดู `docker-compose.yml` ของ bootcamp):

```text
maxmemory 256mb
maxmemory-policy allkeys-lru
```

**Best Practice:** production ต้อง monitor `used_memory`, hit rate, eviction count — eviction
ที่สูงผิดปกติแปลว่า cache เล็กเกินไปหรือ TTL สั้น/ยาวผิด

---

## 5. Data Modeling — Embedded vs References

คำถามหลักของ NoSQL modeling: **ข้อมูลนี้ถูกอ่าน/เขียนด้วยกันบ่อยแค่ไหน?**

### Embedded Documents

```js
// Order ฝัง items — อ่านออเดอร์ครั้งเดียวจบ
{
 orderNo: "ORD-1001",
 items: [
 { sku: "TSHIRT-01", name: "Classic Tee", qty: 2, unitPrice: 390 }
 ]
}
```

| เหมาะเมื่อ                            | ไม่เหมาะเมื่อ                       |
| ------------------------------------- | ----------------------------------- |
| ความสัมพันธ์ 1:few และอ่านด้วยกันเสมอ | เอกสารโตไม่จำกัด (comments ล้านแถว) |
| ต้องการ atomic update ทั้งก้อน        | ข้อมูลถูกแชร์และ update จากหลายที่  |
| Snapshot ณ เวลาหนึ่ง (ราคาตอนสั่ง)    | ต้อง query ย่อยของลูกบ่อยแบบอิสระ   |

### References

```js
// Product อ้าง categoryId — category แชร์และเปลี่ยนชื่อได้ที่เดียว
{ sku: "TSHIRT-01", name: "Classic Tee", categoryId: ObjectId("...") }
```

| เหมาะเมื่อ                 | ข้อควรระวัง                          |
| -------------------------- | ------------------------------------ |
| Many-to-many / แชร์ entity | ต้อง `$lookup` หรือ query รอบสอง     |
| เอกสารลูกมี lifecycle เอง  | application-level join มีค่า latency |

### กฎง่าย ๆ ที่ใช้จริง

1. **Embed** สิ่งที่เป็นส่วนประกอบของ parent และไม่แชร์ (order items, address ตอน checkout)
2. **Reference** สิ่งที่เป็น master data ที่แชร์ (users, categories, warehouses)
3. **Hybrid:** embed snapshot ที่จำเป็นตอนอ่าน + เก็บ id อ้างกลับไป master ถ้าต้อง sync ภายหลัง
4. ออกแบบจาก **คำถามของ UI/API** เช่น “หน้า order detail ต้องการฟิลด์อะไรบ้างใน 1 round-trip?”

ดูโค้ด: [`examples/04-data-modeling/`](./examples/04-data-modeling/)

---

## 6. Best Practices สรุป

1. ใส่ `$match` ต้น pipeline และสร้าง index รองรับฟิลด์ที่ match/sort
2. Leaderboard ใช้ **Sorted Set** — อย่า `SORT` list ทั้งก้อนในแอป
3. Cache key ต้องมี **namespace + version ได้** เช่น `cache:v1:product:SKU`
4. Invalidation ให้ชัด: เขียน DB สำเร็จแล้วค่อย `DEL` (Cache-Aside)
5. อย่า cache ข้อมูลที่ต้อง strong consistency ทุก millisecond โดยไม่มีแผน stampede (เรียนต่อระดับ
   Expert)
6. Document ขนาดไม่ควรเข้าใกล้ 16MB limit — แยก collection เมื่อ array โตไม่หยุด
7. วัด hit ratio; cache ที่ hit < 50% อาจออกแบบ key/TTL ผิด

---

## ลำดับการเรียนในระดับนี้

```
01-mongodb-aggregation → 02-redis-advanced-structures → 03-caching-patterns → 04-data-modeling
           ↓
           LAB.md
```

เมื่อออกแบบรายงาน + leaderboard + cache-aside + เลือก embed/ref ได้แล้ว → ไป
[`03-expert/`](../03-expert/)
