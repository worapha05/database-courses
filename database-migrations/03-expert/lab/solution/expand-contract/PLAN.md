# Expand & Contract Plan — Billing Profile Split

## เป้าหมายธุรกิจ

แยกที่อยู่เรียกเก็บเงินออกจาก `accounts` โดยไม่ทำให้ Blue/Green overlapping versions พัง

## เฟสละเอียด

### Phase E1 — Expand (release N)

**DB**

```sql
CREATE TABLE account_billing_profiles (
  account_id BIGINT PRIMARY KEY REFERENCES accounts (id) ON DELETE CASCADE,
  address TEXT,
  city TEXT,
  country CHAR(2),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW ()
);
```

**App v2 (deploy หลัง migrate)**

- เขียน: update ทั้ง `accounts.billing_*` และ `account_billing_profiles`
- อ่าน: ลองโปรไฟล์ใหม่ แล้ว fallback column เดิม

**App v1**

- ไม่เปลี่ยน — ใช้ column เดิมอย่างเดียว

**Verify**

- ตารางมีอยู่, FK ถูกต้อง, ไม่มี drop อะไร

### Phase E2 — Backfill (job / changeset)

- `INSERT ... SELECT` แบบ idempotent สำหรับแถวที่ยังไม่มีโปรไฟล์
- สำหรับตารางใหญ่: batch ตาม `id` ranges + throttle
- Dual-write ในแอปต้องเปิดอยู่ตลอดเฟสนี้

**Verify**

```sql
SELECT
  COUNT(*)
FROM
  accounts a
  LEFT JOIN account_billing_profiles p ON p.account_id = a.id
WHERE
  p.account_id IS NULL
  AND (
    a.billing_address IS NOT NULL
    OR a.billing_city IS NOT NULL
    OR a.billing_country IS NOT NULL
  );

-- expect 0
```

### Phase E3 — Read switch (release N+1)

- v2 อ่านจาก `account_billing_profiles` เป็นหลัก
- ยัง dual-write อยู่
- ปิด feature flag อ่าน column เก่าเมื่อ metrics ปกติ

### Phase E4 — Drain v1

- Blue (v1) traffic → 0
- เฝ้า error rate / shadow reads 24h (หรือตาม SLA)

### Phase C1 — Contract (release N+2, manual approval)

```sql
ALTER TABLE accounts
DROP COLUMN billing_address,
DROP COLUMN billing_city,
DROP COLUMN billing_country;
```

- ลบ dual-write โค้ดใน release ถัดไปได้

## จุดที่ยัง rollback แอปได้

- ระหว่าง E1–E3: กลับไป v1 ได้เพราะ column เก่ายังอยู่และถูก dual-write
- หลัง C1: rollback แอปที่ยังอ่าน `billing_*` **ไม่ได้** — ต้อง forward-fix แอปหรือ restore จาก
  backup (แพง)

## script อ้างอิงใน folder นี้

- `e1_expand.sql`
- `e2_backfill.sql`
- `verify.sql`
- `c1_contract.sql`
