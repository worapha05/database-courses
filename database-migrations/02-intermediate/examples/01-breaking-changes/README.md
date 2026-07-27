# Example 01 — Breaking Changes Isolation

แสดงลำดับปลอดภัยเมื่อเพิ่ม NOT NULL และเตรียม drop column

## ลำดับไฟล์

| ไฟล์                            | บทบาท                                  |
| ------------------------------- | -------------------------------------- |
| `01_add_phone_nullable.sql`     | Expand — เพิ่ม column แบบปลอดภัย       |
| `02_backfill_phone.sql`         | Data — เติมค่า                         |
| `03_enforce_phone_not_null.sql` | Constrain                              |
| `04_drop_legacy_mobile.sql`     | Contract — หลังแอปไม่ใช้ `mobile` แล้ว |

## Prisma equivalent notes

ใน Prisma คุณจะ:

1. เพิ่ม `phone String?` → migrate
2. รัน backfill script
3. เปลี่ยนเป็น `phone String` → migrate อีกรอบ
4. ลบฟิลด์เก่าออกจาก schema → migrate สุดท้าย
