# เฉลยส่วน C — Migration Conflict

## ทำไมถึง conflict / เพี้ยน

- สอง branch สร้าง migration จาก parent เดียวกัน → ชื่อ folder หรือ timestamp อาจชน
- Git merge ต้องมี **ทั้งสองไฟล์** — additive schema มักรวมได้โดยไม่ต้องเลือกทิ้ง
- Local DB ของ dev ที่ merge ช้าอาจมีประวัติแค่ฝั่ง A → ต้องรัน migration ที่ขาด ไม่ใช่ reset prod

## ขั้นตอนมาตรฐาน

1. บน PR สุดท้าย: เปลี่ยน timestamp ของฝั่ง B เป็น `...90001_...` ถ้าชนกับ A
2. รวมเข้า `main`
3. Dev ที่เคย apply A:

```bash
git pull
npx prisma migrate deploy
# หรือ
npx knex migrate:latest
```

4. Dev / CI ที่ยังว่าง: รัน migrate ทั้งหมดตามลำดับชื่อไฟล์

## สิ่งที่ห้ามทำ

- แก้ SQL ใน migration ที่ production apply แล้วเพื่อ “รวมไฟล์”
- ลบแถวใน `_prisma_migrations` / `knex_migrations` แล้วหวังว่าจะสอดคล้องเอง
- `migrate reset` บน shared staging โดยไม่ประกาศ
