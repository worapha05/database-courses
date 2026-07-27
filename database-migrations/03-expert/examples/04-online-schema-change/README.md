# Example 04 — Online Schema Change Strategies

กลยุทธ์ลดผลกระทบจาก DDL บนตารางใหญ่

## Postgres

ดู [`postgres_concurrent_index.sql`](./postgres_concurrent_index.sql)

- `CREATE INDEX CONCURRENTLY` — ไม่บล็อก writes แบบ index ปกติ (แต่รันนอก transaction block)
- เพิ่ม column nullable มักถูกกว่า rewrite ทั้งตาราง
- ตรวจ `pg_stat_activity` / `pg_locks` ระหว่าง DDL

## MySQL

ดู [`mysql_online_notes.md`](./mysql_online_notes.md)

- `pt-online-schema-change` / `gh-ost` สำหรับ copy + cutover
- ระวัง triggers, FK, disk, replication lag

## หลักทั่วไป

1. วัดขนาดตาราง + ประมาณเวลาบน staging ที่ใกล้เคียง
2. มี max lock wait / abort criteria
3. หลีกเลี่ยงหลาย DDL หนักใน deploy เดียวกัน
4. Monitor replication lag ถ้ามี replica
