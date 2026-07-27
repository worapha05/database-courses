# MySQL Online Schema Change — บันทึกสั้น

## เมื่อไหร่ต้องใช้เครื่องมือพิเศษ

- ตารางใหญ่มาก และ `ALTER` แบบ in-place ไม่รองรับหรือช้าเกิน SLA
- ต้องการลด lock ระหว่าง rewrite

## ตัวเลือกยอดนิยม

| เครื่องมือ                  | แนวคิด                                                |
| --------------------------- | ----------------------------------------------------- |
| **gh-ost**                  | ใช้ binlog แทน triggers บนตารางต้นทาง (ลด contention) |
| **pt-online-schema-change** | สร้างตารางใหม่ + triggers sync + cutover rename       |

## Checklist ก่อน cutover

- [ ] Replica lag ต่ำและมี monitoring
- [ ] Disk พอสำหรับตารางสำเนา
- [ ] ทดสอบบน staging ด้วยข้อมูลใกล้เคียงขนาด prod
- [ ] แผน abort: หยุด tool แล้วเหลือตารางชั่วคราวอย่างไร
- [ ] แอปทนช่วง metadata lock สั้น ๆ ตอน rename ได้

## ความสัมพันธ์กับ Expand/Contract

Online DDL ช่วย **ลด downtime ของ DDL** Expand/Contract ช่วย **ความเข้ากันได้ของแอปหลาย version**
ใช้คู่กันในระบบ mission-critical
