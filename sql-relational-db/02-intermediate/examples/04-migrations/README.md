# 04 — Schema Migrations

ตัวอย่าง migration แบบ Flyway-style พร้อมตาราง `schema_migrations`

> สำคัญ: รันบน **database ว่าง** (หรือสร้าง DB ใหม่) ตามลำดับ V001 → V004
> ไฟล์เหล่านี้ตั้งใจให้รันครั้งเดียว — ไม่ใช้ `IF NOT EXISTS` กลบ schema เก่าที่โครงสร้างต่างกัน

## วิธีรันตามลำดับ

```bash
# สร้าง DB ว่างก่อน (ตัวอย่าง)
docker exec rdb-bootcamp-postgres psql -U bootcamp -d postgres -c "DROP DATABASE IF EXISTS migdemo;"
docker exec rdb-bootcamp-postgres psql -U bootcamp -d postgres -c "CREATE DATABASE migdemo OWNER bootcamp;"

# PostgreSQL
for f in postgresql/V00*.sql; do
  psql "postgresql://bootcamp:bootcamp@localhost:5432/migdemo" -f "$f"
done

# MySQL
docker exec rdb-bootcamp-mysql mysql -uroot -proot -e "DROP DATABASE IF EXISTS migdemo; CREATE DATABASE migdemo; GRANT ALL ON migdemo.* TO 'bootcamp'@'%';"
for f in mysql/V00*.sql; do
  mysql -h 127.0.0.1 -P 3306 -u bootcamp -pbootcamp migdemo < "$f"
done
```

## Checklist

- [ ] ไม่แก้ไฟล์ V00x ที่ขึ้น production แล้ว
- [ ] หนึ่งไฟล์ = หนึ่งจุดประสงค์
- [ ] Expand/Contract สำหรับ breaking change
- [ ] บันทึก version ที่ apply แล้ว
- [ ] เครื่องมือจริง (Flyway/Liquibase/Atlas) จะข้าม version ที่อยู่ใน `schema_migrations`
      ให้อัตโนมัติ
