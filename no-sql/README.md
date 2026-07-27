# NoSQL & Caching Bootcamp — Zero to Expert

bootcamp เรียนรู้ **NoSQL Databases และ Caching Mechanisms** แบบครบวงจร เน้น **MongoDB และ Redis**
จาก Document/Key-Value พื้นฐาน → Aggregation / Caching Patterns → High Availability / Resilience /
Real-time

---

## เป้าหมายของหลักสูตร

เมื่อจบหลักสูตรนี้ คุณจะสามารถ:

- อธิบายความต่างของ **Document Store (MongoDB)** กับ **Key-Value Store (Redis)** และเมื่อใดควรใช้แทน
  RDBMS
- เขียน **CRUD MongoDB** (BSON, query selectors) และคำสั่ง Redis พื้นฐาน (String / Hash / TTL)
- ออกแบบรายงานด้วย **Aggregation Pipeline** และใช้ Lists / Sets / Sorted Sets สำหรับ ranking
- เลือกและ implement **Cache-Aside / Write-Through** พร้อมนโยบาย eviction ที่เหมาะสม
- ออกแบบ **Embedded vs References** ตาม access pattern ของแอป
- ป้องกัน **Cache Avalanche / Stampede / Penetration** และ tune index ด้วย
  `explain("executionStats")`
- สร้างสถาปัตยกรรม real-time ด้วย **Change Streams + Redis Pub/Sub / Streams** และเข้าใจ HA (Replica
  Set, Sharding, Sentinel, Cluster)

---

## โครงสร้างหลักสูตร

| Level            | folder                                   | หัวข้อหลัก                                                              | เวลาแนะนำ   |
| ---------------- | ---------------------------------------- | ----------------------------------------------------------------------- | ----------- |
| 1 — Beginner     | [`01-beginner/`](./01-beginner/)         | NoSQL vs RDBMS, MongoDB CRUD, Redis String/Hash/TTL                     | 1–2 สัปดาห์ |
| 2 — Intermediate | [`02-intermediate/`](./02-intermediate/) | Aggregation, Redis advanced structures, Caching patterns, Data modeling | 2–3 สัปดาห์ |
| 3 — Expert       | [`03-expert/`](./03-expert/)             | Cache resilience, Indexing & EXPLAIN, Change Streams / Pub-Sub, HA      | 2–4 สัปดาห์ |

แต่ละระดับประกอบด้วย:

1. **`README.md`** — ทฤษฎีเชิงลึกภาษาไทย เน้น schema design และ caching strategy
2. **`examples/`** — โค้ด JavaScript (Node.js) / Python ที่รันได้จริงกับ MongoDB + Redis
3. **`LAB.md`** — โจทย์กรณีศึกษาจริงพร้อมเฉลยเต็มใน `lab/solution/`

---

## ข้อกำหนดเบื้องต้น

- ความรู้พื้นฐาน JavaScript (ES modules, async/await) หรือ Python 3.11+
- ความเข้าใจ HTTP / JSON พื้นฐาน
- ติดตั้ง [Docker](https://www.docker.com/) (แนะนำ) และ [Node.js 20+](https://nodejs.org/)

```bash
docker --version
node -v           # ควรเป็น v20.x ขึ้นไป
python3 --version # สำหรับตัวอย่าง Python (optional)
```

---

## วิธีใช้ Bootcamp

1. สตาร์ท MongoDB + Redis ด้วย Docker Compose จาก root ของ bootcamp
2. อ่าน `README.md` ของระดับนั้นให้จบ — โฟกัสที่ **ทำไมออกแบบ schema / cache แบบนี้**
3. รันตัวอย่างใน `examples/` ตามลำดับ
4. ทำ Lab ใน `LAB.md` **ด้วยตัวเองก่อน** แล้วค่อยดูเฉลย
5. ไประดับถัดไปเมื่ออธิบาย trade-off ของการออกแบบได้

```bash
cd database/nosql
docker compose -f .infra/docker-compose.yml up -d

# ติดตั้ง dependencies (ใช้ร่วมทุก examples)
npm install

# Beginner — MongoDB CRUD
node 01-beginner/examples/02-mongodb-crud/crud.js

# หรือตัวอย่าง Python (optional)
python3 -m venv .venv && source .venv/bin/activate
pip install -r .infra/requirements.txt
python 01-beginner/examples/02-mongodb-crud/crud.py
```

| บริการ                        | Host Port | Credentials / Notes                               |
| ----------------------------- | --------- | ------------------------------------------------- |
| MongoDB 7 (replica set `rs0`) | `27017`   | user `bootcamp` / pass `bootcamp` / db `bootcamp` |
| Redis 7                       | `6379`    | ไม่มีรหัสผ่าน (local lab เท่านั้น)                |
| Mongo Express (optional UI)   | `8081`    | `bootcamp` / `bootcamp`                           |

Connection strings:

```text
mongodb://bootcamp:bootcamp@localhost:27017/bootcamp?authSource=admin&replicaSet=rs0&directConnection=true
redis://localhost:6379
```

---

## Learning Path ที่แนะนำ

```
Beginner: NoSQL mindset + Mongo CRUD + Redis String/Hash/TTL
 ↓
Intermediate: Aggregation + Advanced Redis + Cache patterns + Modeling
 ↓
Expert: Resilience + Indexes/EXPLAIN + Real-time + HA / Scale-out
 ↓
project จริงของคุณเอง (e-Commerce API / Real-time Dashboard)
```

---

## หลักการสำคัญที่หลักสูตรย้ำตลอด

| หลักการ                      | ความหมายใน MongoDB / Redis                                                 |
| ---------------------------- | -------------------------------------------------------------------------- |
| Access pattern มาก่อน schema | ออกแบบ document ตาม query ที่แอปยิงจริง ไม่ copy ตาราง RDBMS               |
| Redis ไม่ใช่ source of truth | ข้อมูลสำคัญอยู่ที่ MongoDB (หรือ RDBMS); Redis คือ cache / ephemeral state |
| TTL เป็นสัญญา                | ทุก cache key ต้องมี expiration หรือ invalidation plan ที่ชัด              |
| Embed vs Ref มี trade-off    | Embed เมื่ออ่านด้วยกันเสมอ; Reference เมื่อแชร์และ update อิสระ            |
| Index มีราคา                 | เร่งอ่าน แต่ช้าลงตอนเขียน และกิน memory                                    |
| HA ไม่ใช่ backup             | Replica / Sentinel / Cluster แก้ availability ไม่แทนการสำรองข้อมูล         |

---

## Tech Stack มาตรฐานของหลักสูตร

| ชั้น                  | เทคโนโลยี                                 |
| --------------------- | ----------------------------------------- |
| Document DB           | MongoDB 7.x                               |
| Cache / KV            | Redis 7.x                                 |
| Primary language      | Node.js 20+ (ESM) + `mongodb` + `ioredis` |
| Secondary             | Python 3.11+ (`pymongo`, `redis`)         |
| Orchestration (เรียน) | Docker Compose                            |
| Package manager       | npm                                       |
