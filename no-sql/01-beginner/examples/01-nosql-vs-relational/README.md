# 01 — NoSQL vs Relational

เปรียบเทียบการเก็บ "สินค้า + ออเดอร์" แบบตาราง (คิดแบบ RDBMS) กับแบบ document / key-value

## รัน

```bash
node 01-beginner/examples/01-nosql-vs-relational/compare.js
```

## จุดที่ต้องเข้าใจ

- RDBMS แยกตารางแล้ว JOIN
- MongoDB embed รายการออเดอร์ในเอกสาร order ได้
- Redis เหมาะกับ snapshot ที่ต้องอ่านเร็ว (เช่น สต็อกชั่วคราว) ไม่ใช่ประวัติออเดอร์หลัก
