# Example 01 — Expand and Contract (Column Rename)

จำลอง rename `accounts.full_name` → `accounts.display_name` แบบ parallel-safe

## เฟส

| ไฟล์                             | เฟส                                |
| -------------------------------- | ---------------------------------- |
| `01_expand_add_display_name.sql` | Expand                             |
| `02_backfill_and_trigger.sql`    | Dual-write ผ่าน trigger + backfill |
| `03_verify.sql`                  | Gate                               |
| `04_contract_drop_full_name.sql` | Contract (หลังแอปเก่าตาย)          |

ในแอปจริง dual-write มักอยู่ใน application layer — trigger เป็นทางเลือกฝั่ง DB
