# Lab ระดับ Beginner — ระบบร้านค้า FlashMart (Catalog + Session Cache)

## เป้าหมาย

ออกแบบและ implement ชั้นข้อมูลสำหรับร้าน e-Commerce ขนาดเล็ก:

- **MongoDB** เป็นแหล่งความจริงของสินค้าและคำสั่งซื้อ
- **Redis** เก็บ session / cart ชั่วคราวและ cache รายละเอียดสินค้า

ทำด้วยตัวเองก่อน แล้วค่อยเทียบกับ [`lab/solution/`](./lab/solution/)

---

## กรณีศึกษา

startup **FlashMart** ขายสินค้าแฟชั่นออนไลน์ ทีมเคยเก็บทุกอย่างใน Google Sheet แล้วเจอปัญหา:

- สต็อกไม่ตรงเพราะหลายคนแก้พร้อมกัน
- หน้า product ช้าตอน traffic สูง
- session หายเมื่อรีสตาร์ท API (เก็บใน memory ของ process)

CTO ต้องการให้คุณสร้าง **data access layer** ชุดแรกด้วย MongoDB + Redis

---

## โจทย์

### ส่วนที่ 1 — MongoDB Schema & CRUD

สร้าง collection `products` และ `orders` ใน database `bootcamp` (หรือ `flashmart`):

**Product document อย่างน้อยต้องมี:**

| ฟิลด์       | ชนิด / หมายเหตุ    |
| ----------- | ------------------ |
| `sku`       | string, **unique** |
| `name`      | string             |
| `price`     | number             |
| `stock`     | number ≥ 0         |
| `tags`      | array of string    |
| `active`    | boolean            |
| `createdAt` | Date               |

**Order document:**

| ฟิลด์           | หมายเหตุ                                             |
| --------------- | ---------------------------------------------------- |
| `orderNo`       | string unique เช่น `ORD-1001`                        |
| `customerEmail` | string                                               |
| `items`         | array ของ `{ sku, name, qty, unitPrice }` (snapshot) |
| `total`         | number                                               |
| `status`        | `pending` / `paid` / `cancelled`                     |
| `createdAt`     | Date                                                 |

งานที่ต้องทำ:

1. `insertMany` สินค้าอย่างน้อย 5 รายการ
2. `find` สินค้าที่ `active: true` และ `price` ระหว่าง 100–500
3. `updateOne` ลด `stock` ของสินค้าหนึ่งชิ้นด้วย `$inc`
4. สร้างออเดอร์ 1 ใบพร้อม embed `items` (อย่าเก็บแค่ `productId` อย่างเดียวโดยไม่มี snapshot ราคา)
5. Soft-cancel ออเดอร์ด้วย `$set: { status: "cancelled" }` — **ห้าม** `deleteOne` ออเดอร์

### ส่วนที่ 2 — Redis Session & Product Cache

1. เก็บ session ผู้ใช้ด้วย **Hash**:

- key: `session:user:<email>`
- fields: `cartId`, `role`, `lastSku`
- TTL 30 นาที

2. Cache เอกสารสินค้าด้วย **String**:

- key: `cache:product:<sku>`
- value: JSON ของ `{ sku, name, price, stock }`
- TTL 60 วินาที

3. ใช้ `INCR` นับ `metrics:product:views:<sku>` ทุกครั้งที่ "เปิดดูสินค้า"
4. เมื่อสต็อกใน MongoDB เปลี่ยน — `DEL` cache key ของสินค้านั้น (invalidate)

### ส่วนที่ 3 — Integration Flow

เขียน function/script `getProduct(sku)` ตามลำดับ:

```
1. GET cache:product:<sku>
2. ถ้า hit → INCR view counter → return
3. ถ้า miss → findOne จาก MongoDB → SET cache พร้อม TTL → INCR view → return
4. ถ้าไม่มีสินค้า → return null (อย่า cache null ใน lab นี้ — จะเรียนที่ Expert)
```

---

## เกณฑ์ผ่าน

- [ ] มี unique index บน `products.sku` และ `orders.orderNo`
- [ ] ออเดอร์ embed snapshot ราคาใน `items`
- [ ] Session เป็น Hash + มี TTL
- [ ] Cache มี TTL และถูก `DEL` เมื่อ update สต็อก
- [ ] อธิบายได้ว่าทำไม Redis ไม่ใช่แหล่งความจริงของออเดอร์

---

## คำใบ้

```js
await products.createIndex({ sku: 1 }, { unique: true });
await redis.set(`cache:product:${sku}`, JSON.stringify(doc), 'EX', 60);
await redis.del(`cache:product:${sku}`);
```

เฉลยเต็มอยู่ที่ [`lab/solution/`](./lab/solution/)
