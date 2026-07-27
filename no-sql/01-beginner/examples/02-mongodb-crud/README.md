# 02 — MongoDB Core CRUD

ฝึก `insertOne`, `find`, `updateOne`, `deleteOne` และ query selectors

## เตรียม

```bash
docker compose -f .infra/docker-compose.yml up -d
npm install
```

## รัน

```bash
node 01-beginner/examples/02-mongodb-crud/crud.js

# หรือ Python
pip install -r .infra/requirements.txt
python 01-beginner/examples/02-mongodb-crud/crud.py
```

## Checklist Production

- [ ] มี unique index บนฟิลด์ธุรกิจที่ต้องไม่ซ้ำ (`sku`)
- [ ] Update ใช้ `$set` / `$inc` ไม่ replace ทั้งก้อนโดยไม่จำเป็น
- [ ] Soft delete ด้วย `deletedAt` สำหรับข้อมูลธุรกิจ
- [ ] Connection string มาจาก env
