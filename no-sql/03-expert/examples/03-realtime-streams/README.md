# 03 — Real-time: Change Streams & Redis Pub/Sub / Streams

## สำคัญเรื่อง Change Streams

MongoDB ต้องรันแบบ **replica set** ถึงจะใช้ Change Streams ได้ `docker-compose.yml` ของ bootcamp
เปิด **single-node replica set (`rs0`)** ให้อยู่แล้ว พร้อม init อัตโนมัติ

## รัน examples

```bash
# Terminal A — subscriber
node 03-expert/examples/03-realtime-streams/pubsub-subscriber.js

# Terminal B — publisher
node 03-expert/examples/03-realtime-streams/pubsub-publisher.js

# Streams consumer group
node 03-expert/examples/03-realtime-streams/streams-demo.js

# Change Streams → Redis (ต้องรอ mongo healthy / rs PRIMARY)
node 03-expert/examples/03-realtime-streams/change-stream.js
```

ตรวจสอบสถานะ replica set:

```bash
docker exec -it nosql-bootcamp-mongo mongosh -u bootcamp -p bootcamp \
  --authenticationDatabase admin --eval 'rs.status().myState'
# 1 = PRIMARY
```

## เปรียบเทียบ

| เครื่องมือ     | Persistence | Fan-out         | ใช้เมื่อ                            |
| -------------- | ----------- | --------------- | ----------------------------------- |
| Pub/Sub        | ไม่         | ดี              | notification สด, ไม่ทน message loss |
| Streams        | มี          | consumer groups | pipeline ประมวลผลออเดอร์, retry ได้ |
| Change Streams | oplog-based | ต่อ consumer    | CDC จาก MongoDB                     |
