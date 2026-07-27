# Lab Solution — Beginner (BookNest)

เฉลย schema ร้านหนังสือออนไลน์ตาม 3NF

## รัน

```bash
psql "postgresql://bootcamp:bootcamp@localhost:5432/bootcamp" -f postgresql/01_booknest.sql
mysql -h 127.0.0.1 -P 3306 -u bootcamp -pbootcamp bootcamp < mysql/01_booknest.sql
```

## จุดออกแบบสำคัญ

- `book_authors` แยก M:M + `author_ord` สำหรับลำดับผู้แต่ง
- `order_items.unit_price` เป็น snapshot
- สต็อกลดด้วย `UPDATE` แยกจาก insert ออเดอร์ (ระดับ Expert จะห่อด้วย transaction + lock)
