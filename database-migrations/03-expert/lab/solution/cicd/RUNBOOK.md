# RUNBOOK — Migration Failure Mid-Flight (Aurora Ledger)

## อาการ

- CI job `liquibase update` แดง
- App error พุ่งหลัง deploy
- Verification gate รายงาน missing backfill > 0

## ลำดับตอบสนอง (หน้างาน)

1. **หยุด promote / หยุด contract ทันที**
2. เก็บ artifact: `updateSQL`, job logs, `DATABASECHANGELOG` snapshot
3. ตรวจว่า changeset ไหน `MARK_RAN` / รันจริง / ล้มกลางคัน
4. จัดประเภท:

| สถานะ                            | การกระทำ                                                           |
| -------------------------------- | ------------------------------------------------------------------ |
| Expand ยังไม่เสร็จ               | แก้ DDL แล้ว forward changeset ใหม่; อย่า contract                 |
| Expand เสร็จ backfill ไม่ครบ     | รัน backfill ซ้ำแบบ idempotent; ปิด flag อ่านตารางใหม่             |
| Verify fail หลัง backfill        | หาแถว orphan; ห้าม drop column                                     |
| Contract ล้มหลัง drop บาง column | Forward fix หรือ restore จาก PITR — ประเมิน data ที่เขียนหลัง drop |

5. สื่อสาร war room: schema compatible กับ version แอปไหนบ้างตอนนี้
6. Postmortem ภายใน 48 ชม.: ทำไม staging ไม่จับได้, ต้องเพิ่ม gate อะไร

## คำสั่งตรวจเร็ว (Postgres)

```sql
SELECT
  id,
  author,
  filename,
  dateexecuted,
  exectype,
  md5sum
FROM
  databasechangelog
ORDER BY
  orderexecuted DESC
LIMIT
  20;

SELECT
  locked,
  lockgranted,
  lockedby
FROM
  databasechangeloglock;
```

ถ้า lock ค้างจาก job ที่ถูกฆ่า: ปลด lock **หลังยืนยันว่าไม่มี migrate process จริง** เท่านั้น

## หลักการ

- Prefer **forward fix** มากกว่า rollback ที่ไม่แน่ใจเรื่องข้อมูล
- Compatibility window คือตาข่ายความปลอดภัย — อย่าหดเร็วเกิน
