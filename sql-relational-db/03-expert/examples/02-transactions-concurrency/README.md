# 02 — Transactions & Concurrency

## ทดลอง Race Condition (สอง session)

1. Session A: `BEGIN;` แล้ว `SELECT … FOR UPDATE` บน `inventory`
2. Session B: พยายาม `SELECT … FOR UPDATE` แถวเดียวกัน → **รอ**
3. Session A: update + `COMMIT`
4. Session B: ได้ล็อกต่อ — เห็นสต็อกที่ลดแล้ว

ถ้าไม่ใช้ `FOR UPDATE` และอ่านค่าไปคำนวณในแอป อาจ oversell ได้

## Isolation ที่ควรรู้

- PostgreSQL default: `read committed`
- MySQL InnoDB default: `REPEATABLE READ`
