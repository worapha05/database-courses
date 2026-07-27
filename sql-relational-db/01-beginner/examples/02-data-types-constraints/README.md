# 02 — Data Types & Constraints

ฝึกเลือก type และบังคับ integrity ด้วย constraint

## จุดเปรียบเทียบ PG vs MySQL

| หัวข้อ          | PostgreSQL    | MySQL                         |
| --------------- | ------------- | ----------------------------- |
| Array           | `TEXT[]`      | ใช้ `JSON` array หรือตารางแยก |
| JSON            | `JSONB`       | `JSON`                        |
| Boolean         | `BOOLEAN`     | `TINYINT(1)`                  |
| Auto updated_at | trigger / แอป | `ON UPDATE CURRENT_TIMESTAMP` |

## ทดลองเอง

ลอง insert ค่าที่ผิด constraint (ราคาติดลบ, `qty_delta = 0`) แล้วดู error message
