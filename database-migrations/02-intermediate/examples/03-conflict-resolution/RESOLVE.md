# ขั้นตอนแก้ Migration Conflict (ทีม)

## กรณี Prisma

### บนเครื่องที่ยังไม่ apply อะไรจากสอง branch

```bash
git checkout main
git pull
npx prisma migrate dev # หรือ migrate deploy บน CI-like DB
npx prisma migrate status
```

### บนเครื่องที่เคย apply เฉพาะ branch A

```bash
git checkout main # ได้ไฟล์ B เพิ่ม
npx prisma migrate deploy
# status ควรแสดง A applied, B เพิ่ง applied
```

### ถ้ามีคนแก้ SQL ในไฟล์เก่าจน checksum พัง

1. **อย่า** แก้ checksum ใน DB ด้วยมือแบบเดาสุ่ม
2. Revert การแก้ไฟล์เก่าใน Git
3. สร้าง migration ใหม่ที่แก้ schema ตาม intent
4. ถ้า local พังจนแก้ยาก: สร้าง DB ใหม่แล้ว `migrate deploy` จากประวัติที่ถูกต้องบน main

### Failed migration กลางคัน

```bash
# 1) ตรวจว่า SQL ทำไปถึงไหน
# 2) แก้ schema ด้วยมือให้สอดคล้อง
# 3) บอก Prisma ว่าให้ถือว่า applied หรือ rolled back
npx prisma migrate resolve --applied "20260103100001_add_users_last_login_at"
```

## กรณี Knex

```bash
npx knex migrate:list
npx knex migrate:latest # รันเฉพาะไฟล์ที่ยังไม่อยู่ใน knex_migrations
```

ถ้าชื่อไฟล์ซ้ำ: เปลี่ยนชื่อไฟล์ที่ยังไม่ขึ้น shared env ให้ unique ถ้าซ้ำและ apply แล้วบางที่แล้ว —
ประสานทีมอย่า rename ของที่ production รู้จักแล้ว

## Checklist ก่อน merge PR ที่มี migration

- [ ] rebase/merge main ล่าสุด
- [ ] ไม่มีชื่อ folder/ไฟล์ซ้ำ
- [ ] CI รัน migrate บน clean database ผ่าน
- [ ] มี note ใน PR ว่า additive / destructive / มี data step
