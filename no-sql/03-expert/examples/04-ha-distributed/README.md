# 04 — HA & Distributed Architectures

เอกสาร + คำสั่งอ้างอิงสำหรับ MongoDB Replica Set / Sharding และ Redis Sentinel / Cluster

## รัน

```bash
node 03-expert/examples/04-ha-distributed/ha-cheatsheet.js
```

## คำสั่งระดับ Production (อ้างอิง)

### MongoDB Replica Set

```bash
mongosh --eval 'rs.status()'
mongosh --eval 'rs.printSecondaryReplicationInfo()'
```

Connection:

```text
mongodb://u:p@mongo1:27017,mongo2:27017,mongo3:27017/bootcamp?replicaSet=rs0&authSource=admin
```

### MongoDB Sharding

```bash
sh.status()
sh.shardCollection("bootcamp.orders", { customerId: "hashed" })
```

### Redis Sentinel

```bash
redis-cli -p 26379 SENTINEL masters
redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
```

ioredis:

```js
new Redis({
  sentinels: [
    { host: 'sent1', port: 26379 },
    { host: 'sent2', port: 26379 },
  ],
  name: 'mymaster',
});
```

### Redis Cluster

```bash
redis-cli -c -p 7000 CLUSTER NODES
redis-cli -c -p 7000 SET '{user:42}:cart' '...'
```

```js
new Redis.Cluster([{ host: '127.0.0.1', port: 7000 }]);
```
