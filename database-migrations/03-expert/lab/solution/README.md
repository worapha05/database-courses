# Lab Solution — Aurora Ledger Zero-Downtime

## สรุปแผน Expand / Contract

| เฟส          | Schema                           | App v1                 | App v2                | Rollback app?             |
| ------------ | -------------------------------- | ---------------------- | --------------------- | ------------------------- |
| E1 Expand    | สร้าง `account_billing_profiles` | อ่าน/เขียน column เดิม | dual-write ทั้งสอง    | ได้                       |
| E2 Backfill  | copy ข้อมูล + job ตามรอย         | เหมือนเดิม             | dual-write            | ได้                       |
| E3 Switch    | verify ผ่าน                      | อ่านเดิม               | อ่านตารางใหม่เป็นหลัก | ได้ถ้า dual-write ยังอยู่ |
| E4 Retire v1 | —                                | traffic = 0            | เท่านั้น              | จำกัด                     |
| C1 Contract  | drop `billing_*` บน accounts     | ต้องไม่มี              | อ่านตารางใหม่         | schema forward-fix        |

รายละเอียด SQL/เฟส: [`expand-contract/PLAN.md`](./expand-contract/PLAN.md)

## Liquibase

ดู [`liquibase/`](./liquibase/) — มี labels `expand`, `backfill`, `contract` และ precondition ก่อน
contract

## CI/CD + Runbook

ดู [`cicd/`](./cicd/) — workflow ย่อ + `RUNBOOK.md` สำหรับ failure mid-way
