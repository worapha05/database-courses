# Level 3 — Expert: Enterprise Scale, Optimization & Resilience

เป้าหมายระดับนี้: ออกแบบระบบ NoSQL/Cache ที่ **ทนต่อ traffic พุ่ง, วินิจฉัยช้าได้,
และขยายแบบกระจาย** ไม่ใช่แค่ทำให้ทำงาน — เพื่อป้องกัน failure modes ที่เจอใน production จริง

---

## สารบัญ

1. [High-Performance Caching Risks](#1-high-performance-caching-risks)
2. [MongoDB Indexing & Explain](#2-mongodb-indexing--explain)
3. [Real-time — Change Streams & Redis Pub/Sub / Streams](#3-real-time--change-streams--redis-pubsub--streams)
4. [Distributed Ops — Replica Set, Sharding, Sentinel, Cluster](#4-distributed-ops--replica-set-sharding-sentinel-cluster)
5. [Best Practices สรุป](#5-best-practices-สรุป)

---

## 1. High-Performance Caching Risks

### Cache Avalanche (หิมะถล่ม)

**อาการ:** key จำนวนมากหมดอายุพร้อมกัน → request พุ่งเข้า DB พร้อมกัน → DB ล่ม

**แก้:**

- สุ่ม TTL: `baseTTL + random(0, jitter)`
- แยก TTL ตามชนิดข้อมูล
- multi-level cache (local + Redis) สำหรับ hot keys
- circuit breaker / bulkhead ที่ชั้นแอป

```js
const ttl = 60 + Math.floor(Math.random() * 30); // 60–89 วินาที
await redis.set(key, value, 'EX', ttl);
```

### Cache Stampede / Thundering Herd

**อาการ:** key เดียวหมดอายุ → request นับร้อยพากัน miss → ยิง DB ซ้ำสำหรับข้อมูลชุดเดียวกัน

**แก้:**

1. **Singleflight / lock:** ใช้ `SET lock NX EX` ให้มีแค่ 1 worker โหลด DB
2. **Soft TTL / early refresh:** ต่ออายุก่อนหมดจริง
3. **Probabilistic early expiration**

```js
async function getWithSingleflight(key, loader, ttlSec = 60) {
  const hit = await redis.get(key);
  if (hit) return JSON.parse(hit);

  const lockKey = `lock:${key}`;
  const gotLock = await redis.set(lockKey, '1', 'EX', 5, 'NX');
  if (gotLock) {
    try {
      const value = await loader();
      if (value != null) await redis.set(key, JSON.stringify(value), 'EX', ttlSec);
      return value;
    } finally {
      await redis.del(lockKey);
    }
  }

  // คนอื่นกำลังโหลด — รอแล้วลอง cache อีกครั้ง
  await new Promise(r => setTimeout(r, 50));
  const retry = await redis.get(key);
  if (retry) return JSON.parse(retry);
  return loader(); // fallback สุดท้าย
}
```

### Cache Penetration

**อาการ:** ลูกค้า/บอทขอ id ที่**ไม่มีใน DB** ซ้ำ ๆ → miss ตลอด → DB โดนยิง

**แก้:**

- Cache **negative result** ชั่วคราว (`SET key:null EX 30`)
- Bloom filter / Cuckoo filter หน้า cache
- Validate id ที่ขอบ API ก่อน

```js
if (!doc) {
  await redis.set(key, 'NULL', 'EX', 30);
  return null;
}
```

ดูโค้ด: [`examples/01-cache-resilience/`](./examples/01-cache-resilience/)

---

## 2. MongoDB Indexing & Explain

Index คือโครงสร้างช่วยค้นหา — **เร่งอ่าน แต่เพิ่มต้นทุนเขียนและ memory**

### ชนิด index ที่ต้องรู้

| ชนิด         | ตัวอย่าง                                | ใช้เมื่อ                     |
| ------------ | --------------------------------------- | ---------------------------- |
| Single-field | `{ email: 1 }`                          | filter/sort ฟิลด์เดียวบ่อย   |
| Compound     | `{ status: 1, createdAt: -1 }`          | filter หลายฟิลด์ตามลำดับ ESR |
| Multikey     | `{ tags: 1 }`                           | index บน array               |
| Text         | `{ name: "text", description: "text" }` | full-text search พื้นฐาน     |
| Geospatial   | `{ location: "2dsphere" }`              | ใกล้ฉัน / รัศมี              |

### ESR Rule สำหรับ Compound Index

เรียงคีย์ใน compound ตาม: **Equality → Sort → Range**

```js
// query: status = "paid", sort createdAt, range total
{ status: 1, createdAt: -1, total: 1 }
```

### วิเคราะห์ด้วย explain

```js
const stats = await orders
  .find({ status: 'paid', createdAt: { $gte: since } })
  .sort({ createdAt: -1 })
  .explain('executionStats');

console.log(stats.executionStats.executionStages.stage);
console.log(stats.executionStats.totalDocsExamined);
console.log(stats.executionStats.nReturned);
```

สัญญาณดี: `IXSCAN` และ `totalDocsExamined ≈ nReturned` สัญญาณแย่: `COLLSCAN` หรือ examined
สูงกว่ารeturned มาก

### คำสั่งระดับ Production

```bash
# ใน mongosh
db.currentOp({ "secs_running": { "$gte": 2 } })
db.orders.aggregate([{ $indexStats: {} }])
db.orders.getIndexes()
db.orders.dropIndex("status_1_createdAt_-1")
```

ดูโค้ด: [`examples/02-mongodb-indexing/`](./examples/02-mongodb-indexing/)

---

## 3. Real-time — Change Streams & Redis Pub/Sub / Streams

### MongoDB Change Streams

ฟังการเปลี่ยนแปลงของ collection / database / cluster แบบ event (ต้องใช้ **Replica Set** — แม้
single-node ก็เปิดได้ด้วย `--replSet`)

```js
const stream = orders.watch([{ $match: { operationType: { $in: ['insert', 'update'] } } }], {
  fullDocument: 'updateLookup',
});

for await (const event of stream) {
  // event.operationType, event.fullDocument, event.documentKey
  await redis.publish('orders:events', JSON.stringify(event.fullDocument));
}
```

ใช้เมื่อ: sync cache, push ไป websocket, audit, CDC ไประบบอื่น

### Redis Pub/Sub

```redis
SUBSCRIBE orders:events
PUBLISH orders:events '{"orderNo":"ORD-1"}'
```

**ข้อจำกัด:** ถ้า subscriber ออฟไลน์ ข้อความ**หาย** — ไม่มี persistence

### Redis Streams

คิวแบบ append-only มี consumer group — เหมาะกับ event ที่ต้องประมวลผลอย่างน้อยหนึ่งครั้ง

```redis
XADD orders:stream * orderNo ORD-1 total 1030
XGROUP CREATE orders:stream workers $ MKSTREAM
XREADGROUP GROUP workers consumer-1 COUNT 10 BLOCK 2000 STREAMS orders:stream >
XACK orders:stream workers 1710000000000-0
```

| เครื่องมือ     | Persistence | Fan-out         | ใช้เมื่อ                            |
| -------------- | ----------- | --------------- | ----------------------------------- |
| Pub/Sub        | ไม่         | ดี              | notification สด, ไม่ทน message loss |
| Streams        | มี          | consumer groups | pipeline ประมวลผลออเดอร์, retry ได้ |
| Change Streams | oplog-based | ต่อ consumer    | CDC จาก MongoDB                     |

ดูโค้ด: [`examples/03-realtime-streams/`](./examples/03-realtime-streams/)

---

## 4. Distributed Ops — Replica Set, Sharding, Sentinel, Cluster

### MongoDB Replica Set

- Primary รับเขียน; Secondary replicate จาก oplog
- Automatic failover เมื่อ primary ตาย (ต้องมี majority)
- อ่านจาก secondary ได้ (eventual consistency) ด้วย read preference

```text
mongodb://host1,host2,host3/?replicaSet=rs0
```

### MongoDB Sharding

- แบ่งข้อมูลตาม **shard key** ไปหลาย shard
- Config servers เก็บ metadata; mongos เป็น router
- เลือก shard key ผิด = hotspot / fan-out query

หลักการเลือก shard key: cardinality สูง, ไม่ monotonic อย่างเดียว (เลี่ยง `_id` อย่างเดียวบน
insert-heavy), สอดคล้อง query หลัก

### Redis Sentinel

- Monitor Redis master/replicas
- เลือก master ใหม่เมื่อล่ม + บอก client ว่าใครเป็น master

```text
redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
```

### Redis Cluster

- แบ่ง hash slots 16384 ช่องไปหลายโหนด
- Scale แนวนอนทั้งอ่านและเขียน
- Multi-key command ต้องอยู่ใน slot เดียวกัน (ใช้ hash tag `{user:42}:cart`)

ดูภาพรวมคำสั่งและ script จำลอง: [`examples/04-ha-distributed/`](./examples/04-ha-distributed/)

> Lab ใช้ single-node Mongo replica set + Redis จาก `docker-compose.yml` เพื่อให้ Change Streams
> รันได้จริง — ส่วน Sentinel / Cluster / multi-shard เป็นความรู้สถาปัตยกรรม +
> คำสั่งที่ต้องรู้จักตอนขึ้น production

---

## 5. Best Practices สรุป

1. TTL มี jitter เสมอสำหรับ hot key จำนวนมาก
2. Stampede ใช้ lock แบบ `SET NX` หรือ singleflight library
3. Penetration → cache NULL สั้น ๆ หรือ Bloom filter
4. วัด index ด้วย `executionStats` ก่อนเพิ่ม index ชุดใหม่
5. ลบ index ที่ไม่มีใครใช้ (`$indexStats`) — index กิน RAM และช้าลงตอนเขียน
6. Pub/Sub ≠ queue; งานที่ต้องไม่หายใช้ Streams / broker จริง
7. Change Streams ต้อง replica set; วาง resume token สำหรับ reconnect
8. Shard key / hash tag ออกแบบตั้งแต่ต้น — ย้ายทีหลังแพงมาก
9. HA ไม่แทน backup: ทำ snapshot + PITR ตามนโยบายองค์กร
10. ตั้ง alert: Redis memory/evictions, Mongo replication lag, cache hit ratio

---

## ลำดับการเรียนในระดับนี้

```
01-cache-resilience → 02-mongodb-indexing → 03-realtime-streams → 04-ha-distributed
          ↓
          LAB.md
```

จบระดับนี้แล้ว คุณพร้อมออกแบบระบบ e-Commerce / dashboard ระดับ production ที่ใช้ MongoDB + Redis
อย่างมีสติ
