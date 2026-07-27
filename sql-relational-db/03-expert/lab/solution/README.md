# Lab Solution — Expert (StockGuard)

```bash
psql "postgresql://bootcamp:bootcamp@localhost:5432/bootcamp" -f postgresql/01_stockguard.sql
mysql -h 127.0.0.1 -P 3306 -u bootcamp -pbootcamp bootcamp < mysql/01_stockguard.sql
```

## จุดสำคัญของเฉลย

1. `SELECT … FOR UPDATE` ก่อนลดสต็อก
2. ตรวจ `stock_qty >= qty` ใน transaction เดียวกัน
3. Partial/composite index สำหรับ open reservations
4. Trigger เขียน audit เมื่อ status เปลี่ยน
5. Window functions สำหรับ running stock และ top movement รายวัน
