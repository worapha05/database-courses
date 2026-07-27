# HA Design Note — FlashMart

## ทำไม MongoDB production ต้องเป็น Replica Set

- ได้ **automatic failover** เมื่อ primary ล่ม
- Secondary ใช้เป็น disaster recovery อ่านอย่างเดียว / backup source ได้
- **Change Streams** อาศัย oplog ของ replica set
- Single-node คือจุดเดียวที่พังแล้วระบบหยุดเขียน

แนะนำอย่างน้อย 3 โหนด (หรือ 2 data + 1 arbiter ตามข้อจำกัด — แต่ 3 data โหนดชัดเจนกว่า)

## Redis Sentinel vs Cluster

|                          | Sentinel                                                | Cluster                                        |
| ------------------------ | ------------------------------------------------------- | ---------------------------------------------- |
| เป้าหมายหลัก             | HA ของ topology primary/replica                         | Scale-out memory + throughput                  |
| การแบ่งข้อมูล            | ไม่ shard                                               | แบ่ง 16384 hash slots                          |
| เหมาะกับ FlashMart เมื่อ | dataset/session ยังพอในเครื่องเดียว แต่ต้องไม่ downtime | hot keys/catalog cache ใหญ่เกินเครื่องเดียว    |
| ข้อควรระวัง              | client ต้องรองรับ sentinel                              | multi-key ต้องอยู่ slot เดียวกัน (`{sku}:...`) |

แผน FlashMart: เริ่ม **Sentinel** สำหรับ cache/session → ย้าย **Cluster** เมื่อ memory/CPU ของ Redis
ติดเพดาน

## HA ≠ Backup

- HA ทำให้บริการยังทำงานเมื่อโหนดพัง
- Backup (snapshot / PITR) กู้จาก **ลบข้อมูลผิด / bug / ransomware**
- มี replica ครบแต่ไม่มี backup = ลบผิดแล้ว replicate ความผิดไปทุกโหนด
