# 01 — Relational Model

สร้าง schema ร้านค้าออนไลน์ขนาดเล็กเพื่อฝึก PK, FK และความสัมพันธ์ 1:M / M:M

## รัน

```bash
# PostgreSQL
psql "postgresql://bootcamp:bootcamp@localhost:5432/bootcamp" -f postgresql/01_schema.sql

# MySQL
mysql -h 127.0.0.1 -P 3306 -u bootcamp -pbootcamp bootcamp < mysql/01_schema.sql
```

## สิ่งที่ควรสังเกต

- `customers` ↔ `orders` เป็น **1:M** (`orders.customer_id`)
- `orders` ↔ `products` เป็น **M:M** ผ่าน `order_items`
- `unit_price` ใน `order_items` เป็น **snapshot** ราคาตอนสั่ง ไม่ join ไปอ่านราคาปัจจุบันอย่างเดียว
- `ON DELETE CASCADE` ใช้กับ `order_items` เมื่อลบ order; แต่ลบ customer ใช้ `RESTRICT`
