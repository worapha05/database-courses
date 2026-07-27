# Lab — Expert: Zero-Downtime Split + Liquibase + Pipeline Gates

## บริบท

**Aurora Ledger** เป็นระบบบัญชีที่ต้อง uptime สูง ตอนนี้มีตารางใหญ่:

```text
accounts(
 id BIGSERIAL PK,
 email TEXT UNIQUE NOT NULL,
 full_name TEXT NOT NULL,
 billing_address TEXT,
 billing_city TEXT,
 billing_country CHAR(2),
 balance_cents BIGINT NOT NULL DEFAULT 0,
 created_at TIMESTAMPTZ NOT NULL
)
```

เป้าหมาย:

1. แยกที่อยู่ไปตาราง `account_billing_profiles` **แบบ zero-downtime** (Expand/Contract)
2. จัดการด้วย **Liquibase** (changeset + precondition + rollback)
3. ใส่ใน **CI/CD** พร้อม verification gate และแผนเมื่อ migrate ล้มกลางคัน

สมมติ Blue-Green: ช่วงหนึ่งมี API v1 และ v2 ชน DB เดียวกัน

---

## ส่วน A — Expand and Contract Plan

เขียนแผน release (อย่างน้อย 4 เฟส) สำหรับ:

- ย้าย `billing_*` ออกจาก `accounts`
- แอป v2 อ่าน/เขียนโปรไฟล์ใหม่
- แอป v1 ยังใช้ column เดิมได้จนกว่าจะปลด

ต้องระบุ: schema change แต่ละเฟส, พฤติกรรมแอป, verification, จุดที่ยัง rollback แอปได้

---

## ส่วน B — Liquibase Changelogs

สร้าง:

1. Master changelog
2. Expand changeset (สร้างตารางใหม่ + column เชื่อมถ้าจำเป็น)
3. Backfill changeset (หรือ document ว่า backfill เป็น job แยก + changeset ที่ mark เมื่อเสร็จ)
4. Contract changeset (drop column เก่า) พร้อม **precondition** ที่กันการรันก่อนข้อมูลครบ
5. Rollback blocks ที่สมเหตุสมผลสำหรับ Expand (Contract มัก forward-only ใน prod — อธิบายทำไม)

---

## ส่วน C — CI/CD + Failure Drill

ออกแบบ pipeline (GitHub Actions และ/หรือ Jenkins) ที่:

1. รัน `liquibase updateSQL` (dry-run) แล้วอัพโหลด artifact
2. รัน `liquibase update` บน staging ด้วย secrets
3. รัน verification SQL — fail ถ้าไม่ผ่าน
4. ค่อย deploy app
5. มีขั้นตอน manual approval ก่อน contract บน production
6. มี runbook สั้นเมื่อ job fail หลัง apply บาง changeset

---

## เกณฑ์ผ่าน

- แผน Expand/Contract สอดคล้อง Blue-Green
- Precondition กัน contract ก่อน backfill ครบ
- Pipeline แยก migrate / verify / deploy / contract approval
- มีคำตอบชัดเจนเรื่อง mid-flight failure

---

## เฉลย — วิธีคิด

### Compatibility window สำคัญกว่าความสวยของ schema

การมี column ซ้ำชั่วคราว “ดูไม่สวย” แต่ถูกทาง engineering Drop เร็วเกินไป = ตัดทาง rollback แอป

### Precondition ตัวอย่างก่อน Contract

```yaml
preConditions:
 - onFail: HALT
 - sqlCheck:
 expectedResult: 0
 sql: >
 SELECT COUNT(*) FROM accounts a
 LEFT JOIN account_billing_profiles p ON p.account_id = a.id
 WHERE p.account_id IS NULL
  AND a.billing_country IS NOT NULL
```

### Failure mid-way

- ถ้า Expand เสร็จแต่ backfill ไม่ครบ: แอปเก่ายังรอด, หยุด promote v2 หรือปิด flag อ่านตารางใหม่
- อย่า Contract ถ้า verify ไม่ผ่าน
- Forward fix changeset ใหม่ดีกว่า rollback ที่ทำลายข้อมูลที่เขียนช่วง dual-write

โครงสร้างเฉลย: [`lab/solution/`](./lab/solution/)
