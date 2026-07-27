# 03 — EXPLAIN & Tuning

เปรียบเทียบแผน query ก่อน/หลังสร้าง composite index

## สิ่งที่ควรเห็น

- ก่อน index: Seq Scan / ALL บน `events`
- หลัง `(user_id, created_at)`: Index Scan / range ที่แคบลง
- PostgreSQL partial index ช่วย filter `event_type = 'purchase'`
- MySQL ใช้ `(event_type, created_at)` แทน partial
