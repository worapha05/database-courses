# Level 1 — Beginner: NoSQL Foundations & Core Operations

เป้าหมายระดับนี้: ให้คุณเข้าใจ **ทำไมต้องใช้ NoSQL** และเริ่มใช้งาน MongoDB / Redis ได้จริง
ไม่ใช่แค่จำคำสั่ง — เพื่อเลือกเครื่องมือและออกแบบ key/document ให้เหมาะกับงาน

---

## สารบัญ

1. [NoSQL คืออะไร และต่างจาก RDBMS อย่างไร](#1-nosql-คืออะไร-และต่างจาก-rdbms-อย่างไร)
2. [Document Store vs Key-Value Store](#2-document-store-vs-key-value-store)
3. [BSON และโครงสร้าง Document ใน MongoDB](#3-bson-และโครงสร้าง-document-ใน-mongodb)
4. [MongoDB Core CRUD & Query Selectors](#4-mongodb-core-crud--query-selectors)
5. [Redis String Operations](#5-redis-string-operations)
6. [Data Expiration — EXPIRE / TTL](#6-data-expiration--expire--ttl)
7. [Redis Hashes](#7-redis-hashes)
8. [Best Practices สรุป](#8-best-practices-สรุป)

---

## 1. NoSQL คืออะไร และต่างจาก RDBMS อย่างไร

**NoSQL** (Not Only SQL) คือกลุ่มฐานข้อมูลที่ออกแบบมาเพื่อความยืดหยุ่นของ schema, การกระจายข้อมูล
(horizontal scale) และ access pattern ที่ไม่บังคับ JOIN แบบ relational

| มิติ         | Relational (PostgreSQL/MySQL)      | NoSQL (MongoDB / Redis)                                          |
| ------------ | ---------------------------------- | ---------------------------------------------------------------- |
| Schema       | ตาราง + column ตายตัว (DDL)        | Document/Key อิสระกว่า — schema-on-read                          |
| ความสัมพันธ์ | FK + JOIN                          | Embed / Reference / application-level join                       |
| Transaction  | ACID เต็มรูปแบบเป็นค่าเริ่มต้น     | MongoDB มี multi-doc ACID; Redis เป็น single-key atomic เป็นหลัก |
| Scale        | Vertical ง่าย; horizontal ซับซ้อน  | ออกแบบมาเพื่อ scale-out (sharding/cluster)                       |
| Use case     | ข้อมูลธุรกรรม, ความสัมพันธ์ซับซ้อน | Product catalog, session, cache, real-time counters              |

> **กฎทอง:** อย่าเลือก NoSQL เพราะ "เท่" — เลือกเมื่อ access pattern ของคุณได้ประโยชน์จาก document
> หรือ in-memory key-value จริง ๆ

ดูเปรียบเทียบสั้น ๆ: [`examples/01-nosql-vs-relational/`](./examples/01-nosql-vs-relational/)

---

## 2. Document Store vs Key-Value Store

### MongoDB — Document Store

- เก็บข้อมูลเป็น **document** (คล้าย JSON) ใน **collection**
- Query ได้หลายเงื่อนไข, มี index, aggregation
- เหมาะเป็น **primary datastore** ของแอปหลายประเภท

```
Database → Collection → Document
bootcamp → products → { _id, sku, name, price, tags: [...] }
```

### Redis — Key-Value (In-Memory)

- เก็บคู่ key → value ในหน่วยความจำ (เร็วมาก)
- Value มีหลายชนิด: String, Hash, List, Set, Sorted Set, Stream
- เหมาะเป็น **cache, session, rate limit, leaderboard, pub/sub** —
  ไม่ใช่คลังข้อมูลถาวรเพียงอย่างเดียว

```
Key    Value
product:sku:TSHIRT-01 "{\"name\":\"Tee\",\"price\":390}"
session:user:42  Hash { role, cartId, lastSeen }
```

| คำถามตัดสินใจ                                         | เลือก                                       |
| ----------------------------------------------------- | ------------------------------------------- |
| ต้อง query หลายฟิลด์ / report / ความสัมพันธ์ยืดหยุ่น? | MongoDB                                     |
| ต้อง latency ต่ำมาก, TTL, counter, ephemeral state?   | Redis                                       |
| ข้อมูลต้องรอดหลัง restart และเป็นแหล่งความจริง?       | MongoDB (หรือ RDBMS) + Redis เป็นชั้น cache |

---

## 3. BSON และโครงสร้าง Document ใน MongoDB

MongoDB เก็บข้อมูลเป็น **BSON** (Binary JSON) — รองรับชนิดที่ JSON มาตรฐานไม่มี เช่น `ObjectId`,
`Date`, `Decimal128`, `Binary`

```js
{
  _id: ObjectId("665f..."),  // primary key อัตโนมัติ
  sku: "TSHIRT-01",
  name: "Classic Tee",
  price: 390,    // Number (หรือ Decimal128 สำหรับเงินจริงจัง)
  tags: ["apparel", "cotton"], // array
  attributes: { color: "navy", size: "M" }, // nested document
  createdAt: ISODate("2026-07-18")
}
```

### แนวคิดการออกแบบ Schema แบบ NoSQL (พื้นฐาน)

1. **ออกแบบตาม query ที่แอปยิง** — ไม่เริ่มจาก ER diagram แบบ RDBMS แล้ว map 1:1
2. **ข้อมูลที่อ่านด้วยกันบ่อย → embed** ใน document เดียวกัน
3. **ข้อมูลที่แชร์และ update อิสระ → reference** ด้วย `ObjectId`
4. **หลีกเลี่ยง unbounded arrays** (เช่น comments ไม่จำกัดในเอกสารเดียว)

ตัวอย่างผิด (คิดแบบตาราง):

```js
// ❌ แยกทุกอย่างเป็น collection แล้ว join ในแอปทุกครั้ง โดยไม่จำเป็น
{
  (_id, productId);
} // product_attrs
{
  (_id, productId);
} // product_prices
```

ตัวอย่างถูกสำหรับ product page:

```js
// ✅ เอกสารสินค้าที่หน้า product อ่านครั้งเดียวจบ
{
  sku: "TSHIRT-01",
  name: "Classic Tee",
  price: 390,
  inventory: { warehouseA: 12, warehouseB: 3 },
  images: [{ url: "...", alt: "front" }]
}
```

---

## 4. MongoDB Core CRUD & Query Selectors

คำสั่งหลักที่ต้องชิน:

| Operation | Method                                    | ความหมาย    |
| --------- | ----------------------------------------- | ----------- |
| Create    | `insertOne` / `insertMany`                | เพิ่มเอกสาร |
| Read      | `find` / `findOne`                        | ค้นหา       |
| Update    | `updateOne` / `updateMany` / `replaceOne` | แก้         |
| Delete    | `deleteOne` / `deleteMany`                | ลบ          |

### Query selectors ที่ใช้บ่อย

```js
{ price: { $gte: 100, $lte: 500 } } // ช่วงราคา
{ tags: "cotton" }   // array contains
{ name: { $regex: /^Classic/i } } // regex (ระวังประสิทธิภาพ)
{ "attributes.color": "navy" }  // nested field
{ $or: [{ stock: 0 }, { active: false }] }
```

### Update operators

```js
{ $set: { price: 420 } }
{ $inc: { "inventory.warehouseA": -1 } }
{ $push: { tags: "sale" } }
{ $unset: { deprecatedField: "" } }
```

> Production tip: update ด้วย **operator** (`$set`, `$inc`) ดีกว่า `replaceOne`
> ทั้งก้อนเมื่อต้องการเปลี่ยนบางฟิลด์ — ลด race กับการเขียนพร้อมกัน

ดูโค้ดรันได้: [`examples/02-mongodb-crud/`](./examples/02-mongodb-crud/)

---

## 5. Redis String Operations

String คือชนิดพื้นฐานที่สุดของ Redis — value เป็น byte string (มักเก็บ JSON หรือตัวเลข)

```redis
SET product:TSHIRT-01 '{"name":"Classic Tee","price":390}'
GET product:TSHIRT-01
DEL product:TSHIRT-01
INCR pageviews:home  # atomic counter
INCRBY stock:TSHIRT-01 -1
```

| คำสั่ง                | ใช้เมื่อ                                          |
| --------------------- | ------------------------------------------------- |
| `SET` / `GET`         | cache payload ทั้งก้อน                            |
| `SET key value EX 60` | set พร้อม TTL ในคำสั่งเดียว (แนะนำ)               |
| `INCR` / `INCRBY`     | counter ที่ต้อง atomic (views, rate limit bucket) |
| `DEL`                 | ลบ key (invalidate)                               |
| `EXISTS`              | เช็คว่ามี cache หรือยัง                           |

ดูโค้ด: [`examples/03-redis-strings-ttl/`](./examples/03-redis-strings-ttl/)

---

## 6. Data Expiration — EXPIRE / TTL

Redis โดดเด่นเรื่อง **TTL** — ข้อมูลหมดอายุแล้วถูกลบอัตโนมัติ

```redis
SET session:42 "..." EX 1800 # หมดใน 30 นาที
EXPIRE session:42 900  # ตั้ง/เปลี่ยน TTL เป็นวินาที
TTL session:42   # เหลือกี่วินาที (-1 = ไม่มี TTL, -2 = ไม่มี key)
PERSIST session:42  # ถอด TTL ออก
```

### กลยุทธ์ TTL สำหรับมือใหม่

| ข้อมูล                | TTL แนะนำ (เริ่มต้น) | เหตุผล                |
| --------------------- | -------------------- | --------------------- |
| Session               | 15–60 นาที           | security + memory     |
| Product cache         | 1–5 นาที             | ราคา/สต็อกเปลี่ยนบ่อย |
| Config / feature flag | 30–300 วินาที        | อ่านบ่อย เปลี่ยนน้อย  |
| OTP / magic link      | 1–10 นาที            | อายุสั้นโดยเจตนา      |

> **Best Practice:** ทุก cache key ควรมี TTL หรือแผน invalidation ที่ชัด — key
> ที่ไม่มีวันหมดอายุคือบั๊กที่รอวันระเบิด memory

---

## 7. Redis Hashes

Hash เหมาะกับ object ที่มีหลายฟิลด์ — update ทีละฟิลด์ได้โดยไม่ deserialize ทั้ง JSON

```redis
HSET user:42 name "Mira" role "customer" cartId "c9"
HGET user:42 role
HGETALL user:42
HINCRBY user:42 loginCount 1
HDEL user:42 cartId
```

| ใช้ String (JSON ทั้งก้อน) เมื่อ | ใช้ Hash เมื่อ             |
| -------------------------------- | -------------------------- |
| อ่าน/เขียนทั้ง object เสมอ       | update บางฟิลด์บ่อย        |
| schema ซับซ้อน / nested ลึก      | ฟิลด์แบน ๆ ระดับเดียว      |
| ต้องการ atomic replace ทั้งก้อน  | ต้องการ `HINCRBY` ต่อฟิลด์ |

ดูโค้ด: [`examples/04-redis-hashes/`](./examples/04-redis-hashes/)

---

## 8. Best Practices สรุป

1. **ตั้งชื่อ key เป็นมาตรฐาน** เช่น `entity:id:field` → `product:TSHIRT-01:stock`
2. **อย่าเก็บข้อมูลสำคัญเฉพาะใน Redis** โดยไม่มีแหล่งความจริงอื่น
3. **ใช้ `insertOne` + unique index** สำหรับฟิลด์ที่ต้องไม่ซ้ำ (เช่น `sku`)
4. **Query ด้วย index ได้** — อย่า `$regex` นำหน้าแบบ `%foo` บน collection ใหญ่
5. **เงินใน production ใช้ `Decimal128`** หรือเก็บเป็น integer สตางค์ — อย่าพึ่ง IEEE float
6. **Soft delete** ใน MongoDB ด้วย `deletedAt` มักดีกว่า hard delete สำหรับข้อมูลธุรกิจ
7. **แยก environment** — connection string ผ่าน env (`MONGO_URI`, `REDIS_URL`) ไม่ hardcode
   ในโค้ดแอปจริง

---

## ลำดับการเรียนในระดับนี้

```
01-nosql-vs-relational → 02-mongodb-crud → 03-redis-strings-ttl → 04-redis-hashes
          ↓
          LAB.md
```

เมื่ออธิบายได้ว่าเมื่อใดใช้ MongoDB เมื่อใดใช้ Redis และเขียน CRUD + TTL ได้แล้ว → ไป
[`02-intermediate/`](../02-intermediate/)
