# Example 02 — Liquibase Enterprise Changelogs

โครงสร้าง changelog แบบแยกไฟล์ + precondition + rollback

## โครงสร้าง

```
02-liquibase/
 liquibase.properties
 changelog/
 db.changelog-master.yaml
 changes/
 001-create-accounts.yaml
 010-expand-billing-profile.yaml
 020-backfill-billing-profile.yaml
 030-contract-drop-billing-columns.yaml
 scripts/
 run-update.sh
```

## คำสั่งพื้นฐาน

```bash
liquibase --defaults-file=liquibase.properties status
liquibase --defaults-file=liquibase.properties updateSQL
liquibase --defaults-file=liquibase.properties update
liquibase --defaults-file=liquibase.properties rollbackCount 1
```
