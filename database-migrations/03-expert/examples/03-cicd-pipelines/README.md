# Example 03 — CI/CD Migration Pipelines

แยก **migrate → verify → deploy** และมี approval ก่อน contract

## ไฟล์

| ไฟล์                         | เนื้อหา             |
| ---------------------------- | ------------------- |
| `github-actions-migrate.yml` | GitHub Actions      |
| `Jenkinsfile.migrate`        | Jenkins Declarative |
| `verify.sql`                 | Post-migrate gates  |

## หลักที่ฝังในตัวอย่าง

- Job migrate ใช้ secrets คนละชุดกับ runtime
- `updateSQL` เก็บเป็น artifact ก่อน apply
- Verification fail = หยุด deploy
- Production contract ต้องการ `environment: production-contract` approval
