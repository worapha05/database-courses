# 05 — Functions, Procedures & Triggers

- PostgreSQL: `set_updated_at` trigger + audit trigger + `create_order()` function
- MySQL: `ON UPDATE CURRENT_TIMESTAMP` สำหรับ `updated_at` + audit trigger + `create_order`
  procedure

## คำเตือน

Trigger ที่ซับซ้อนเกินไปทำให้ระบบยากต่อ debug — เก็บเฉพาะ invariant / audit / derived fields
