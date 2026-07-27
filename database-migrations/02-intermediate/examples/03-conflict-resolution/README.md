# Example 03 — Conflict Resolution

จำลองสอง branch สร้าง migration พร้อมกัน และวิธีรวม

## สถานการณ์

```
migrations/
 20260103100000_add_users_avatar_url/ # จาก branch A
 20260103100000_add_users_last_login_at/ # จาก branch B — ชน timestamp!
```

## แนวทางแก้

1. เวลา merge: เปลี่ยนชื่อฝั่งหนึ่งให้ timestamp ไม่ซ้ำ เช่น `20260103100001_...`
2. ตรวจสอบว่า SQL ไม่พึ่งพากันแบบ hard dependency (additive มักรวมได้)
3. นักพัฒนาที่ apply แค่ A แล้ว: ดึง main แล้ว `migrate deploy` / `migrate:latest` เพื่อรับ B
4. **ห้าม** แก้เนื้อไฟล์ A ที่ขึ้น production แล้วเพื่อรวมกับ B

ดู [`RESOLVE.md`](./RESOLVE.md) และตัวอย่าง migration ใน folder นี้
