# Lab Solution — Intermediate (LearnHub)

```bash
# PostgreSQL
for f in postgresql/V00*.sql postgresql/04_reports.sql; do
  psql "postgresql://bootcamp:bootcamp@localhost:5432/bootcamp" -f "$f"
done

# MySQL
for f in mysql/V00*.sql mysql/04_reports.sql; do
  mysql -h 127.0.0.1 -P 3306 -u bootcamp -pbootcamp bootcamp < "$f"
done
```

หมายเหตุ MySQL: ถ้ารัน `V003` ซ้ำ constraint อาจ error — ใน lab ให้ drop DB หรือข้ามการรันซ้ำ
